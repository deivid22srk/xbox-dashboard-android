class_name DownloadManager
extends Node
## Download HTTP streaming com: progresso (bytes/velocidade/ETA), pausar/retomar via
## HTTP Range, cancelar, segue redirects (GitHub releases -> CDN assinada) e grava
## em arquivo .part com renomeacao atomica ao concluir.

signal progress(id: String, downloaded: int, total: int, speed_bps: float, eta_s: float)
signal state_changed(id: String, state: String)  # downloading|paused|finished|failed|canceled

const STATE_DOWNLOADING := "downloading"
const STATE_PAUSED := "paused"
const STATE_FINISHED := "finished"
const STATE_FAILED := "failed"
const STATE_CANCELED := "canceled"

const MAX_REDIRECTS := 6
const READ_BUDGET_PER_FRAME := 1 << 19  # 512 KB/frame (nao trava o render)

const UA := "SeriesDash/1.0 (Android console dashboard)"

var _jobs := {}  # id -> Dictionary

func start(id: String, url: String, dest_path: String) -> void:
        cancel(id, true)
        var part := dest_path + ".part"
        var have := 0
        if FileAccess.file_exists(part):
                var f := FileAccess.open(part, FileAccess.READ)
                if f != null:
                        have = f.get_length()
                        f.close()
        _jobs[id] = {
                "id": id, "url": url, "dest": dest_path, "part": part, "have": have,
                "total": 0, "speed": 0.0, "client": null, "state": STATE_DOWNLOADING,
                "redirects": 0, "requested": false, "error": "",
                "last_poll": Time.get_ticks_msec(), "acc_bytes": 0, "acc_ms": 0,
                "chunk": PackedByteArray(),
        }
        state_changed.emit(id, STATE_DOWNLOADING)

func pause(id: String) -> void:
        if not _jobs.has(id):
                return
        var job: Dictionary = _jobs[id]
        _close_client(job)
        _flush(job)
        job["state"] = STATE_PAUSED
        state_changed.emit(id, STATE_PAUSED)

func resume(id: String) -> void:
        if not _jobs.has(id) or _jobs[id]["state"] != STATE_PAUSED:
                return
        _jobs[id]["state"] = STATE_DOWNLOADING
        state_changed.emit(id, STATE_DOWNLOADING)

func cancel(id: String, silent: bool = false) -> void:
        if not _jobs.has(id):
                return
        var job: Dictionary = _jobs[id]
        _close_client(job)
        if FileAccess.file_exists(job["part"]):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(job["part"]))
        _jobs.erase(id)
        if not silent:
                state_changed.emit(id, STATE_CANCELED)

func state_of(id: String) -> String:
        return String(_jobs[id]["state"]) if _jobs.has(id) else ""

func last_error(id: String) -> String:
        return String(_jobs[id].get("error", "erro desconhecido")) if _jobs.has(id) else "erro desconhecido"

func snapshot(id: String) -> Dictionary:
        if not _jobs.has(id):
                return {}
        var job: Dictionary = _jobs[id]
        return {"have": int(job["have"]), "total": int(job["total"]), "speed": float(job["speed"])}

## ------------------------------ maquina HTTP ------------------------------

func _process(_delta: float) -> void:
        for id in _jobs.keys():
                var job: Dictionary = _jobs[id]
                if job["state"] != STATE_DOWNLOADING:
                        continue
                if job["client"] == null:
                        _connect_job(job)
                        continue
                var client: HTTPClient = job["client"]
                var status := client.get_status()
                if status == HTTPClient.STATUS_DISCONNECTED or status == HTTPClient.STATUS_CONNECTION_ERROR:
                        # conexao caiu no meio: tenta retomar de onde parou
                        if job["have"] > 0 and job["redirects"] < MAX_REDIRECTS * 4:
                                job["client"] = null
                                job["requested"] = false
                                continue
                        _fail(job, "connection_closed")
                        continue
                var err := client.poll()
                if err != OK:
                        _fail(job, "poll_err_%d" % err)
                        continue
                if client.get_status() == HTTPClient.STATUS_CONNECTED and not job["requested"]:
                        var headers := PackedStringArray(["User-Agent: " + UA, "Accept: */*"])
                        if job["have"] > 0:
                                headers.append("Range: bytes=%d-" % job["have"])
                        var req_err := client.request(HTTPClient.METHOD_GET, job["path"], headers)
                        if req_err != OK:
                                _fail(job, "request_err_%d" % req_err)
                                continue
                        job["requested"] = true
                if client.has_response():
                        _read_body(job, client)

