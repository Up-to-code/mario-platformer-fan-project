class_name MeadowPortal
extends Area2D

const WORLD_TILES := preload("res://assets/original/overworld_tiles.svg")

signal entered

var player_inside := false
var active := true
var _time := 0.0
var prompt: Label

func _ready() -> void:
	add_to_group("world_portal")
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(46, 62)
	shape_node.position.y = -31
	shape_node.shape = shape
	add_child(shape_node)
	prompt = Label.new()
	prompt.text = "DOWN / S"
	prompt.position = Vector2(-42, -91)
	prompt.size = Vector2(84, 22)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_color_override("font_color", Color("fff0a6"))
	prompt.visible = false
	add_child(prompt)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_time += delta
	if active and player_inside and Input.is_action_just_pressed("move_down"):
		active = false
		entered.emit()
	queue_redraw()

func _draw() -> void:
	var pulse := 0.84 + sin(_time * 4.0) * 0.12
	draw_texture_rect_region(WORLD_TILES, Rect2(-32, -64, 64, 32), Rect2(96, 0, 32, 16), Color(1, 1, 1, pulse))
	draw_texture_rect_region(WORLD_TILES, Rect2(-28, -32, 56, 32), Rect2(96, 16, 32, 16), Color(1, 1, 1, pulse))

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		player_inside = true
		prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body is MeadowPlayer:
		player_inside = false
		prompt.visible = false
