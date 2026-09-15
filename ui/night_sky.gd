class_name MeadowNightSky
extends Control

const WORLD_TILES := preload("res://assets/user_provided/overworld_tiles.png")
const CASTLE_TILES := preload("res://assets/user_provided/castle_tiles.png")

var night := false
var _stars := [
	Vector2(38, 58), Vector2(92, 104), Vector2(145, 52), Vector2(204, 88),
	Vector2(265, 43), Vector2(318, 115), Vector2(376, 62), Vector2(429, 97),
	Vector2(487, 48), Vector2(542, 118), Vector2(598, 70), Vector2(642, 39),
	Vector2(70, 165), Vector2(180, 142), Vector2(350, 154), Vector2(520, 158)
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	queue_redraw()

func set_night(value: bool) -> void:
	night = value
	visible = true
	queue_redraw()

func _draw() -> void:
	var viewport_size := size
	if not night:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("56c9f2"))
		draw_rect(Rect2(0, viewport_size.y * 0.72, viewport_size.x, viewport_size.y * 0.28), Color("8bd448"))
		# Supplied clouds and hills replace the old flat green silhouette.
		for cloud in [Vector2(45, 50), Vector2(300, 82), Vector2(545, 42)]:
			draw_texture_rect_region(WORLD_TILES, Rect2(cloud, Vector2(96, 48)), Rect2(80, 32, 48, 32))
		for hill in [Vector2(-30, 178), Vector2(185, 158), Vector2(425, 183), Vector2(590, 150)]:
			draw_texture_rect_region(WORLD_TILES, Rect2(hill, Vector2(176, 144)), Rect2(48, 80, 80, 48))
		for bush in [Vector2(60, 272), Vector2(340, 267), Vector2(560, 274)]:
			draw_texture_rect_region(WORLD_TILES, Rect2(bush, Vector2(78, 48)), Rect2(0, 96, 48, 32))
		return
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("08132f"))
	draw_rect(Rect2(0, viewport_size.y * 0.38, viewport_size.x, viewport_size.y * 0.62), Color("182451"))
	draw_rect(Rect2(0, viewport_size.y * 0.62, viewport_size.x, viewport_size.y * 0.38), Color("26315f"))
	for index in _stars.size():
		var radius := 1.5 if index % 3 else 2.2
		draw_circle(_stars[index], radius, Color("d7efff"))
	draw_circle(Vector2(viewport_size.x - 82, 78), 30.0, Color("f8e9a8"))
	draw_circle(Vector2(viewport_size.x - 70, 68), 29.0, Color("08132f"))
	draw_texture_rect_region(CASTLE_TILES, Rect2(18, 190, 176, 176), Rect2(0, 0, 80, 80), Color(0.56, 0.58, 0.78, 0.62))
	draw_texture_rect_region(CASTLE_TILES, Rect2(viewport_size.x - 205, 172, 190, 190), Rect2(0, 0, 80, 80), Color(0.48, 0.50, 0.74, 0.60))

func _on_viewport_size_changed() -> void:
	size = get_viewport_rect().size
	queue_redraw()
