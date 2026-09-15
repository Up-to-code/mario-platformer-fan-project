class_name MeadowPowerUp
extends CharacterBody2D

enum PowerUpType { MUSHROOM, FLOWER }

const ITEMS_SHEET := preload("res://assets/user_provided/items_sheet.png")

@export var persistent_id: StringName
@export var powerup_type: PowerUpType = PowerUpType.MUSHROOM
var collected := false
var _direction := 1.0

func _ready() -> void:
	add_to_group("persistent")
	collision_layer = 0
	collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(17, 17)
	shape_node.position.y = -8.5
	shape_node.shape = shape
	add_child(shape_node)
	var pickup := Area2D.new()
	pickup.collision_layer = 8
	pickup.collision_mask = 2
	var pickup_shape := CollisionShape2D.new()
	pickup_shape.position.y = -9
	pickup_shape.shape = shape
	pickup.add_child(pickup_shape)
	add_child(pickup)
	pickup.body_entered.connect(_on_body_entered)
	var tween := create_tween()
	var target := global_position.y - 18.0
	position.y += 18.0
	tween.tween_property(self, "global_position:y", target, 0.35).set_trans(Tween.TRANS_BACK)

func _physics_process(delta: float) -> void:
	if collected:
		return
	velocity.x = _direction * 42.0 if powerup_type == PowerUpType.MUSHROOM else 0.0
	if not is_on_floor():
		velocity.y = minf(velocity.y + 850.0 * delta, 450.0)
	move_and_slide()
	if is_on_wall():
		_direction *= -1.0

func _draw() -> void:
	if not collected:
		var source := Rect2(0, 0, 16, 16) if powerup_type == PowerUpType.MUSHROOM else Rect2(32, 0, 16, 16)
		var bob := sin(Time.get_ticks_msec() * 0.008) * 1.5 if powerup_type == PowerUpType.FLOWER else 0.0
		draw_texture_rect_region(ITEMS_SHEET, Rect2(-10, -21 + bob, 20, 20), source)

func collect(player: MeadowPlayer) -> void:
	if collected:
		return
	collected = true
	visible = false
	set_physics_process(false)
	AudioManager.play_sfx(&"coin", 0.04)
	player.collect_powerup(powerup_type)
	if get_parent().has_method("burst"):
		get_parent().burst(global_position - Vector2(0, 10), Color("ff9d3f"), 12)

func get_persistent_state() -> Dictionary:
	return {"collected": collected, "position": global_position, "type": powerup_type}

func restore_persistent_state(state: Dictionary) -> void:
	collected = bool(state.get("collected", false))
	powerup_type = int(state.get("type", powerup_type)) as PowerUpType
	global_position = state.get("position", global_position)
	visible = not collected
	set_physics_process(not collected)

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		collect(body)
