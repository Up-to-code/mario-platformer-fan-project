extends Node

const LevelScene := preload("res://levels/grassland.tscn")

var level: MeadowGrassland
var canvas: CanvasLayer
var night_sky: MeadowNightSky
var hud: Control
var top_bar: ColorRect
var score_label: Label
var coins_label: Label
var time_label: Label
var power_label: Label
var title_screen: Control
var pause_screen: Control
var victory_screen: Control
var death_banner: Label
var title_records: Label
var victory_summary: Label
var mobile_controls: Control
var touch_controls_enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_controls_enabled = OS.has_feature("mobile")
	_build_background()
	_build_interface()
	_connect_session()
	_show_title()

func _process(_delta: float) -> void:
	if hud.visible:
		time_label.text = "TIME  %s" % GameSession.format_time(GameSession.elapsed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and level and GameSession.running:
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _build_background() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -20
	add_child(background_layer)
	night_sky = MeadowNightSky.new()
	night_sky.z_index = -90
	background_layer.add_child(night_sky)
	night_sky.set_night(false)

func _build_interface() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)
	top_bar = ColorRect.new()
	top_bar.color = Color("f5cb38")
	top_bar.position = Vector2(12, 10)
	top_bar.size = Vector2(252, 50)
	hud.add_child(top_bar)
	var stats := GridContainer.new()
	stats.columns = 2
	stats.position = Vector2(20, 13)
	stats.add_theme_constant_override("h_separation", 22)
	stats.add_theme_constant_override("v_separation", -2)
	hud.add_child(stats)
	score_label = _make_hud_label("SCORE  000000")
	coins_label = _make_hud_label("COINS  00")
	time_label = _make_hud_label("TIME  00:00")
	power_label = _make_hud_label("SMALL")
	for label in [score_label, coins_label, time_label, power_label]: stats.add_child(label)
	_build_mobile_controls()

	title_screen = _make_overlay(Color(0.03, 0.10, 0.28, 0.42))
	var title_box := _make_panel(Vector2(398, 278))
	title_box.position = Vector2(137, 50)
	title_screen.add_child(title_box)
	var title_layout := VBoxContainer.new()
	title_layout.position = Vector2(26, 22)
	title_layout.size = Vector2(346, 230)
	title_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	title_layout.add_theme_constant_override("separation", 12)
	title_box.add_child(title_layout)
	var title := Label.new()
	title.text = "MEADOW DASH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 33)
	title.add_theme_color_override("font_color", Color("ffdc3c"))
	title_layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Run, leap, grow, and light up the meadow!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	title_layout.add_child(subtitle)
	var start_button := _make_button("START ADVENTURE")
	start_button.pressed.connect(_start_game)
	title_layout.add_child(start_button)
	var controls := Label.new()
	controls.text = "MOVE  A/D or arrows    JUMP  Space / A\nFIRE  F / C / B         SPRINT  Shift / X\nENTER PIPE  S / down"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 12)
	title_layout.add_child(controls)
	title_records = Label.new()
	title_records.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_records.add_theme_color_override("font_color", Color("ffffff"))
	title_layout.add_child(title_records)

	pause_screen = _make_overlay(Color(0.01, 0.03, 0.05, 0.72))
	var pause_box := _make_panel(Vector2(280, 205))
	pause_box.position = Vector2(196, 86)
	pause_screen.add_child(pause_box)
	var pause_layout := VBoxContainer.new()
	pause_layout.position = Vector2(30, 22)
	pause_layout.size = Vector2(220, 165)
	pause_layout.add_theme_constant_override("separation", 12)
	pause_box.add_child(pause_layout)
	pause_layout.add_child(_make_title("PAUSED", 27))
	var resume := _make_button("RESUME")
	resume.pressed.connect(_toggle_pause)
	pause_layout.add_child(resume)
	var retry := _make_button("RESTART LEVEL")
	retry.pressed.connect(_restart_game)
	pause_layout.add_child(retry)
	var quit := _make_button("RETURN TO TITLE")
	quit.pressed.connect(_return_to_title)
	pause_layout.add_child(quit)

	victory_screen = _make_overlay(Color(0.02, 0.10, 0.11, 0.76))
	var victory_box := _make_panel(Vector2(360, 255))
	victory_box.position = Vector2(156, 62)
	victory_screen.add_child(victory_box)
	var victory_layout := VBoxContainer.new()
	victory_layout.position = Vector2(28, 22)
	victory_layout.size = Vector2(304, 215)
	victory_layout.add_theme_constant_override("separation", 12)
	victory_box.add_child(victory_layout)
	victory_layout.add_child(_make_title("MEADOW CLEARED!", 25))
	victory_summary = Label.new()
	victory_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_summary.add_theme_font_size_override("font_size", 16)
	victory_layout.add_child(victory_summary)
	var again := _make_button("RUN AGAIN")
	again.pressed.connect(_restart_game)
	victory_layout.add_child(again)
	var title_button := _make_button("RETURN TO TITLE")
	title_button.pressed.connect(_return_to_title)
	victory_layout.add_child(title_button)

	death_banner = Label.new()
	death_banner.text = "TRY AGAIN!"
	death_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_banner.position = Vector2(236, 156)
	death_banner.size = Vector2(200, 54)
	death_banner.add_theme_font_size_override("font_size", 26)
	death_banner.add_theme_color_override("font_color", Color("fff0a0"))
	death_banner.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.08, 0.1, 0.9), Color("fff0a0"), 2))
	death_banner.visible = false
	canvas.add_child(death_banner)

