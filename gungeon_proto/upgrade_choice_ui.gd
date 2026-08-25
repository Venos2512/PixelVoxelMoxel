extends Control

var upgrade_system: Node

var choices: Array[String] = []

var title_label: Label
var buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()

	backdrop.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	backdrop.color = Color(
		0.01,
		0.01,
		0.02,
		0.80
	)

	backdrop.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	add_child(backdrop)

	var panel := ColorRect.new()

	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5

	panel.offset_left = -280.0
	panel.offset_right = 280.0
	panel.offset_top = -145.0
	panel.offset_bottom = 145.0

	panel.color = Color(
		0.07,
		0.075,
		0.10,
		0.98
	)

	add_child(panel)

	var box := VBoxContainer.new()

	box.position = Vector2(
		22,
		18
	)

	box.size = Vector2(
		516,
		254
	)

	box.add_theme_constant_override(
		"separation",
		10
	)

	panel.add_child(box)

	title_label = Label.new()

	title_label.text = "CHOOSE 1 UPGRADE"

	title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title_label.add_theme_font_size_override(
		"font_size",
		18
	)

	title_label.custom_minimum_size = Vector2(
		0,
		35
	)

	box.add_child(title_label)

	for i in range(3):
		var button := Button.new()

		button.custom_minimum_size = Vector2(
			0,
			58
		)

		button.add_theme_font_size_override(
			"font_size",
			12
		)

		button.pressed.connect(
			_select_choice.bind(i)
		)

		box.add_child(button)

		buttons.append(button)

	visible = false


func open_for_system(
	system: Node,
	source_type: String = "normal"
) -> void:
	if not is_instance_valid(system):
		return

	upgrade_system = system

	var result = upgrade_system.call(
		"get_random_choices",
		3,
		source_type
	)

	if typeof(result) != TYPE_ARRAY:
		return

	choices.clear()

	for value in result:
		choices.append(
			str(value)
		)

	if choices.is_empty():
		return

	for i in range(buttons.size()):
		var button: Button = buttons[i]

		if i >= choices.size():
			button.visible = false
			continue

		button.visible = true

		var upgrade_id: String = choices[i]

		var info_value = upgrade_system.call(
			"get_upgrade_info",
			upgrade_id
		)

		if typeof(info_value) != TYPE_DICTIONARY:
			continue

		var info: Dictionary = info_value

		var stack_count: int = int(
			upgrade_system.call(
				"get_stack_count",
				upgrade_id
			)
		)

		button.text = (
			"["
			+ str(i + 1)
			+ "] "
			+ str(info["name"])
			+ "  -  "
			+ str(info["rarity"])
			+ "\n"
			+ str(info["description"])
			+ "   STACK "
			+ str(stack_count)
		)

	visible = true

	get_tree().paused = true


func _input(
	event: InputEvent
) -> void:
	if not visible:
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		var key_event := event as InputEventKey

		if key_event.keycode == KEY_1:
			_select_choice(0)

		elif key_event.keycode == KEY_2:
			_select_choice(1)

		elif key_event.keycode == KEY_3:
			_select_choice(2)


func _select_choice(
	index: int
) -> void:
	if index < 0:
		return

	if index >= choices.size():
		return

	if not is_instance_valid(upgrade_system):
		return

	var upgrade_id: String = choices[index]

	upgrade_system.call(
		"apply_upgrade",
		upgrade_id
	)

	visible = false

	get_tree().paused = false