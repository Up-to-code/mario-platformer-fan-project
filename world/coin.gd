class_name MeadowCoin
extends Area2D

const ITEMS_SHEET := preload("res://assets/original/items_sheet.svg")

@export var persistent_id: StringName
var collected := false
var _time := 0.0
var night_mode := false

func _ready() -> void:
	add_to_group("persistent")
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if collected:
		return
	var frame := int(_time * 9.0) % 3
	draw_texture_rect_region(ITEMS_SHEET, Rect2(-10, -10, 20, 20), Rect2(frame * 16, 16, 16, 16))

func collect() -> void:
	if collected:
		return
	collected = true
	set_deferred("monitoring", false)
	AudioManager.play_sfx(&"coin", 0.08)
	GameSession.add_coin()
	if get_parent().has_method("burst"):
		get_parent().burst(global_position, Color("ffe15b"), 7)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	queue_redraw()

func set_night(value: bool) -> void:
	night_mode = value
	self_modulate = Color("8fe8ff") if night_mode else Color.WHITE
	queue_redraw()

func get_persistent_state() -> Dictionary:
	return {"collected": collected}

func restore_persistent_state(state: Dictionary) -> void:
	collected = bool(state.get("collected", false))
	monitoring = not collected
	modulate = Color.WHITE
	scale = Vector2.ONE
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		collect()
