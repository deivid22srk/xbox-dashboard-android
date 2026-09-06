class_name StoreService
extends Node
## Consulta releases no GitHub API (sem autenticacao) e resolve o asset .apk real.
## Em caso de falha (offline/rate-limit/sem release) usa o fallback do catalogo
## ou marca o item como "em breve" — a loja nunca quebra.

signal release_resolved(id: String, info: Dictionary)
signal release_unavailable(id: String, reason: String)

const API_URL := "https://api.github.com/repos/%s/releases/latest"
const UA := "SeriesDash/1.0 (Android console dashboard; +https://github.com/deivid22srk)"

func resolve(id: String) -> void:
        var g := GameState.game_by_id(id)
        if g.is_empty():
                release_unavailable.emit(id, "not_in_catalog")
                return
        var src: Dictionary = g.get("source", {})
        if src.get("type", "") != "github_release":
                # sem fonte de download: item estatico (coming_soon)
                release_unavailable.emit(id, "no_source")
                return
        _fetch(id, src.get("repo", ""), src.get("asset_pattern", ".apk"))

func _fetch(id: String, repo: String, pattern: String) -> void:
        if repo == "":
                release_unavailable.emit(id, "no_repo")
                return
        var http := HTTPRequest.new()
        http.timeout = 15.0
        http.accept_gzip = true
        http.use_threads = true
        add_child(http)
        var headers := PackedStringArray([
                "User-Agent: " + UA,
                "Accept: application/vnd.github+json",
        ])
        var req_err := http.request(API_URL % repo, headers)
        if req_err != OK:
                http.queue_free()
                _use_fallback_or_fail(id, "request_err_%d" % req_err)
                return
        var result: Array = await http.request_completed
        var err: int = result[0]
        var code: int = result[1]
        var body: PackedByteArray = result[3]
        http.queue_free()
        if err != HTTPRequest.RESULT_SUCCESS or code != 200:
                _use_fallback_or_fail(id, "http_%d_%d" % [err, code])
                return
        var data: Variant = JSON.parse_string(body.get_string_from_utf8())
        if data == null or not (data is Dictionary):
                _use_fallback_or_fail(id, "bad_json")
                return
        var info := _extract(data, pattern)
        if info.is_empty():
                _use_fallback_or_fail(id, "no_apk_asset")
                return
        GameState.releases[id] = info
        GameState.save()
        release_resolved.emit(id, info)

func _extract(data: Dictionary, pattern: String) -> Dictionary:
        var tag: String = data.get("tag_name", "")
        if tag == "":
                return {}
        for asset in data.get("assets", []):
                var aname: String = asset.get("name", "")
                if aname.to_lower().ends_with(pattern.to_lower()):
                        return {
                                "version": tag,
                                "name": aname,
                                "size": float(asset.get("size", 0)),
                                "url": asset.get("browser_download_url", ""),
                                "published": data.get("published_at", ""),
                        }
        return {}

func _use_fallback_or_fail(id: String, reason: String) -> void:
        if GameState.releases.has(id):
                # fallback do catalogo ja em cache: segue funcional
                release_resolved.emit(id, GameState.releases[id])
        else:
                release_unavailable.emit(id, reason)
