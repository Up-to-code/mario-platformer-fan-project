class_name MeadowEnemy
extends CharacterBody2D

enum EnemyType { WALKER, TURTLE, HUNTER }

const ENEMY_SHEET := preload("res://assets/original/enemy_sheet.svg")

@export var persistent_id: StringName
@export var speed := 45.0
@export var start_direction := -1.0
@export var enemy_type: EnemyType = EnemyType.WALKER
var defeated := false
var _direction := -1.0
var _time := 0.0
var night_mode := false

func _ready() -> void:
	add_to_group("persistent")
	_direction = start_direction
	if enemy_type == EnemyType.TURTLE:
		speed = 56.0
	elif enemy_type == EnemyType.HUNTER:
		speed = 68.0
	collision_layer = 4
	collision_mask = 1
	var body_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(17, 14)
	body_shape.position.y = -7
	body_shape.shape = rectangle
	add_child(body_shape)
	var hurtbox := Area2D.new()
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 2
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(22, 18)
	hurt_shape.position.y = -9
	hurt_shape.shape = hurt_rect
	hurtbox.add_child(hurt_shape)
	add_child(hurtbox)
	hurtbox.body_entered.connect(_on_player_entered)

func _physics_process(delta: float) -> void:
	_time += delta
	if defeated:
		queue_redraw()
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + 900.0 * delta, 500.0)
	if enemy_type == EnemyType.HUNTER:
		var player := get_tree().get_first_node_in_group("meadow_player") as MeadowPlayer
		if is_instance_valid(player) and absf(player.global_position.x - global_position.x) < 280.0:
			_direction = signf(player.global_position.x - global_position.x)
	velocity.x = _direction * speed
	move_and_slide()
	if is_on_wall():
		_direction *= -1.0
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(_direction * 12.0, -2.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 26), 1)
	query.exclude = [get_rid()]
	if is_on_floor() and space.intersect_ray(query).is_empty():
		_direction *= -1.0
	queue_redraw()

func _draw() -> void:
	if defeated:
		var defeated_frame := 2 if enemy_type != EnemyType.HUNTER else 13
		_draw_enemy_frame(defeated_frame, Rect2(-16, -12, 32, 16))
	else:
		var frame := int(_time * 7.0) % 2
		if enemy_type == EnemyType.TURTLE:
			frame = 9 + int(_time * 9.0) % 4
		elif enemy_type == EnemyType.HUNTER:
			frame = 14 + int(_time * 6.0) % 3
		_draw_enemy_frame(frame, Rect2(-16, -32, 32, 32))

func _draw_enemy_frame(frame: int, destination: Rect2) -> void:
	var target := destination
	if _direction > 0.0:
		target.position.x += target.size.x
		target.size.x *= -1.0
	draw_texture_rect_region(ENEMY_SHEET, target, Rect2(frame * 32, 0, 32, 32))

func set_night(value: bool) -> void:
	night_mode = value
	self_modulate = Color("b9c7ff") if night_mode else Color.WHITE
	queue_redraw()

func take_stomp() -> void:
	if defeated:
		return
	defeated = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	collision_layer = 0
	GameSession.add_score(200)
	if get_parent().has_method("burst"):
		get_parent().burst(global_position - Vector2(0, 8), Color("88d8c0"), 8)
	queue_redraw()

func take_projectile_hit() -> void:
	if defeated:
		return
	take_stomp()
	GameSession.add_score(50)

func get_persistent_state() -> Dictionary:
	return {"defeated": defeated}

func restore_persistent_state(state: Dictionary) -> void:
	defeated = bool(state.get("defeated", false))
	visible = true
	modulate = Color.WHITE
	collision_layer = 0 if defeated else 4
	set_physics_process(not defeated)
	queue_redraw()

func _on_player_entered(body: Node) -> void:
	if defeated or not body is MeadowPlayer:
		return
	var player := body as MeadowPlayer
	if player.velocity.y > 45.0 and player.global_position.y < global_position.y - 7.0:
		take_stomp()
		player.bounce_from_stomp()
		var level := get_parent()
		if level.has_method("hit_stop"):
			level.hit_stop(0.06)
	else:
		player.take_damage()
