class_name MeadowTerrainVisual
extends Node2D

const WORLD_TILES := preload("res://assets/user_provided/overworld_tiles.png")
const CASTLE_TILES := preload("res://assets/user_provided/castle_tiles.png")

var ground_segments: Array[Rect2] = []
var platforms: Array[Rect2] = []
var decorations: Array[Dictionary] = []
var night_mode := false

func configure(ground: Array[Rect2], raised_platforms: Array[Rect2], decor: Array[Dictionary]) -> void:
	ground_segments = ground
	platforms = raised_platforms
	decorations = decor
	queue_redraw()

func set_night(value: bool) -> void:
	night_mode = value
	queue_redraw()

func _draw() -> void:
	for segment in ground_segments:
		draw_rect(segment, Color("301c2d") if night_mode else Color("8d4d27"))
		var tile_count := ceili(segment.size.x / 16.0)
		for index in tile_count:
			var x := segment.position.x + index * 16.0
			var texture := CASTLE_TILES if night_mode else WORLD_TILES
			var source := Rect2(16, 48, 16, 16) if night_mode else Rect2((index % 2) * 16, 0, 16, 16)
			draw_texture_rect_region(texture, Rect2(x, segment.position.y, 16, 16), source)
			for row in range(1, ceili(segment.size.y / 16.0)):
				var fill_source := Rect2((index % 4) * 16, 48 + (row % 2) * 16, 16, 16) if night_mode else Rect2(16, 0, 16, 16)
				draw_texture_rect_region(texture, Rect2(x, segment.position.y + row * 16, 16, 16), fill_source)
	for platform in platforms:
		draw_rect(platform, Color("301c2d") if night_mode else Color("8d4d27"))
		var tile_count := ceili(platform.size.x / 16.0)
		for index in tile_count:
			var texture := CASTLE_TILES if night_mode else WORLD_TILES
			var source := Rect2(16, 48, 16, 16) if night_mode else Rect2((index % 2) * 16, 0, 16, 16)
			draw_texture_rect_region(texture, Rect2(platform.position.x + index * 16.0, platform.position.y, 16, 21), source)
	for item in decorations:
		var tile: int = item.get("tile", 18)
		var position: Vector2 = item.get("position", Vector2.ZERO)
		var size: Vector2 = item.get("size", Vector2(21, 21))
		MeadowArt.draw_tile(self, tile, Rect2(position - Vector2(size.x * 0.5, size.y), size))
