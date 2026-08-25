extends Node2D

var weapon_id: String = "shotgun"

var pickup_radius: float = 30.0

var e_key_was_down: bool = false

var label: Label


func _ready() -> void:
	add_to_group("room_pickups")

	label = Label.new()

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.position = Vector2(-50, 17)
	label.size = Vector2(100, 24)

	label.add_theme_font_size_override(
		"font_size",
		9
	)

	add_child(label)

	_update_label()

	queue_redraw()


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group(
		"player"
	)

	var e_key_down: bool = Input.is_key_pressed(
		KEY_E
	)

	if is_instance_valid(player):
		var player_node: Node2D = player as Node2D

		var distance: float = global_position.distance_to(
			player_node.global_position
		)

		if distance <= pickup_radius:
			label.visible = true

			if (
				e_key_down
				and not e_key_was_down
			):
				if player.has_method(
					"equip_weapon_pickup"
				):
					player.equip_weapon_pickup(
						weapon_id
					)

					var scene: Node = (
						get_tree().current_scene
					)

					if (
						is_instance_valid(scene)
						and scene.has_method(
							"notify_weapon_picked"
						)
					):
						scene.call(
							"notify_weapon_picked",
							weapon_id
						)

					queue_free()
					return
		else:
			label.visible = false

	e_key_was_down = e_key_down


func _update_label() -> void:
	if weapon_id == "shotgun":
		label.text = "[E] SHOTGUN"

	elif weapon_id == "machine_gun":
		label.text = "[E] MACHINE GUN"

	elif weapon_id == "sword":
		label.text = "[E] SWORD"

	else:
		label.text = "[E] WEAPON"


func _draw() -> void:
	# Pickup shadow.
	draw_rect(
		Rect2(-13, 7, 26, 6),
		Color8(10, 10, 14, 160),
		true
	)

	# Pickup pedestal.
	draw_rect(
		Rect2(-15, 5, 30, 5),
		Color8(79, 63, 57),
		true
	)

	if weapon_id == "sword":
		# Sword handle.
		draw_line(
			Vector2(-9, 7),
			Vector2(-3, 1),
			Color8(110, 70, 42),
			5.0
		)

		# Sword guard.
		draw_line(
			Vector2(-7, -1),
			Vector2(0, 6),
			Color8(225, 180, 65),
			3.0
		)

		# Blade outline.
		draw_line(
			Vector2(-3, 1),
			Vector2(12, -14),
			Color8(70, 78, 90),
			6.0
		)

		# Blade.
		draw_line(
			Vector2(-3, 1),
			Vector2(12, -14),
			Color8(220, 230, 238),
			3.0
		)

	else:
		var body_color: Color = Color8(
			210,
			170,
			65
		)

		if weapon_id == "machine_gun":
			body_color = Color8(
				110,
				200,
				125
			)

		draw_rect(
			Rect2(-12, -3, 24, 6),
			body_color,
			true
		)

		draw_rect(
			Rect2(6, 2, 5, 7),
			Color8(75, 65, 62),
			true
		)

	# Sparkle pixels.
	draw_rect(
		Rect2(-16, -10, 2, 2),
		Color8(255, 235, 150),
		true
	)

	draw_rect(
		Rect2(15, -5, 2, 2),
		Color8(255, 235, 150),
		true
	)