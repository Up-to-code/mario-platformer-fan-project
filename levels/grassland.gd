class_name MeadowGrassland
extends Node2D

signal world_mode_changed(is_night: bool)

enum WorldMode { DAY, NIGHT }

const PlayerScene := preload("res://player/player.tscn")
const LEVEL_END := 15050
const GROUND_Y := 315.0
const SPAWN := Vector2(80, GROUND_Y)
const NIGHT_SPAWN := Vector2(7850, GROUND_Y)

var player: MeadowPlayer
var _terrain: MeadowTerrainVisual
var _restoring := false
var _death_count := 0
var world_mode: WorldMode = WorldMode.DAY
var _transitioning := false
var _transition_overlay: ColorRect

var ground_segments: Array[Rect2] = [
	Rect2(0, GROUND_Y, 1180, 100), Rect2(1240, GROUND_Y, 990, 100),
	Rect2(2290, GROUND_Y, 1250, 100), Rect2(3600, GROUND_Y, 1200, 100),
	Rect2(4860, GROUND_Y, 1290, 100), Rect2(6210, GROUND_Y, 1500, 100),
	Rect2(7770, GROUND_Y, 1480, 100), Rect2(9310, GROUND_Y, 1490, 100),
	Rect2(10860, GROUND_Y, 1810, 100), Rect2(12730, GROUND_Y, 2400, 100)
]

var platforms: Array[Rect2] = [
	Rect2(520, 252, 126, 21), Rect2(688, 210, 147, 21),
	Rect2(1430, 252, 168, 21), Rect2(1640, 210, 126, 21),
	Rect2(2500, 250, 168, 21), Rect2(2710, 205, 189, 21), Rect2(2941, 245, 126, 21),
	Rect2(3790, 250, 147, 21), Rect2(3979, 205, 168, 21), Rect2(4189, 250, 126, 21),
	Rect2(5110, 248, 168, 21), Rect2(5320, 205, 189, 21), Rect2(5551, 250, 126, 21),
	Rect2(6450, 250, 147, 21), Rect2(6639, 205, 210, 21), Rect2(6891, 250, 147, 21),
	Rect2(8000, 250, 168, 21), Rect2(8210, 205, 168, 21), Rect2(8420, 250, 168, 21),
	Rect2(9530, 248, 147, 21), Rect2(9719, 205, 189, 21), Rect2(9950, 250, 147, 21),
	Rect2(11120, 250, 189, 21), Rect2(11351, 205, 210, 21), Rect2(11603, 250, 168, 21),
	Rect2(13020, 250, 168, 21), Rect2(13230, 205, 210, 21), Rect2(13482, 250, 189, 21),
	Rect2(13900, 250, 189, 21), Rect2(14131, 205, 168, 21)
]

func _ready() -> void:
	_build_terrain()
	_build_level_content()
	player = PlayerScene.instantiate()
	player.global_position = SPAWN
	add_child(player)
	player.set_camera_limits(0, 0, LEVEL_END + 250, 378)
	player.died.connect(_on_player_died)
	_build_transition_overlay()
	set_world_mode(WorldMode.DAY)
	GameSession.start_run(SPAWN)
	GameSession.save_checkpoint(&"start", SPAWN, _capture_world_state())

func _process(_delta: float) -> void:
	if world_mode == WorldMode.DAY and not _transitioning and is_instance_valid(player) and player.global_position.x > 7760.0:
		_transition_to_night()

func _build_terrain() -> void:
	_terrain = MeadowTerrainVisual.new()
	_terrain.z_index = -1
	add_child(_terrain)
	var decor: Array[Dictionary] = []
	for segment in ground_segments:
		_add_static_rect(segment)
	for platform in platforms:
		_add_static_rect(platform)
	_terrain.configure(ground_segments, platforms, decor)

