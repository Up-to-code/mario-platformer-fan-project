class_name MeadowSpike
extends Area2D

@export var width := 42.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width - 6.0, 12.0)
	shape_node.position.y = -6
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	var count := maxi(1, int(width / 21.0))
	for index in count:
		MeadowArt.draw_tile(self, 570, Rect2(-width * 0.5 + index * 21.0, -21, 21, 21))

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		body.take_damage(true)
