extends Node

var failures: Array[String] = []

func _ready() -> void:
	await _run_all()
	if failures.is_empty():
		print("MEADOW DASH TESTS: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("MEADOW DASH TESTS: %d FAILURE(S)" % failures.size())
		get_tree().quit(1)

func _run_all() -> void:
	var level := preload("res://levels/grassland.tscn").instantiate() as MeadowGrassland
	add_child(level)
	for frame in 5:
		await get_tree().physics_frame
	_check(level.player != null, "Level creates a player")
	_check(level.player.is_on_floor(), "Player settles on the opening ground")
	_check(level.player.coyote_time >= 0.095 and level.player.coyote_time <= 0.105, "Coyote time remains approximately 100 ms")
	_check(level.player.jump_buffer_time >= 0.115 and level.player.jump_buffer_time <= 0.125, "Jump buffer remains approximately 120 ms")
	var theoretical_jump_height := pow(level.player.jump_velocity, 2.0) / (2.0 * level.player.gravity)
	_check(theoretical_jump_height >= 72.0, "Full jump reaches the first raised platforms comfortably")
	for index in level.ground_segments.size() - 1:
		var segment_end: float = level.ground_segments[index].end.x
		var next_start: float = level.ground_segments[index + 1].position.x
		_check(next_start - segment_end <= 60.0, "Ground gaps remain clearable without sprinting")
	for index in level.platforms.size() - 1:
		var platform: Rect2 = level.platforms[index]
		var next_platform: Rect2 = level.platforms[index + 1]
		var platform_gap := next_platform.position.x - platform.end.x
		if platform_gap < 100.0:
			_check(platform_gap <= 42.0, "Neighboring raised platforms form reachable steps")
			_check(absf(next_platform.position.y - platform.position.y) <= 45.0, "Raised platform height changes stay within the jump arc")
	_check(get_tree().get_nodes_in_group("persistent").size() >= 150, "Level contains the expected persistent content")
	_check(get_tree().get_nodes_in_group("world_portal").size() == 1, "Day level contains a down-entry world portal")
	_check(get_tree().get_nodes_in_group("fire_hazard").size() >= 2, "Day level contains animated fire hazards")
	_check(ResourceLoader.exists("res://assets/audio/platform_jump.wav"), "Dedicated retro platformer jump audio is imported")
	_check(ResourceLoader.exists("res://assets/audio/death.ogg"), "Dedicated losing audio is imported")
	_check(ResourceLoader.exists("res://assets/audio/flowerbed_fields.ogg"), "Licensed cheerful chiptune music is imported")
	_check(ResourceLoader.exists("res://assets/user_provided/hero_sheet.png"), "User-supplied character animation sheet is imported")
	_check(ResourceLoader.exists("res://assets/user_provided/enemy_sheet.png"), "User-supplied enemy animation sheet is imported")
	_check(ResourceLoader.exists("res://assets/user_provided/overworld_tiles.png"), "Supplied OverWorld environment sheet is imported")
	_check(ResourceLoader.exists("res://assets/user_provided/castle_tiles.png"), "Supplied Castle environment sheet is imported")
	_check(InputMap.has_action("fire"), "Fire has a dedicated keyboard and gamepad action")
	_check(get_tree().get_nodes_in_group("plant_enemies").size() >= 4, "Level includes fixed opening and closing plant enemies")
	_check(get_tree().get_nodes_in_group("star_pickups").size() >= 3, "Optional routes include star power-ups")
	var enemy_types := {}
	for node in get_tree().get_nodes_in_group("persistent"):
		if node is MeadowEnemy:
			enemy_types[node.enemy_type] = true
	_check(enemy_types.size() == 3, "Level uses walker, turtle, and player-seeking enemy behaviors")
	_check(ProjectSettings.get_setting("display/window/size/window_width_override") == 1280, "Desktop window targets 1280 pixels wide")
	_check(ProjectSettings.get_setting("display/window/stretch/scale_mode") == "fractional", "Desktop rendering fills the window without integer-scale borders")

	# Acceleration must approach, but never exceed, the sprint cap.
	Input.action_press("move_right")
	Input.action_press("sprint")
	for frame in 40:
		await get_tree().physics_frame
	Input.action_release("move_right")
	Input.action_release("sprint")
	_check(level.player.velocity.x <= level.player.sprint_speed + 0.5, "Sprint velocity is capped")
	_check(level.player.velocity.x > level.player.walk_speed, "Sprint is faster than walking")

	# Jump begins on the buffered action and releasing early cuts its height.
	level.player.reset_at(Vector2(80, 315), GameSession.PowerState.SMALL)
	for frame in 3:
		await get_tree().physics_frame
	Input.action_press("jump")
	for frame in 2:
		await get_tree().physics_frame
	var launch_velocity := level.player.velocity.y
	Input.action_release("jump")
	for frame in 2:
		await get_tree().physics_frame
	_check(launch_velocity < -250.0, "Buffered jump launches the player")
	_check(level.player.velocity.y > launch_velocity * 0.7, "Early jump release cuts upward velocity")

	# A normal-speed full jump clears the first pit from a reasonable edge takeoff.
	level.player.reset_at(Vector2(1100, 315), GameSession.PowerState.SMALL)
	for frame in 3:
		await get_tree().physics_frame
	Input.action_press("move_right")
	while level.player.global_position.x < 1162.0:
		await get_tree().physics_frame
	Input.action_press("jump")
	for frame in 25:
		await get_tree().physics_frame
	Input.action_release("jump")
	for frame in 55:
		await get_tree().physics_frame
		if level.player.is_on_floor() and level.player.global_position.x >= 1240.0:
			break
	Input.action_release("move_right")
	_check(level.player.global_position.x >= 1240.0 and level.player.is_on_floor(), "Normal running jump clears the first pit")

	# Direction changes preserve the physics pivot, and left + jump works simultaneously.
	level.player.reset_at(Vector2(180, 315), GameSession.PowerState.SMALL)
	for frame in 3:
		await get_tree().physics_frame
	var left_start := level.player.global_position
	Input.action_press("move_left")
	Input.action_press("jump")
	for frame in 4:
		await get_tree().physics_frame
	Input.action_release("jump")
	Input.action_release("move_left")
	_check(level.player.global_position.x < left_start.x, "Holding left moves continuously without changing the physics pivot")
	_check(level.player.global_position.y < left_start.y, "Jump works while left movement is held")

	# Checkpoint snapshots restore stats and object state without coin farming.
	var coins: Array[Node] = []
	for node in get_tree().get_nodes_in_group("persistent"):
		if node is MeadowCoin:
			coins.append(node)
	_check(coins.size() > 2, "Level creates collectible coins")
	coins[0].collect()
	level.capture_checkpoint(&"test", Vector2(500, 315))
	var checkpoint_score := GameSession.score
	coins[1].collect()
	_check(GameSession.score > checkpoint_score, "Collecting after a checkpoint increases score")
	GameSession.restore_checkpoint_stats()
	level._restore_world_state(GameSession.checkpoint_world)
	_check(coins[0].collected, "Objects collected before the checkpoint stay collected")
	_check(not coins[1].collected, "Objects collected after the checkpoint are restored")
	_check(GameSession.score == checkpoint_score, "Checkpoint restore prevents score duplication")

	# Pickups advance small -> grown -> fire, then damage steps down one tier.
	GameSession.set_power(GameSession.PowerState.SMALL)
	level.player.collect_powerup(MeadowPowerUp.PowerUpType.MUSHROOM)
	_check(GameSession.power_state == GameSession.PowerState.GROWN, "First power-up grows a small player")
	level.player.collect_powerup(MeadowPowerUp.PowerUpType.FLOWER)
	_check(GameSession.power_state == GameSession.PowerState.FIRE, "Second power-up grants the fire state")
	level.player._shoot_cooldown = 0.0
	level.player.shoot_fireball()
	_check(get_tree().get_nodes_in_group("player_fireballs").size() == 1, "Fire state launches a projectile")
	for fireball in get_tree().get_nodes_in_group("player_fireballs"):
		fireball.queue_free()
	GameSession.set_power(GameSession.PowerState.FIRE)
	level.player.invulnerable = false
	level.player.take_damage()
	_check(GameSession.power_state == GameSession.PowerState.GROWN, "Damage removes fire power before shrinking")
	GameSession.set_power(GameSession.PowerState.GROWN)
	level.player.invulnerable = false
	level.player.take_damage()
	_check(GameSession.power_state == GameSession.PowerState.SMALL, "Damage shrinks a grown player")
	_check(not level.player.dead, "A grown player survives one hit")
	level.player.invulnerable = false
	level.player.take_damage(true)
	_check(level.player.dead, "A small player enters the death state")
	await get_tree().create_timer(1.0).timeout
	_check(not level.player.dead, "Death respawns the player at the active checkpoint")
	_check(level.player.global_position.distance_to(GameSession.checkpoint_position) < 2.0, "Respawn uses the checkpoint position")

	GameSession.set_paused(true)
	_check(get_tree().paused, "Pause freezes the scene tree")
	GameSession.set_paused(false)
	_check(not get_tree().paused, "Pause can resume gameplay")

	# Record data round-trips, while invalid local data falls back safely.
	var old_best_score := GameSession.best_score
	var old_best_time := GameSession.best_time
	var record_path := "user://meadow_dash_record_test.cfg"
	GameSession.best_score = 4321
	GameSession.best_time = 98.5
	GameSession.save_records(record_path)
	GameSession.best_score = 0
	GameSession.best_time = 0.0
	GameSession.load_records(record_path)
	_check(GameSession.best_score == 4321 and is_equal_approx(GameSession.best_time, 98.5), "Best records persist through ConfigFile")
	var corrupt_path := "user://meadow_dash_corrupt_test.cfg"
	var corrupt_file := FileAccess.open(corrupt_path, FileAccess.WRITE)
	corrupt_file.store_string("this is not a ConfigFile")
	corrupt_file.close()
	GameSession.load_records(corrupt_path)
	_check(GameSession.best_score == 0 and GameSession.best_time == 0.0, "Corrupt save data uses safe record defaults")
	GameSession.best_score = old_best_score
	GameSession.best_time = old_best_time
	DirAccess.remove_absolute(ProjectSettings.globalize_path(record_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(corrupt_path))

	# The portal transition swaps the complete world theme and creates a safe night checkpoint.
	level._transition_to_night()
	await get_tree().create_timer(1.05).timeout
	_check(level.world_mode == MeadowGrassland.WorldMode.NIGHT, "Portal changes the level into night mode")
	_check(level._terrain.night_mode, "Night transition swaps the terrain tiles and palette")
	_check(GameSession.checkpoint_id == &"night_entry", "Night world starts with a safe checkpoint")
	_check(level.player.global_position.distance_to(MeadowGrassland.NIGHT_SPAWN) < 3.0, "Portal transports the player to the night world")

	level.queue_free()
	await level.tree_exited

	# On-screen mobile controls press and release the same actions as hardware.
	var game := preload("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var touch_left := game.find_child("TouchLeft", true, false) as TouchScreenButton
	var touch_jump := game.find_child("TouchJump", true, false) as TouchScreenButton
	var touch_down := game.find_child("TouchDown", true, false) as TouchScreenButton
	var touch_fire := game.find_child("TouchFire", true, false) as TouchScreenButton
	_check(touch_left != null and touch_jump != null and touch_down != null and touch_fire != null, "Mobile movement, down-entry, jump, and fire controls are available")
	_check(game.top_bar.size.x < 300.0 and game.top_bar.color.r > 0.8, "HUD uses a compact yellow side panel")
	if touch_left and touch_jump and touch_down and touch_fire:
		_check(touch_left.action == &"move_left", "Mobile left control maps directly to left movement")
		_check(touch_jump.action == &"jump", "Mobile jump control maps directly to jump")
		_check(touch_down.action == &"move_down", "Mobile down control maps directly to portal entry")
		_check(touch_fire.action == &"fire", "Mobile fire control maps directly to fire")
	game.queue_free()
	await game.tree_exited

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