func _build_level_content() -> void:
	# Coins teach movement, mark safe arcs, and reward the optional upper route.
	var coin_positions: Array[Vector2] = []
	for x in range(180, 1080, 105): coin_positions.append(Vector2(x, 275))
	for x in range(1420, 2140, 84): coin_positions.append(Vector2(x, 270 - sin(x * 0.02) * 35))
	for x in range(2500, 3380, 70): coin_positions.append(Vector2(x, 175 if x > 2780 and x < 3100 else 270))
	for x in range(3800, 4660, 84): coin_positions.append(Vector2(x, 170 + absf(4200 - x) * 0.12))
	for x in range(5100, 6020, 84): coin_positions.append(Vector2(x, 175 if x > 5420 and x < 5780 else 270))
	for x in range(6450, 7580, 92): coin_positions.append(Vector2(x, 180 + (x % 3) * 22))
	for x in range(8000, 9120, 84): coin_positions.append(Vector2(x, 175 if x > 8320 and x < 8620 else 270))
	for x in range(9550, 10650, 88): coin_positions.append(Vector2(x, 180 + absf(10100 - x) * 0.08))
	for x in range(11100, 12500, 95): coin_positions.append(Vector2(x, 175 if x > 11450 and x < 11800 else 270))
	for x in range(13000, 14800, 92): coin_positions.append(Vector2(x, 175 + (x % 4) * 17))
	for index in coin_positions.size():
		_add_coin(coin_positions[index], StringName("coin_%03d" % index))

	var enemy_positions := [930, 1510, 2010, 2620, 3300, 3890, 4550, 5160, 5950, 6510, 7080, 7440, 8130, 8890, 9620, 10420, 11250, 12120, 13080, 13860, 14520]
	for index in enemy_positions.size():
		var kind: MeadowEnemy.EnemyType = MeadowEnemy.EnemyType.WALKER
		if index % 3 == 1:
			kind = MeadowEnemy.EnemyType.TURTLE
		elif index % 3 == 2:
			kind = MeadowEnemy.EnemyType.HUNTER
		_add_enemy(Vector2(enemy_positions[index], GROUND_Y), StringName("enemy_%02d" % index), -1.0 if index % 2 == 0 else 1.0, kind)

	var plant_positions := [1810, 5685, 10120, 13280]
	for index in plant_positions.size():
		_add_plant(Vector2(plant_positions[index], GROUND_Y), StringName("plant_%02d" % index))
	var star_positions := [Vector2(2850, 168), Vector2(6750, 168), Vector2(11450, 168)]
	for index in star_positions.size():
		_add_star(star_positions[index], StringName("star_%02d" % index))

	var question_positions := [Vector2(420, 235), Vector2(1670, 160), Vector2(2720, 160), Vector2(5350, 160), Vector2(8240, 160), Vector2(11380, 160), Vector2(13580, 160)]
	for index in question_positions.size():
		_add_block(question_positions[index], StringName("question_%02d" % index), MeadowBlock.BlockType.QUESTION)
	var brick_positions := [Vector2(399, 235), Vector2(441, 235), Vector2(1649, 160), Vector2(1691, 160), Vector2(2699, 160), Vector2(2741, 160), Vector2(5329, 160), Vector2(5371, 160), Vector2(8219, 160), Vector2(8261, 160), Vector2(11359, 160), Vector2(11401, 160), Vector2(13559, 160), Vector2(13601, 160)]
	for index in brick_positions.size():
		_add_block(brick_positions[index], StringName("brick_%02d" % index), MeadowBlock.BlockType.BRICK)

	_add_checkpoint(Vector2(7380, GROUND_Y), &"meadow_midpoint")
	_add_spikes(Vector2(4250, GROUND_Y), 63)
	_add_spikes(Vector2(11780, GROUND_Y), 84)
	_add_fire(Vector2(5750, GROUND_Y), 42)
	_add_fire(Vector2(7160, GROUND_Y), 63)
	_add_portal(Vector2(7500, GROUND_Y))
	var goal := MeadowGoal.new()
	goal.global_position = Vector2(14880, GROUND_Y)
	add_child(goal)

func _add_static_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func _add_coin(position: Vector2, id: StringName) -> void:
	var coin := MeadowCoin.new()
	coin.persistent_id = id
	coin.global_position = position
	add_child(coin)

func _add_enemy(position: Vector2, id: StringName, direction: float, kind: MeadowEnemy.EnemyType = MeadowEnemy.EnemyType.WALKER) -> void:
	var enemy := MeadowEnemy.new()
	enemy.persistent_id = id
	enemy.start_direction = direction
	enemy.enemy_type = kind
	enemy.global_position = position
	add_child(enemy)

func _add_plant(position: Vector2, id: StringName) -> void:
	var plant := MeadowPlantEnemy.new()
	plant.persistent_id = id
	plant.global_position = position
	add_child(plant)

func _add_star(position: Vector2, id: StringName) -> void:
	var star := MeadowStarPickup.new()
	star.persistent_id = id
	star.global_position = position
	add_child(star)

func _add_block(position: Vector2, id: StringName, type: MeadowBlock.BlockType) -> void:
	var block := MeadowBlock.new()
	block.persistent_id = id
	block.block_type = type
	block.global_position = position
	add_child(block)

func _add_checkpoint(position: Vector2, id: StringName) -> void:
	var checkpoint := MeadowCheckpoint.new()
	checkpoint.persistent_id = id
	checkpoint.global_position = position
	add_child(checkpoint)