func _connect_session() -> void:
	GameSession.score_changed.connect(func(value: int): score_label.text = "SCORE  %06d" % value)
	GameSession.coins_changed.connect(func(value: int): coins_label.text = "COINS  %02d" % value)
	GameSession.power_changed.connect(_on_power_changed)
	GameSession.player_died.connect(_on_player_died)
	GameSession.victory.connect(_on_victory)

func _start_game() -> void:
	GameSession.set_paused(false)
	AudioManager.reset_music()
	_release_mobile_actions()
	if is_instance_valid(level):
		level.queue_free()
		await level.tree_exited
	level = LevelScene.instantiate()
	add_child(level)
	level.world_mode_changed.connect(_on_world_mode_changed)
	_on_world_mode_changed(false)
	title_screen.visible = false
	pause_screen.visible = false
	victory_screen.visible = false
	hud.visible = true
	mobile_controls.visible = touch_controls_enabled

func _restart_game() -> void:
	await _start_game()

func _return_to_title() -> void:
	_release_mobile_actions()
	GameSession.running = false
	GameSession.set_paused(false)
	if is_instance_valid(level):
		level.queue_free()
		level = null
	_show_title()

func _show_title() -> void:
	AudioManager.set_world_music(false)
	hud.visible = false
	mobile_controls.visible = false
	pause_screen.visible = false
	victory_screen.visible = false
	title_screen.visible = true
	night_sky.set_night(false)
	top_bar.color = Color("f5cb38")
	var time_record := "--:--" if GameSession.best_time <= 0.0 else GameSession.format_time(GameSession.best_time)
	title_records.text = "BEST  %06d     FASTEST  %s" % [GameSession.best_score, time_record]

func _toggle_pause() -> void:
	_release_mobile_actions()
	var next := not get_tree().paused
	GameSession.set_paused(next)
	pause_screen.visible = next
	mobile_controls.visible = touch_controls_enabled and not next
	if next:
		var first_button := pause_screen.find_children("", "Button", true, false).front() as Button
		first_button.grab_focus()

func _on_player_died() -> void:
	death_banner.visible = true
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	death_banner.modulate.a = 0.0
	tween.tween_property(death_banner, "modulate:a", 1.0, 0.12)
	tween.tween_interval(0.48)
	tween.tween_property(death_banner, "modulate:a", 0.0, 0.18)
	await tween.finished
	death_banner.visible = false