func _connect_job(job: Dictionary) -> void:
        var url: String = job["url"]
        var host := url
        var path := "/"
        var use_tls := false
        var port := -1
        if url.begins_with("https://"):
                use_tls = true
                host = url.substr(8)
                port = 443
        elif url.begins_with("http://"):
                host = url.substr(7)
        var slash := host.find("/")
        if slash >= 0:
                path = host.substr(slash)
                host = host.substr(0, slash)
        var at := host.rfind("@")
        if at >= 0:
                host = host.substr(at + 1)
        if not host.begins_with("["):
                var colon := host.rfind(":")
                if colon >= 0:
                        port = int(host.substr(colon + 1))
                        host = host.substr(0, colon)

        var client := HTTPClient.new()
        client.set_read_chunk_size(1 << 16)
        client.blocking_mode_enabled = false
        var tls_opts: TLSOptions = TLSOptions.client() if use_tls else null
        var err := client.connect_to_host(host, port if port > 0 else (443 if use_tls else 80), tls_opts)
        if err != OK:
                _fail(job, "connect_err_%d" % err)
                return
        job["client"] = client
        job["path"] = path
        job["requested"] = false

func _close_client(job: Dictionary) -> void:
        if job.get("client") != null:
                job["client"].close()
                job["client"] = null
        job["requested"] = false

func _read_body(job: Dictionary, client: HTTPClient) -> void:
        var code := client.get_response_code()
        # redirect (GitHub api/download -> CDN assinada)
        if code >= 300 and code < 400:
                var loc := ""
                for h in client.get_response_headers():
                        if h.to_lower().begins_with("location:"):
                                loc = h.substr(9).strip_edges()
                                break
                if loc != "" and job["redirects"] < MAX_REDIRECTS:
                        job["redirects"] += 1
                        job["url"] = loc
                        _close_client(job)
                        return
                _fail(job, "redirect_limit")
                return
        if code == 416 and job["have"] > 0:
                # ja temos tudo
                job["total"] = job["have"]
                _finish(job)
                return
        if code != 200 and code != 206:
                _fail(job, "http_%d" % code)
                return

        if code == 200 and job["have"] > 0:
                # servidor ignorou Range: recomeca do zero
                job["have"] = 0
                var f0 := FileAccess.open(job["part"], FileAccess.WRITE)
                if f0 != null:
                        f0.close()

        var body_len := int(client.get_response_body_length())
        if body_len > 0:
                job["total"] = (job["have"] + body_len) if code == 206 else body_len
        if job["total"] <= 0 and code == 206 and job["have"] > 0:
                job["total"] = job["have"]  # sem content-length: assume concluido ao terminar

        var now := Time.get_ticks_msec()
        var dt: int = now - int(job["last_poll"])
        job["last_poll"] = now

        var budget := READ_BUDGET_PER_FRAME
        while budget > 0 and client.get_status() == HTTPClient.STATUS_BODY:
                var chunk := client.read_response_body_chunk()
                if chunk.is_empty():
                        break
                job["chunk"].append_array(chunk)
                job["have"] += chunk.size()
                job["acc_bytes"] += chunk.size()
                budget -= chunk.size()
                if job["total"] > 0 and job["have"] >= job["total"]:
                        break

        job["acc_ms"] += dt
        if job["acc_ms"] >= 400:
                var inst_speed := float(job["acc_bytes"]) / (float(job["acc_ms"]) / 1000.0)
                job["speed"] = inst_speed if job["speed"] <= 0.0 else lerpf(job["speed"], inst_speed, 0.4)
                job["acc_bytes"] = 0
                job["acc_ms"] = 0
                _flush(job)
                _emit_progress(job)

        if job["total"] > 0 and job["have"] >= job["total"]:
                _flush(job)
                _finish(job)
        _emit_progress(job)

func _flush(job: Dictionary) -> void:
        if job["chunk"].is_empty():
                return
        var exists := FileAccess.file_exists(job["part"])
        var f := FileAccess.open(job["part"], FileAccess.READ_WRITE if exists else FileAccess.WRITE)
        if f == null:
                return
        f.seek_end()
        f.store_buffer(job["chunk"])
        f.close()
        job["chunk"] = PackedByteArray()

func _finish(job: Dictionary) -> void:
        _flush(job)
        var gp := ProjectSettings.globalize_path(job["dest"])
        DirAccess.make_dir_recursive_absolute(gp.get_base_dir())
        var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(job["part"]), gp)
        var id := String(job["id"])
        _jobs.erase(id)
        if err != OK:
                state_changed.emit(id, STATE_FAILED)
                return
        state_changed.emit(id, STATE_FINISHED)

func _fail(job: Dictionary, reason: String) -> void:
        _close_client(job)
        _flush(job)
        var id := String(job["id"])
        _jobs[id]["state"] = STATE_FAILED
        _jobs[id]["error"] = reason
        state_changed.emit(id, STATE_FAILED)

func _emit_progress(job: Dictionary) -> void:
        var total := int(job["total"])
        var have := int(job["have"])
        var speed := float(job["speed"])
        var remaining := float(max(total - have, 0))
        var eta := remaining / speed if speed > 0.0 else 0.0
        progress.emit(String(job["id"]), have, total, speed, eta)
