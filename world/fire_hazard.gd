class_name MeadowFireHazard
extends Area2D

@export var width := 42.0
var _time := 0.0

func _ready() -> void:
	add_to_group("fire_hazard")
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width - 8.0, 20.0)
	shape_node.position.y = -10
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var count := maxi(1, int(width / 21.0))
	for index in count:
		var tile := 316 + (int(_time * 8.0 + index) % 2)
		MeadowArt.draw_tile(self, tile, Rect2(-width * 0.5 + index * 21.0, -25, 21, 25))

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		AudioManager.play_sfx(&"fire", 0.05)
		body.take_damage(true)
