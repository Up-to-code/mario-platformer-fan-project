class_name MeadowCheckpoint
extends Area2D

@export var persistent_id: StringName
var activated := false

func _ready() -> void:
	add_to_group("persistent")
	collision_layer = 8
	collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 72)
	shape_node.position.y = -36
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)

func _draw() -> void:
	draw_rect(Rect2(-2, -70, 4, 70), Color("6e4b2a"))
	var tile := 312 if activated else 310
	MeadowArt.draw_tile(self, tile, Rect2(1, -67, 21, 21))
	if activated:
		draw_circle(Vector2(0, -2), 5.0, Color("ffe15b"))

func activate_checkpoint(player: MeadowPlayer) -> void:
	if activated:
		return
	activated = true
	AudioManager.play_sfx(&"coin", 0.02)
	GameSession.add_score(500)
	var level := get_parent()
	if level.has_method("capture_checkpoint"):
		level.capture_checkpoint(persistent_id, global_position + Vector2(28, 0))
	if level.has_method("burst"):
		level.burst(global_position - Vector2(0, 35), Color("ffe15b"), 16)
	player.shake(0.08)
	queue_redraw()

func get_persistent_state() -> Dictionary:
	return {"activated": activated}

func restore_persistent_state(state: Dictionary) -> void:
	activated = bool(state.get("activated", false))
	monitoring = not activated
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body is MeadowPlayer:
		activate_checkpoint(body)
