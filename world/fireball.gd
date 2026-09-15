class_name MeadowFireball
extends CharacterBody2D

@export var speed := 245.0
@export var bounce_velocity := -155.0
@export var gravity := 720.0
var direction := 1.0
var _life_left := 3.0
var _time := 0.0

func _ready() -> void:
	add_to_group("player_fireballs")
	collision_layer = 0
	collision_mask = 1
	var body_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	body_shape.shape = circle
	add_child(body_shape)
	var hit_area := Area2D.new()
	hit_area.collision_layer = 0
	hit_area.collision_mask = 4
	var hit_shape := CollisionShape2D.new()
	hit_shape.shape = circle
	hit_area.add_child(hit_shape)
	add_child(hit_area)
	hit_area.body_entered.connect(_on_body_entered)
	velocity = Vector2(signf(direction) * speed, 0.0)

func _physics_process(delta: float) -> void:
	_life_left -= delta
	_time += delta
	if _life_left <= 0.0:
		queue_free()
		return
	velocity.x = signf(direction) * speed
	velocity.y = minf(velocity.y + gravity * delta, 420.0)
	move_and_slide()
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal()
		if normal.y < -0.6:
			velocity.y = bounce_velocity
		elif absf(normal.x) > 0.6:
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color("fff36a"))
	draw_circle(Vector2.ZERO, 4.0, Color("ff7b22"))
	var tail := Vector2(-signf(direction) * (7.0 + sin(_time * 25.0) * 2.0), 0)
	draw_circle(tail, 3.0, Color("e83b2e"))

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_projectile_hit"):
		body.take_projectile_hit()
		if get_parent().has_method("burst"):
			get_parent().burst(global_position, Color("ffb32b"), 7)
		queue_free()
