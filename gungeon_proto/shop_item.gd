extends Node2D

var upgrade_id: String = ""
var display_name: String = "UPGRADE"

var rarity: String = "COMMON"

var cost: int = 15

var activation_radius: float = 38.0

var e_key_was_down: bool = false

var label: Label


func _ready() -> void:
	add_to_group("room_pickups")

	label = Label.new()

	label.position = Vector2(
		-75,
		22
	)

	label.size = Vector2(
		150,
		42
	)

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.add_theme_font_size_override(
		"font_size",
		9
	)

	label.text = (
		"[E] "
		+ display_name
		+ "\n"
		+ str(cost)
		+ " GOLD"
	)

	add_child(label)

	label.visible = false

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

		if scene.has_method(
			"try_purchase_upgrade"
		):
			var success_value = scene.call(
				"try_purchase_upgrade",
				upgrade_id,
				cost
			)

			if bool(success_value):
				queue_free()
				return

	e_key_was_down = e_down


func _draw() -> void:
	draw_rect(
		Rect2(-20, 12, 40, 6),
		Color8(8, 8, 12, 150),
		true
	)

	var rarity_color := Color8(
		120,
		125,
		135
	)

	if rarity == "RARE":
		rarity_color = Color8(
			65,
			145,
			225
		)

	elif rarity == "EPIC":
		rarity_color = Color8(
			190,
			80,
			225
		)

	draw_rect(
		Rect2(-17, -6, 34, 19),
		Color8(65, 52, 46),
		true
	)

	draw_rect(
		Rect2(-14, -12, 28, 8),
		rarity_color,
		true
	)

	draw_rect(
		Rect2(-3, -3, 6, 8),
		Color8(240, 195, 65),
		true
	)

	draw_circle(
		Vector2(0, -16),
		3.0,
		rarity_color
	)