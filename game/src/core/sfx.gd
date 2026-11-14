extends Node
## Placeholder sound effects (M1 task "placeholder audio"). Autoload: Sfx.
## Files are short generated tones in res://assets/audio; a missing file is simply silent.

const VOICES := 6
var _players: Array = []
var _next := 0
var _cache: Dictionary = {}


func _ready() -> void:
	for i: int in range(VOICES):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String) -> void:
	if not _cache.has(sound):
		var path := "res://assets/audio/%s.wav" % sound
		_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	if _cache[sound] == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _cache[sound]
	p.play()
