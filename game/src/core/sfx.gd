extends Node
## Placeholder sound effects (M1 task "placeholder audio"). Autoload: Sfx.
## Files are short generated tones in res://assets/audio; a missing file is simply silent.

const VOICES := 6
var _players: Array = []
var _next := 0
var _cache: Dictionary = {}
var _music: AudioStreamPlayer
var _track := ""


func _ready() -> void:
	for i: int in range(VOICES):
		var p := AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.finished.connect(func() -> void: _music.play())      # loop
	add_child(_music)
	Sim.hour_changed.connect(func(_h: int) -> void: update_music())


## Day and night have their own tune; the switch fades out and in.
func update_music() -> void:
	var track := "music_night" if Sim.is_night() else "music_day"
	if track == _track:
		return
	var path := "res://assets/audio/%s.wav" % track
	if not ResourceLoader.exists(path):
		return
	_track = track
	var tween := create_tween()
	if _music.playing:
		tween.tween_property(_music, "volume_db", -40.0, 1.0)
	tween.tween_callback(func() -> void:
		_music.stream = load(path)
		_music.volume_db = -40.0
		_music.play())
	tween.tween_property(_music, "volume_db", 0.0, 1.5)


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
