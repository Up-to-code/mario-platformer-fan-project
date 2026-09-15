class_name MeadowGoal
extends Area2D

var reached := false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 120)
	shape_node.position.y = -60
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	draw_rect(Rect2(-3, -116, 6, 116), Color("f7f2d0"))
	draw_circle(Vector2(0, -118), 7.0, Color("ffd83d"))
	MeadowArt.draw_tile(self, 312, Rect2(3, -108, 21, 21))

func _on_body_entered(body: Node) -> void:
	if reached or not body is MeadowPlayer:
		return
	reached = true
	AudioManager.play_sfx(&"coin")
	AudioManager.duck_music(1.0)
	body.celebrate()
	var level := get_parent()
	if level.has_method("burst"):
		level.burst(global_position - Vector2(0, 65), Color("ffe15b"), 28)
	if level.has_method("complete_level"):
		level.complete_level()
