class_name MeadowArt
extends RefCounted

const ATLAS := preload("res://assets/kenney/platformer_atlas.png")
const TILE_SIZE := 21
const ATLAS_STRIDE := 23
const ATLAS_COLUMNS := 30

static func region(tile_id: int) -> Rect2:
	var column := tile_id % ATLAS_COLUMNS
	var row := tile_id / ATLAS_COLUMNS
	return Rect2(column * ATLAS_STRIDE, row * ATLAS_STRIDE, TILE_SIZE, TILE_SIZE)

static func draw_tile(canvas: CanvasItem, tile_id: int, destination: Rect2, flip_x: bool = false) -> void:
	var target := destination
	if flip_x:
		target.position.x += target.size.x
		target.size.x *= -1.0
	canvas.draw_texture_rect_region(ATLAS, target, region(tile_id))

