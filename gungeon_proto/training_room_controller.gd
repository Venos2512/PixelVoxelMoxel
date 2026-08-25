extends CanvasLayer

const TrainingDummyScript = preload(
	"res://gungeon_proto/training_dummy.gd"
)

const TRAINING_BOUNDS: Rect2 = Rect2(
	-330.0,
	-170.0,
	660.0,
	340.0
)

var player: Node2D = null
var dummy: Node2D = null

var esc_was_down: bool = false

var status_label: Label


func _ready() -> void:
	layer = 420

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_build_ui()

	call_deferred(
		"_enter_training_room"
	)


func _process(
	_delta: float
) -> void:
	var escape_down: bool = Input.is_key_pressed(
		KEY_ESCAPE
	)

	if (
		escape_down
		and not esc_was_down
	):
		_return_to_menu()

	esc_was_down = escape_down

	if not is_instance_valid(
		player
	):
		player = _get_player()

	if is_instance_valid(
		player
	):
		_keep_player_inside_training_room()

	if not is_instance_valid(
		dummy
	):
		_spawn_dummy()


func _enter_training_room() -> void:
	_clear_existing_enemies()
	_clear_hazards()

	player = _get_player()

	if is_instance_valid(
		player
	):
		player.global_position = Vector2(
			-130.0,
			20.0
		)

		if player is CharacterBody2D:
			var body: CharacterBody2D = (
				player as CharacterBody2D
			)

			body.velocity = Vector2.ZERO

	_spawn_dummy()


func _clear_existing_enemies() -> void:
	for enemy: Node in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy
		):
			continue

		if enemy.is_in_group(
			"training_dummy"
		):
			continue

		enemy.queue_free()


func _clear_hazards() -> void:
	for hazard: Node in get_tree().get_nodes_in_group(
		"room_hazards"
	):
		if not is_instance_valid(
			hazard
		):
			continue

		hazard.queue_free()


func _spawn_dummy() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	if is_instance_valid(
		dummy
	):
		return

	dummy = (
		TrainingDummyScript.new()
		as Node2D
	)

	if not is_instance_valid(
		dummy
	):
		return

	scene.add_child(
		dummy
	)

	if dummy.has_method(
		"set_training_position"
	):
		dummy.call(
			"set_training_position",
			Vector2(
				135.0,
				10.0
			)
		)

	else:
		dummy.global_position = Vector2(
			135.0,
			10.0
		)


func _keep_player_inside_training_room() -> void:
	var position_value: Vector2 = (
		player.global_position
	)

	position_value.x = clampf(
		position_value.x,
		TRAINING_BOUNDS.position.x,
		TRAINING_BOUNDS.end.x
	)

	position_value.y = clampf(
		position_value.y,
		TRAINING_BOUNDS.position.y,
		TRAINING_BOUNDS.end.y
	)

	player.global_position = position_value


func _build_ui() -> void:
	var top_panel: PanelContainer = (
		PanelContainer.new()
	)

	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5

	top_panel.offset_left = -260.0
	top_panel.offset_right = 260.0

	top_panel.offset_top = 14.0
	top_panel.offset_bottom = 96.0

	add_child(
		top_panel
	)

	var layout: VBoxContainer = (
		VBoxContainer.new()
	)

	layout.add_theme_constant_override(
		"separation",
		4
	)

	top_panel.add_child(
		layout
	)

	var title: Label = Label.new()

	title.text = "TRAINING ROOM"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		18
	)

	title.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.80,
			0.32,
			1.0
		)
	)

	layout.add_child(
		title
	)

	status_label = Label.new()

	status_label.text = (
		"F2 SPAWN WEAPONS  •  F1 CLEAR ENEMIES  •  ESC MAIN MENU"
	)

	status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status_label.add_theme_font_size_override(
		"font_size",
		10
	)

	layout.add_child(
		status_label
	)

	var buttons: HBoxContainer = (
		HBoxContainer.new()
	)

	buttons.alignment = (
		BoxContainer.ALIGNMENT_CENTER
	)

	buttons.add_theme_constant_override(
		"separation",
		8
	)

	layout.add_child(
		buttons
	)

	var reset_button: Button = Button.new()

	reset_button.text = "RESET DUMMY"

	reset_button.pressed.connect(
		_reset_dummy
	)

	buttons.add_child(
		reset_button
	)

	var back_button: Button = Button.new()

	back_button.text = "BACK TO MENU"

	back_button.pressed.connect(
		_return_to_menu
	)

	buttons.add_child(
		back_button
	)


func _reset_dummy() -> void:
	if not is_instance_valid(
		dummy
	):
		_spawn_dummy()

		return

	if dummy.has_method(
		"reset_target"
	):
		dummy.call(
			"reset_target"
		)


func _return_to_menu() -> void:
	get_tree().paused = false

	get_tree().reload_current_scene()


func _get_player() -> Node2D:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return null

	return player_value as Node2D