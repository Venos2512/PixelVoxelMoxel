extends Node2D

var source_type: String = "elite"

var activation_radius: float = 38.0

var e_key_was_down: bool = false

var label: Label


func _ready() -> void:
	add_to_group("room_pickups")

	label = Label.new()

	label.position = Vector2(
		-55,
		22
	)

	label.size = Vector2(
		110,
		24
	)

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.add_theme_font_size_override(
		"font_size",
		10
	)

	label.text = "[E] OPEN CHEST"

	add_child(label)

	label.visible = false

	queue_redraw()


func _process(
	_delta: float
) -> void:
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

		if scene.has_method(
			"notify_upgrade_chest_opened"
		):
			scene.call(
				"notify_upgrade_chest_opened"
			)

		if scene.has_method(
			"open_upgrade_choice"
		):
			scene.call(
				"open_upgrade_choice",
				source_type
			)

			queue_free()
			return

	e_key_was_down = e_down


func _draw() -> void:
	draw_rect(
		Rect2(-20, 12, 40, 7),
		Color8(8, 8, 12, 160),
		true
	)

	var body_color := Color8(
		156,
		92,
		38
	)

	var trim_color := Color8(
		225,
		175,
		62
	)

	if source_type == "boss":
		body_color = Color8(
			105,
			55,
			125
		)

		trim_color = Color8(
			220,
			115,
			235
		)

	elif source_type == "treasure":
		body_color = Color8(
			175,
			120,
			36
		)

		trim_color = Color8(
			255,
			220,
			80
		)

	draw_rect(
		Rect2(-18, -4, 36, 18),
		body_color,
		true
	)

	draw_rect(
		Rect2(-18, -10, 36, 9),
		body_color.lightened(0.12),
		true
	)

	draw_rect(
		Rect2(-2, -10, 4, 24),
		trim_color,
		true
	)

	draw_rect(
		Rect2(-18, -3, 36, 3),
		trim_color,
		true
	)

	draw_rect(
		Rect2(-4, 2, 8, 7),
		Color8(52, 42, 30),
		true
	)