extends Node
## Autoload Sfx: reproduz os blips de UI (sintetizados, assets/sounds). Pool simples.

const SOUNDS := {
	"nav": "res://assets/sounds/nav.wav",
	"select": "res://assets/sounds/select.wav",
	"back": "res://assets/sounds/back.wav",
	"error": "res://assets/sounds/error.wav",
	"done": "res://assets/sounds/done.wav",
	"boot": "res://assets/sounds/boot.wav",
}

var _cache := {}
var _players: Array = []

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(sound_name: String, volume_db: float = -8.0) -> void:
	if not GameState.settings.get("sound", true):
		return
	if not SOUNDS.has(sound_name):
		return
	if not _cache.has(sound_name):
		_cache[sound_name] = load(SOUNDS[sound_name])
	var stream: AudioStream = _cache[sound_name]
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = randf_range(0.98, 1.02)
			p.play()
			return
	_players[0].stream = stream
	_players[0].volume_db = volume_db
	_players[0].play()
