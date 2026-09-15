extends Node

const DAY_MUSIC := preload("res://assets/audio/flowerbed_fields.ogg")
const NIGHT_MUSIC := preload("res://assets/audio/going_up.ogg")
const SOUNDS := {
	&"click": preload("res://assets/audio/ui_click.ogg"),
	&"jump": preload("res://assets/audio/platform_jump.wav"),
	&"death": preload("res://assets/audio/death.ogg"),
	&"portal": preload("res://assets/audio/portal.wav"),
	&"fire": preload("res://assets/audio/fire.wav"),
	&"coin": preload("res://assets/audio/coin.ogg"),
	&"stomp": preload("res://assets/audio/stomp.ogg"),
	&"block": preload("res://assets/audio/block.ogg"),
	&"hurt": preload("res://assets/audio/hurt.ogg")
}

var music_player: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_index := 0
var _night_music := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	var music_stream := DAY_MUSIC.duplicate() as AudioStreamOggVorbis
	music_stream.loop = true
	music_player.stream = music_stream
	music_player.volume_db = -15.0
	add_child(music_player)
	for index in 8:
		var player := AudioStreamPlayer.new()
		player.volume_db = -7.0
		add_child(player)
		_pool.append(player)
	music_player.play()

func play_sfx(sound_name: StringName, pitch_variation: float = 0.0) -> void:
	if not SOUNDS.has(sound_name):
		return
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()
	player.stream = SOUNDS[sound_name]
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play()

func duck_music(duration: float = 0.5) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(music_player, "volume_db", -27.0, 0.1)
	tween.tween_interval(duration)
	tween.tween_property(music_player, "volume_db", -15.0, 0.35)

func reset_music() -> void:
	music_player.volume_db = -15.0
	if not music_player.playing:
		music_player.play()

func set_world_music(is_night: bool) -> void:
	if _night_music == is_night:
		return
	_night_music = is_night
	var source: AudioStreamOggVorbis = NIGHT_MUSIC if is_night else DAY_MUSIC
	var next_stream := source.duplicate() as AudioStreamOggVorbis
	next_stream.loop = true
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(music_player, "volume_db", -32.0, 0.22)
	await tween.finished
	music_player.stream = next_stream
	music_player.play()
	var fade_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(music_player, "volume_db", -15.0, 0.38)

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for player in _pool:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_pool.clear()
