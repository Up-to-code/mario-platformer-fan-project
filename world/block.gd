class_name MeadowBlock
extends StaticBody2D

const WORLD_TILES := preload("res://assets/original/overworld_tiles.svg")
const CASTLE_TILES := preload("res://assets/original/castle_tiles.svg")

enum BlockType { QUESTION, BRICK }

@export var persistent_id: StringName
@export var block_type: BlockType = BlockType.QUESTION
var used := false
var broken := false
var _bump_offset := 0.0
var night_mode := false

func _ready() -> void:
	add_to_group("persistent")
	collision_layer = 1
	collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(21, 21)
	shape_node.shape = shape
	add_child(shape_node)

func _draw() -> void:
	if broken:
		return
	var source := Rect2(48, 0, 16, 16) if block_type == BlockType.BRICK else (Rect2(32, 0, 16, 16) if used else Rect2(64, 0, 16, 16))
	if night_mode and block_type == BlockType.BRICK:
		draw_texture_rect_region(CASTLE_TILES, Rect2(-10.5, -10.5 + _bump_offset, 21, 21), Rect2(16, 48, 16, 16))
	else:
		draw_texture_rect_region(WORLD_TILES, Rect2(-10.5, -10.5 + _bump_offset, 21, 21), source)

func hit_from_below(player_state: GameSession.PowerState) -> void:
	if broken:
		return
	AudioManager.play_sfx(&"block", 0.06)
	_bump()
	if block_type == BlockType.BRICK:
		if player_state != GameSession.PowerState.SMALL:
			broken = true
			collision_layer = 0
			GameSession.add_score(50)
			if get_parent().has_method("burst"):
				get_parent().burst(global_position, Color("b97a45"), 10)
			queue_redraw()
		return
	if used:
		return
	used = true
	var level := get_parent()
	if player_state == GameSession.PowerState.FIRE:
		GameSession.add_coin()
	elif level.has_method("spawn_powerup"):
		var kind := MeadowPowerUp.PowerUpType.MUSHROOM if player_state == GameSession.PowerState.SMALL else MeadowPowerUp.PowerUpType.FLOWER
		level.spawn_powerup(global_position + Vector2(0, -22), persistent_id, kind)
	queue_redraw()

func get_persistent_state() -> Dictionary:
	return {"used": used, "broken": broken}

func set_night(value: bool) -> void:
	night_mode = value
	self_modulate = Color("b9a7ff") if night_mode else Color.WHITE
	queue_redraw()

func restore_persistent_state(state: Dictionary) -> void:
	used = bool(state.get("used", false))
	broken = bool(state.get("broken", false))
	collision_layer = 0 if broken else 1
	_bump_offset = 0.0
	queue_redraw()

func _bump() -> void:
	_bump_offset = -4.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(func(value: float): _bump_offset = value; queue_redraw(), -4.0, 0.0, 0.12)
