extends Node

signal score_changed(value: int)
signal coins_changed(value: int)
signal power_changed(value: int)
signal checkpoint_changed(checkpoint_id: StringName)
signal run_started
signal player_died
signal pause_changed(is_paused: bool)
signal victory(score: int, elapsed: float, is_best_score: bool, is_best_time: bool)

enum PowerState { SMALL, GROWN, FIRE }

const SAVE_PATH := "user://meadow_dash.cfg"

var score: int = 0
var coins: int = 0
var elapsed: float = 0.0
var power_state: PowerState = PowerState.SMALL
var running: bool = false
var best_score: int = 0
var best_time: float = 0.0
var checkpoint_id: StringName = &"start"
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_world: Dictionary = {}
var _checkpoint_score: int = 0
var _checkpoint_coins: int = 0
var _checkpoint_elapsed: float = 0.0
var _checkpoint_power: PowerState = PowerState.SMALL

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_records()

func _process(delta: float) -> void:
	if running and not get_tree().paused:
		elapsed += delta

func start_run(spawn_position: Vector2) -> void:
	score = 0
	coins = 0
	elapsed = 0.0
	power_state = PowerState.SMALL
	running = true
	checkpoint_id = &"start"
	checkpoint_position = spawn_position
	checkpoint_world = {}
	_commit_checkpoint_stats()
	score_changed.emit(score)
	coins_changed.emit(coins)
	power_changed.emit(power_state)
	run_started.emit()

func add_score(amount: int) -> void:
	if not running:
		return
	score = max(0, score + amount)
	score_changed.emit(score)

func add_coin(amount: int = 1) -> void:
	coins += amount
	add_score(100 * amount)
	coins_changed.emit(coins)

func set_power(value: PowerState) -> void:
	if power_state == value:
		return
	power_state = value
	power_changed.emit(power_state)

func save_checkpoint(id: StringName, spawn_position: Vector2, world_state: Dictionary) -> void:
	checkpoint_id = id
	checkpoint_position = spawn_position
	checkpoint_world = world_state.duplicate(true)
	_commit_checkpoint_stats()
	checkpoint_changed.emit(checkpoint_id)

func restore_checkpoint_stats() -> void:
	score = _checkpoint_score
	coins = _checkpoint_coins
	elapsed = _checkpoint_elapsed
	power_state = _checkpoint_power
	score_changed.emit(score)
	coins_changed.emit(coins)
	power_changed.emit(power_state)

func notify_death() -> void:
	player_died.emit()

func finish_run() -> void:
	if not running:
		return
	running = false
	var new_score := score > best_score
	var new_time := best_time <= 0.0 or elapsed < best_time
	if new_score:
		best_score = score
	if new_time:
		best_time = elapsed
	save_records()
	victory.emit(score, elapsed, new_score, new_time)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_changed.emit(value)

func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

func save_records(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	config.set_value("records", "best_score", best_score)
	config.set_value("records", "best_time", best_time)
	config.save(path)

func load_records(path: String = SAVE_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		best_score = 0
		best_time = 0.0
		return
	best_score = maxi(0, int(config.get_value("records", "best_score", 0)))
	best_time = maxf(0.0, float(config.get_value("records", "best_time", 0.0)))

func _commit_checkpoint_stats() -> void:
	_checkpoint_score = score
	_checkpoint_coins = coins
	_checkpoint_elapsed = elapsed
	_checkpoint_power = power_state
