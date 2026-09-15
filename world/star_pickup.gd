class_name MeadowStarPickup
extends Area2D

const ITEMS_SHEET := preload("res://assets/user_provided/items_sheet.png")

@export var persistent_id: StringName
var collected := false
var _time := 0.0

func _ready() -> void:
	add_to_group("persistent")
	add_to_group("star_pickups")
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if collected:
		return
	var bob := sin(_time * 4.5) * 4.0
	var tint := Color.from_hsv(fmod(_time * 0.35, 1.0), 0.35, 1.0)
	draw_texture_rect_region(ITEMS_SHEET, Rect2(-12, -12 + bob, 24, 24), Rect2(48, 0, 16, 16), tint)

func collect(player: MeadowPlayer) -> void:
	if collected:
		return
	collected = true
	monitoring = false
	visible = false
	AudioManager.play_sfx(&"coin", 0.05)
	player.activate_star()
	if get_parent().has_method("burst"):
		get_parent().burst(global_position, Color("fff06a"), 18)

func get_persistent_state() -> Dictionary:
	return {"collected": collected}

func restore_persistent_state(state: Dictionary) -> void:
	collected = bool(state.get("collected", false))
	monitoring = not collected
	visible = not collected
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		collect(body)
