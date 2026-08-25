extends Node2D

var activation_radius: float = 38.0
var e_key_was_down: bool = false

var label: Label


func _ready() -> void:
	add_to_group("room_pickups")

	label = Label.new()

	label.text = "[E] NEXT FLOOR"

	label.position = Vector2(-60, 25)
	label.size = Vector2(120, 24)

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.add_theme_font_size_override(
		"font_size",
		10
	)

	add_child(label)

	queue_redraw()


func _process(_delta: float) -> void:
	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if not is_instance_valid(player_value):
		return

	var player: Node2D = player_value as Node2D

	var distance: float = global_position.distance_to(
		player.global_position
	)

	label.visible = (
		distance <= activation_radius
	)

	var e_down: bool = Input.is_key_pressed(
		KEY_E
	)

	if (
		distance <= activation_radius
		and e_down
		and not e_key_was_down
	):
		var scene: Node = get_tree().current_scene

		if scene.has_method("advance_floor"):
			scene.call("advance_floor")

	e_key_was_down = e_down


func _draw() -> void:
	# Shadow.
	_draw_portal_shadow()

	# Portal rings.
	draw_circle(
		Vector2.ZERO,
		22.0,
		Color8(38, 28, 55)
	)

	draw_circle(
		Vector2.ZERO,
		17.0,
		Color8(90, 55, 150)
	)

	draw_circle(
		Vector2.ZERO,
		11.0,
		Color8(95, 180, 230)
	)

	draw_circle(
		Vector2.ZERO,
		5.0,
		Color8(225, 245, 255)
	)


func _draw_portal_shadow() -> void:
	draw_rect(
		Rect2(-26, 17, 52, 8),
		Color8(5, 5, 10, 160),
		true
	)