func _on_victory(run_score: int, run_time: float, new_score: bool, new_time: bool) -> void:
	_release_mobile_actions()
	mobile_controls.visible = false
	var records := ""
	if new_score: records += "\nNEW BEST SCORE!"
	if new_time: records += "\nNEW FASTEST TIME!"
	victory_summary.text = "SCORE  %06d\nCOINS  %02d\nTIME   %s%s" % [run_score, GameSession.coins, GameSession.format_time(run_time), records]
	victory_screen.visible = true
	GameSession.set_paused(true)
	var buttons := victory_screen.find_children("", "Button", true, false)
	if not buttons.is_empty():
		(buttons.front() as Button).grab_focus()

func _on_world_mode_changed(is_night: bool) -> void:
	night_sky.set_night(is_night)
	top_bar.color = Color("e9bd35") if is_night else Color("f5cb38")
	power_label.add_theme_color_override("font_color", Color("143b82"))

func _make_overlay(color: Color) -> Control:
	var overlay := Control.new()
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = color
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	canvas.add_child(overlay)
	return overlay

func _make_panel(size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(Color("16499a"), Color("ffdc3c"), 4))
	return panel

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 34)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _panel_style(Color("d9362b"), Color("ffdc3c"), 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color("f05a2a"), Color.WHITE, 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color("f05a2a"), Color("ffdc3c"), 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("a92025"), Color.WHITE, 2))
	button.pressed.connect(func(): AudioManager.play_sfx(&"click", 0.03))
	return button

func _build_mobile_controls() -> void:
	mobile_controls = Control.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(mobile_controls)
	var left := _make_touch_button("TouchLeft", "<", Vector2(22, 294), Vector2(62, 62), &"move_left")
	var right := _make_touch_button("TouchRight", ">", Vector2(92, 294), Vector2(62, 62), &"move_right")
	var down := _make_touch_button("TouchDown", "v", Vector2(64, 235), Vector2(50, 50), &"move_down")
	var fire_button := _make_touch_button("TouchFire", "FIRE", Vector2(438, 301), Vector2(58, 55), &"fire")
	var sprint_button := _make_touch_button("TouchSprint", "RUN", Vector2(500, 301), Vector2(58, 55), &"sprint")
	var jump_button := _make_touch_button("TouchJump", "JUMP", Vector2(574, 284), Vector2(76, 72), &"jump")
	var pause_button := _make_touch_button("TouchPause", "II", Vector2(615, 50), Vector2(38, 34), &"")
	pause_button.pressed.connect(_toggle_pause)
	for button in [left, right, down, fire_button, sprint_button, jump_button]:
		button.modulate = Color(1, 1, 1, 0.78)
	pause_button.modulate = Color(1, 1, 1, 0.72)
	mobile_controls.visible = false

func _make_touch_button(node_name: String, text: String, position: Vector2, size: Vector2, action: StringName) -> TouchScreenButton:
	var button := TouchScreenButton.new()
	button.name = node_name
	button.position = position
	button.texture_normal = _touch_texture(size, Color(0.06, 0.20, 0.52, 0.76))
	button.texture_pressed = _touch_texture(size, Color(0.85, 0.18, 0.15, 0.92))
	button.passby_press = true
	if not action.is_empty():
		button.action = action
	var label := Label.new()
	label.text = text
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("fff3bd"))
	button.add_child(label)
	mobile_controls.add_child(button)
	return button

func _touch_texture(size: Vector2, color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = int(size.x)
	texture.height = int(size.y)
	return texture

func _release_mobile_actions() -> void:
	for action in [&"move_left", &"move_right", &"move_down", &"jump", &"sprint", &"fire"]:
		Input.action_release(action)

func _make_hud_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(105, 18)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("143b82"))
	return label

func _make_title(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("ffe46b"))
	return label

func _on_power_changed(value: int) -> void:
	match value:
		GameSession.PowerState.GROWN:
			power_label.text = "GROWN"
		GameSession.PowerState.FIRE:
			power_label.text = "FIRE"
		_:
			power_label.text = "SMALL"

func _panel_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
