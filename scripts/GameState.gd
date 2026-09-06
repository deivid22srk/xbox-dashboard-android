extends Node
## Estado global persistente (autoload): preferencias, instalados, cache de releases.

const SAVE_PATH := "user://state.json"

var settings := {
	"sound": true,
	"fast_anim": false,
}
var installed := {}       # id -> {pkg, at, method}
var releases := {}        # id -> {url, size, version, name} (cache do GitHub API / fallback)
var catalog := {}         # carregado no boot
var catalog_list: Array = []

func _ready() -> void:
	_load()
	_load_catalog()

func _load_catalog() -> void:
	var f := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	if f == null:
		push_error("catalog.json ausente")
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data == null:
		push_error("catalog.json invalido")
		return
	catalog = data
	catalog_list = data.get("games", [])
	for g in catalog_list:
		if g.source is Dictionary and g.source.get("type") == "github_release":
			var fb: Dictionary = g.source.get("fallback", {})
			if fb.has("url"):
				releases[g.id] = fb

func game_by_id(id: String) -> Dictionary:
	for g in catalog_list:
		if g.get("id", "") == id:
			return g
	return {}

func is_installed(id: String) -> bool:
	return installed.has(id)

func mark_installed(id: String, pkg: String, method: String) -> void:
	installed[id] = {"pkg": pkg, "at": Time.get_unix_time_from_system(), "method": method}
	save()

func unmark_installed(id: String) -> void:
	installed.erase(id)
	save()

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"settings": settings, "installed": installed, "releases": releases}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		if data.has("settings"):
			for k in data["settings"]:
				settings[k] = data["settings"][k]
		if data.has("installed"):
			installed = data["installed"]
		if data.has("releases"):
			releases = data["releases"]

## ---- formatadores pt-BR ----

static func fmt_size(bytes: float) -> String:
	if bytes <= 0.0:
		return "--"
	var mb := bytes / (1024.0 * 1024.0)
	if mb >= 1024.0:
		return "%.1f GB" % (mb / 1024.0)
	if mb >= 1.0:
		return "%.1f MB" % mb
	return "%d KB" % int(bytes)

static func fmt_eta(sec: float) -> String:
	if sec <= 0.0 or is_inf(sec):
		return "--"
	if sec < 60.0:
		return "%ds" % int(ceil(sec))
	var m := int(sec / 60.0)
	var s := int(fmod(sec, 60.0))
	return "%dmin %02ds" % [m, s]

static func fmt_speed(bps: float) -> String:
	if bps <= 0.0:
		return "-- MB/s"
	var mb := bps / (1024.0 * 1024.0)
	if mb >= 1.0:
		return "%.1f MB/s" % mb
	return "%d KB/s" % int(bps / 1024.0)
