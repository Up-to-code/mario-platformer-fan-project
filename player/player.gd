class_name MeadowPlayer
extends CharacterBody2D

signal died

const HERO_SHEET := preload("res://assets/original/hero_sheet.svg")
const FRAME_SIZE := Vector2(32, 32)

@export_group("Movement")
@export var walk_speed := 105.0
@export var sprint_speed := 165.0
@export var ground_acceleration := 850.0
@export var ground_deceleration := 1050.0
@export var air_acceleration := 500.0
@export var gravity := 1000.0
@export var jump_velocity := -390.0
@export var jump_cut_multiplier := 0.46
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12

var controls_enabled := true
var invulnerable := false
var dead := false
var won := false
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _animation_time := 0.0
var _facing := 1.0
var _shake_left := 0.0
var _spawn_position := Vector2.ZERO
var _shoot_cooldown := 0.0
var _shoot_pose_left := 0.0
var _visual_scale := Vector2.ONE
var _visual_tween: Tween
var _star_powered := false
var _star_token := 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("meadow_player")
	_spawn_position = global_position
	set_power_state(GameSession.power_state, false)
	GameSession.power_changed.connect(_on_power_changed)

func _physics_process(delta: float) -> void:
	_animation_time += delta
	_shoot_cooldown = maxf(0.0, _shoot_cooldown - delta)
	_shoot_pose_left = maxf(0.0, _shoot_pose_left - delta)
	if dead or won:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		queue_redraw()
		return

	var was_on_floor := is_on_floor()
	if was_on_floor:
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)

	if controls_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	var axis := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	if absf(axis) > 0.05:
		_facing = signf(axis)
	var max_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	if absf(axis) > 0.05:
		velocity.x = move_toward(velocity.x, axis * max_speed, acceleration * delta)
	else:
		var deceleration := ground_deceleration if is_on_floor() else air_acceleration * 0.35
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = jump_velocity
		AudioManager.play_sfx(&"jump", 0.06)
		_animate_visual(Vector2(1.12, 0.84), 0.14)
		_jump_buffer_left = 0.0
		_coyote_left = 0.0

	if controls_enabled and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	if controls_enabled and Input.is_action_just_pressed("fire"):
		shoot_fireball()

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 650.0)

	move_and_slide()
	if not was_on_floor and is_on_floor():
		_animate_visual(Vector2(0.88, 1.12), 0.12)
	for index in get_slide_collision_count():
		var hit := get_slide_collision(index)
		if hit.get_normal().y > 0.65:
			var collider := hit.get_collider()
			if collider and collider.has_method("hit_from_below"):
				collider.hit_from_below(GameSession.power_state)

	if global_position.y > 430.0:
		take_damage(true)
	queue_redraw()

func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		camera.offset = Vector2(randf_range(-2.0, 2.0), randf_range(-1.5, 1.5))
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO, 40.0 * delta)

