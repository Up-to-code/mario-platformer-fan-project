class_name MeadowPlantEnemy
extends Area2D

const ENEMY_SHEET := preload("res://assets/original/enemy_sheet.svg")

@export var persistent_id: StringName
var defeated := false
var open := false
var _time := 0.0
var _player: MeadowPlayer

func _ready() -> void:
	add_to_group("persistent")
	add_to_group("plant_enemies")
	collision_layer = 4
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 27)
	shape_node.position.y = -14
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if defeated:
		return
	_time += delta
	open = fmod(_time, 2.5) < 1.35
	if open and is_instance_valid(_player):
		_player.take_damage()
	queue_redraw()

func _draw() -> void:
	if defeated:
		return
	var frame := 8 if open else 7
	var height := 32.0 if open else 23.0
	draw_texture_rect_region(ENEMY_SHEET, Rect2(-16, -height, 32, 32), Rect2(frame * 32, 0, 32, 32))

func take_projectile_hit() -> void:
	if defeated:
		return
	defeated = true
	monitoring = false
	GameSession.add_score(250)
	visible = false

func get_persistent_state() -> Dictionary:
	return {"defeated": defeated, "time": _time}

func restore_persistent_state(state: Dictionary) -> void:
	defeated = bool(state.get("defeated", false))
	_time = float(state.get("time", 0.0))
	monitoring = not defeated
	visible = not defeated
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		_player = body

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