func _add_spikes(position: Vector2, spike_width: float) -> void:
	var spike := MeadowSpike.new()
	spike.width = spike_width
	spike.global_position = position
	add_child(spike)

func _add_fire(position: Vector2, fire_width: float) -> void:
	var fire := MeadowFireHazard.new()
	fire.width = fire_width
	fire.global_position = position
	add_child(fire)

func _add_portal(position: Vector2) -> void:
	var portal := MeadowPortal.new()
	portal.global_position = position
	portal.entered.connect(_transition_to_night)
	add_child(portal)

func spawn_powerup(position: Vector2, source_id: StringName, type: MeadowPowerUp.PowerUpType = MeadowPowerUp.PowerUpType.MUSHROOM) -> void:
	var id := StringName("power_%s" % source_id)
	for node in get_tree().get_nodes_in_group("persistent"):
		if node.get("persistent_id") == id:
			return
	var power_up := MeadowPowerUp.new()
	power_up.persistent_id = id
	power_up.powerup_type = type
	power_up.global_position = position
	add_child(power_up)
	if power_up.has_method("set_night"):
		power_up.set_night(world_mode == WorldMode.NIGHT)

func spawn_fireball(position: Vector2, direction: float) -> void:
	var fireball := MeadowFireball.new()
	fireball.global_position = position
	fireball.direction = direction
	add_child(fireball)

func capture_checkpoint(id: StringName, spawn_position: Vector2) -> void:
	GameSession.save_checkpoint(id, spawn_position, _capture_world_state())

func _capture_world_state() -> Dictionary:
	var state := {}
	for node in get_tree().get_nodes_in_group("persistent"):
		if not is_ancestor_of(node) or not node.has_method("get_persistent_state"):
			continue
		var id: StringName = node.get("persistent_id")
		if not id.is_empty():
			state[id] = node.get_persistent_state()
	return state

func _restore_world_state(state: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("persistent"):
		if not is_ancestor_of(node):
			continue
		var id: StringName = node.get("persistent_id")
		if state.has(id) and node.has_method("restore_persistent_state"):
			node.restore_persistent_state(state[id])
		elif String(id).begins_with("power_"):
			node.queue_free()
	_apply_world_theme()

func _on_player_died() -> void:
	if _restoring:
		return
	_restoring = true
	_death_count += 1
	await get_tree().create_timer(0.85).timeout
	GameSession.restore_checkpoint_stats()
	_restore_world_state(GameSession.checkpoint_world)
	player.reset_at(GameSession.checkpoint_position, GameSession.power_state)
	_restoring = false

func complete_level() -> void:
	GameSession.add_score(2000)
	await get_tree().create_timer(0.65).timeout
	GameSession.finish_run()

func set_world_mode(value: WorldMode) -> void:
	world_mode = value
	AudioManager.set_world_music(world_mode == WorldMode.NIGHT)
	_terrain.set_night(world_mode == WorldMode.NIGHT)
	_apply_world_theme()
	world_mode_changed.emit(world_mode == WorldMode.NIGHT)

func _apply_world_theme() -> void:
	var night := world_mode == WorldMode.NIGHT
	for node in get_tree().get_nodes_in_group("persistent"):
		if is_ancestor_of(node) and node.has_method("set_night"):
			node.set_night(night)

func _build_transition_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0.035, 0.055, 0.15, 0.0)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_transition_overlay)

func _transition_to_night() -> void:
	if _transitioning or world_mode == WorldMode.NIGHT:
		return
	_transitioning = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	AudioManager.play_sfx(&"portal")
	var fade_in := create_tween()
	fade_in.tween_property(_transition_overlay, "color:a", 1.0, 0.38)
	await fade_in.finished
	set_world_mode(WorldMode.NIGHT)
	player.global_position = NIGHT_SPAWN
	player.velocity = Vector2.ZERO
	player.camera.reset_smoothing()
	GameSession.save_checkpoint(&"night_entry", NIGHT_SPAWN, _capture_world_state())
	var fade_out := create_tween()
	fade_out.tween_property(_transition_overlay, "color:a", 0.0, 0.48)
	await fade_out.finished
	player.controls_enabled = true
	_transitioning = false

func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.12
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func burst(at: Vector2, color: Color, amount: int = 8) -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = at
	particles.z_index = 15
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.42
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 95.0
	particles.initial_velocity_min = 35.0
	particles.initial_velocity_max = 75.0
	particles.gravity = Vector2(0, 130)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	particles.color = color
	add_child(particles)
	particles.emitting = true
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(particles):
		particles.queue_free()