func _draw() -> void:
	var frame := 0
	var state := GameSession.power_state
	var base := 0
	if state == GameSession.PowerState.GROWN:
		base = 8
	elif state == GameSession.PowerState.FIRE:
		base = 17
	if dead:
		frame = 6
	elif won:
		frame = base
	elif state == GameSession.PowerState.FIRE and _shoot_pose_left > 0.0:
		frame = 24 + (int(_animation_time * 14.0) % 2)
	elif not is_on_floor():
		frame = 4 if state == GameSession.PowerState.SMALL else base + 4
	elif absf(velocity.x) > 15.0:
		frame = base + 1 + (int(_animation_time * 11.0) % 3)
	else:
		frame = base
	var tint := Color.WHITE
	if _star_powered:
		tint = Color.from_hsv(fmod(_animation_time * 0.9, 1.0), 0.55, 1.0)
	elif invulnerable and int(_animation_time * 14.0) % 2 == 0:
		tint = Color(1, 1, 1, 0.25)
	var draw_size := FRAME_SIZE * _visual_scale
	var destination := Rect2(-draw_size.x * 0.5, -draw_size.y, draw_size.x, draw_size.y)
	var source := Rect2(frame * int(FRAME_SIZE.x), 0, FRAME_SIZE.x, FRAME_SIZE.y)
	# Mirror around the character origin so changing direction never shifts the sprite pivot.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1.0))
	draw_texture_rect_region(HERO_SHEET, destination, source, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func bounce_from_stomp() -> void:
	velocity.y = -235.0
	AudioManager.play_sfx(&"stomp", 0.08)
	shake(0.11)

func take_damage(force_death: bool = false) -> void:
	if invulnerable or dead or won:
		return
	if GameSession.power_state != GameSession.PowerState.SMALL and not force_death:
		AudioManager.play_sfx(&"hurt", 0.04)
		var next_state := GameSession.PowerState.GROWN if GameSession.power_state == GameSession.PowerState.FIRE else GameSession.PowerState.SMALL
		GameSession.set_power(next_state)
		invulnerable = true
		velocity.y = -160.0
		shake(0.18)
		_invulnerability_window()
	else:
		AudioManager.play_sfx(&"death")
		AudioManager.duck_music(0.75)
		dead = true
		controls_enabled = false
		velocity = Vector2(0.0, -260.0)
		GameSession.notify_death()
		died.emit()
	queue_redraw()

func grow() -> void:
	collect_powerup(MeadowPowerUp.PowerUpType.MUSHROOM)

func collect_powerup(type: MeadowPowerUp.PowerUpType) -> void:
	if type == MeadowPowerUp.PowerUpType.MUSHROOM and GameSession.power_state == GameSession.PowerState.SMALL:
		GameSession.set_power(GameSession.PowerState.GROWN)
		GameSession.add_score(1000)
	elif type == MeadowPowerUp.PowerUpType.FLOWER and GameSession.power_state == GameSession.PowerState.GROWN:
		GameSession.set_power(GameSession.PowerState.FIRE)
		GameSession.add_score(1000)
	else:
		GameSession.add_score(500)
	shake(0.14)

func shoot_fireball() -> void:
	if GameSession.power_state != GameSession.PowerState.FIRE or _shoot_cooldown > 0.0:
		return
	var level := get_parent()
	if not level.has_method("spawn_fireball") or get_tree().get_nodes_in_group("player_fireballs").size() >= 2:
		return
	_shoot_cooldown = 0.32
	_shoot_pose_left = 0.18
	AudioManager.play_sfx(&"fire", 0.03)
	level.spawn_fireball(global_position + Vector2(_facing * 15.0, -16.0), _facing)
	queue_redraw()

func activate_star(duration: float = 6.0) -> void:
	_star_token += 1
	var token := _star_token
	_star_powered = true
	invulnerable = true
	GameSession.add_score(1500)
	shake(0.18)
	queue_redraw()
	await get_tree().create_timer(duration).timeout
	if token == _star_token:
		_star_powered = false
		invulnerable = false
		queue_redraw()

func reset_at(position: Vector2, power: GameSession.PowerState) -> void:
	global_position = position
	velocity = Vector2.ZERO
	dead = false
	won = false
	controls_enabled = true
	invulnerable = false
	_star_powered = false
	_star_token += 1
	GameSession.set_power(power)
	set_power_state(power, false)
	camera.reset_smoothing()
	queue_redraw()

func celebrate() -> void:
	won = true
	controls_enabled = false
	velocity.x = 0.0
	queue_redraw()

func shake(duration: float) -> void:
	_shake_left = maxf(_shake_left, duration)

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom

func set_power_state(value: GameSession.PowerState, animate: bool = true) -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if value != GameSession.PowerState.SMALL:
		shape.size = Vector2(16.0, 30.0)
		collision_shape.position.y = -15.0
	else:
		shape.size = Vector2(15.0, 20.0)
		collision_shape.position.y = -10.0
	if animate:
		_animate_visual(Vector2(1.16, 0.74), 0.20)
	queue_redraw()

func _on_power_changed(value: int) -> void:
	set_power_state(value as GameSession.PowerState)

func _invulnerability_window() -> void:
	await get_tree().create_timer(1.25).timeout
	if not _star_powered:
		invulnerable = false
	queue_redraw()

func _animate_visual(from: Vector2, duration: float) -> void:
	if is_instance_valid(_visual_tween):
		_visual_tween.kill()
	_visual_scale = from
	_visual_tween = create_tween()
	_visual_tween.tween_method(func(value: Vector2): _visual_scale = value; queue_redraw(), from, Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
