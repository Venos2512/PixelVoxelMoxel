extends CanvasLayer

const TrainingRoomControllerScript = preload(
	"res://gungeon_proto/training_room_controller_v2.gd"
)

var root_background: ColorRect

var main_container: VBoxContainer
var relic_choice_container: VBoxContainer

var codex_layer: Control

var relic_system: Node


func _ready() -> void:
	layer = 200

	process_mode = (
		Node.PROCESS_MODE_WHEN_PAUSED
	)

	_build_menu()

	get_tree().paused = true


func _build_menu() -> void:
	root_background = ColorRect.new()

	root_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root_background.color = Color(
		0.035,
		0.025,
		0.04,
		1.0
	)

	add_child(
		root_background
	)

	_build_background_decoration()

	var center: CenterContainer = (
		CenterContainer.new()
	)

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root_background.add_child(
		center
	)

	var panel: PanelContainer = (
		PanelContainer.new()
	)

	panel.custom_minimum_size = Vector2(
		520.0,
		560.0
	)

	center.add_child(
		panel
	)

	main_container = VBoxContainer.new()

	main_container.add_theme_constant_override(
		"separation",
		18
	)

	panel.add_child(
		main_container
	)

	var spacer_top: Control = Control.new()

	spacer_top.custom_minimum_size = Vector2(
		1.0,
		40.0
	)

	main_container.add_child(
		spacer_top
	)

	var title: Label = Label.new()

	title.text = "DUNGEON DESCENT"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		38
	)

	title.add_theme_color_override(
		"font_color",
		Color(
			0.95,
			0.78,
			0.40
		)
	)

	main_container.add_child(
		title
	)

	var subtitle: Label = Label.new()

	subtitle.text = (
		"ENTER. DIE. RETURN STRONGER."
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.add_theme_font_size_override(
		"font_size",
		12
	)

	subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.56,
			0.53,
			0.58
		)
	)

	main_container.add_child(
		subtitle
	)

	var spacer: Control = Control.new()

	spacer.custom_minimum_size = Vector2(
		1.0,
		55.0
	)

	main_container.add_child(
		spacer
	)

	var start_button: Button = (
		_create_menu_button(
			"START RUN"
		)
	)

	start_button.pressed.connect(
		_on_start_pressed
	)

	main_container.add_child(
		start_button
	)

	var training_button: Button = (
		_create_menu_button(
			"TRAINING ROOM"
		)
	)

	training_button.pressed.connect(
		_on_training_pressed
	)

	main_container.add_child(
		training_button
	)

	var relic_button: Button = (
		_create_menu_button(
			"RELICS"
		)
	)

	relic_button.pressed.connect(
		_on_relic_codex_pressed
	)

	main_container.add_child(
		relic_button
	)

	var quit_button: Button = (
		_create_menu_button(
			"QUIT"
		)
	)

	quit_button.pressed.connect(
		_on_quit_pressed
	)

	main_container.add_child(
		quit_button
	)

	var controls_label: Label = Label.new()

	controls_label.text = (
		"WASD MOVE  •  LMB ATTACK / THROW  •  E INTERACT  •  SPACE DODGE"
	)

	controls_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	controls_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	controls_label.add_theme_font_size_override(
		"font_size",
		10
	)

	controls_label.add_theme_color_override(
		"font_color",
		Color(
			0.46,
			0.44,
			0.48
		)
	)

	main_container.add_child(
		controls_label
	)

	_build_relic_choice(
		panel
	)

	_build_codex()


func _build_background_decoration() -> void:
	var top_bar: ColorRect = ColorRect.new()

	top_bar.anchor_right = 1.0

	top_bar.offset_bottom = 5.0

	top_bar.color = Color(
		0.44,
		0.17,
		0.12
	)

	root_background.add_child(
		top_bar
	)

	var bottom_bar: ColorRect = ColorRect.new()

	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0

	bottom_bar.offset_top = -5.0

	bottom_bar.color = Color(
		0.44,
		0.17,
		0.12
	)

	root_background.add_child(
		bottom_bar
	)


func _create_menu_button(
	button_text: String
) -> Button:
	var button: Button = Button.new()

	button.text = button_text

	button.custom_minimum_size = Vector2(
		360.0,
		52.0
	)

	button.add_theme_font_size_override(
		"font_size",
		18
	)

	return button


func _build_relic_choice(
	panel: PanelContainer
) -> void:
	relic_choice_container = VBoxContainer.new()

	relic_choice_container.visible = false

	relic_choice_container.add_theme_constant_override(
		"separation",
		14
	)

	panel.add_child(
		relic_choice_container
	)


func _on_start_pressed() -> void:
	relic_system = _get_relic_system()

	if not is_instance_valid(
		relic_system
	):
		_start_game_without_relic()

		return

	main_container.visible = false
	relic_choice_container.visible = true

	_clear_children(
		relic_choice_container
	)

	var top_space: Control = Control.new()

	top_space.custom_minimum_size = Vector2(
		1.0,
		30.0
	)

	relic_choice_container.add_child(
		top_space
	)

	var title: Label = Label.new()

	title.text = "CHOOSE A RELIC"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		27
	)

	relic_choice_container.add_child(
		title
	)

	var subtitle: Label = Label.new()

	subtitle.text = (
		"Every run begins with one strange advantage."
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.60,
			0.57,
			0.62
		)
	)

	relic_choice_container.add_child(
		subtitle
	)

	var ids_value: Variant = relic_system.call(
		"get_random_relic_ids",
		3
	)

	var ids: Array = []

	if typeof(
		ids_value
	) == TYPE_ARRAY:
		ids = ids_value

	var catalog_value: Variant = relic_system.call(
		"get_catalog"
	)

	var catalog: Dictionary = {}

	if typeof(
		catalog_value
	) == TYPE_DICTIONARY:
		catalog = catalog_value

	for relic_id_value: Variant in ids:
		var relic_id: String = str(
			relic_id_value
		)

		if not catalog.has(
			relic_id
		):
			continue

		var relic_data: Dictionary = catalog[
			relic_id
		]

		var relic_name: String = str(
			relic_data.get(
				"name",
				relic_id
			)
		)

		var rarity: String = str(
			relic_data.get(
				"rarity",
				"COMMON"
			)
		)

		var description: String = str(
			relic_data.get(
				"description",
				""
			)
		)

		var card: Button = Button.new()

		card.text = (
			relic_name
			+ "\n"
			+ "["
			+ rarity
			+ "]\n"
			+ description
		)

		card.custom_minimum_size = Vector2(
			430.0,
			95.0
		)

		card.add_theme_font_size_override(
			"font_size",
			14
		)

		card.pressed.connect(
			_on_relic_selected.bind(
				relic_id
			)
		)

		relic_choice_container.add_child(
			card
		)

	var back_button: Button = Button.new()

	back_button.text = "BACK"

	back_button.custom_minimum_size = Vector2(
		220.0,
		42.0
	)

	back_button.pressed.connect(
		_on_choice_back_pressed
	)

	relic_choice_container.add_child(
		back_button
	)


func _on_training_pressed() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var training_room: CanvasLayer = (
		TrainingRoomControllerScript.new()
		as CanvasLayer
	)

	scene.add_child(
		training_room
	)

	root_background.visible = false

	get_tree().paused = false


func _on_relic_selected(
	relic_id: String
) -> void:
	if is_instance_valid(
		relic_system
	):
		relic_system.call(
			"acquire_relic",
			relic_id
		)

	root_background.visible = false

	get_tree().paused = false


func _start_game_without_relic() -> void:
	root_background.visible = false

	get_tree().paused = false


func _on_choice_back_pressed() -> void:
	relic_choice_container.visible = false
	main_container.visible = true


func _build_codex() -> void:
	codex_layer = Control.new()

	codex_layer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	codex_layer.visible = false

	add_child(
		codex_layer
	)

	var background: ColorRect = ColorRect.new()

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.color = Color(
		0.025,
		0.02,
		0.03,
		1.0
	)

	codex_layer.add_child(
		background
	)

	var margin: MarginContainer = (
		MarginContainer.new()
	)

	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	margin.add_theme_constant_override(
		"margin_left",
		80
	)

	margin.add_theme_constant_override(
		"margin_right",
		80
	)

	margin.add_theme_constant_override(
		"margin_top",
		55
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		55
	)

	codex_layer.add_child(
		margin
	)

	var layout: VBoxContainer = (
		VBoxContainer.new()
	)

	layout.add_theme_constant_override(
		"separation",
		14
	)

	margin.add_child(
		layout
	)

	var title: Label = Label.new()

	title.text = "RELIC ARCHIVE"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		30
	)

	layout.add_child(
		title
	)

	var scroll: ScrollContainer = (
		ScrollContainer.new()
	)

	scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	layout.add_child(
		scroll
	)

	var relic_list: VBoxContainer = (
		VBoxContainer.new()
	)

	relic_list.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	relic_list.add_theme_constant_override(
		"separation",
		8
	)

	scroll.add_child(
		relic_list
	)

	var system: Node = _get_relic_system()

	if is_instance_valid(
		system
	):
		var catalog_value: Variant = system.call(
			"get_catalog"
		)

		if typeof(
			catalog_value
		) == TYPE_DICTIONARY:
			var catalog: Dictionary = (
				catalog_value
			)

			for relic_key: Variant in catalog.keys():
				var relic_data: Dictionary = catalog[
					relic_key
				]

				var entry: Label = Label.new()

				entry.text = (
					str(
						relic_data.get(
							"name",
							relic_key
						)
					)
					+ "  ["
					+ str(
						relic_data.get(
							"rarity",
							"COMMON"
						)
					)
					+ "]\n"
					+ str(
						relic_data.get(
							"description",
							""
						)
					)
				)

				entry.custom_minimum_size = Vector2(
					1.0,
					55.0
				)

				entry.add_theme_font_size_override(
					"font_size",
					14
				)

				relic_list.add_child(
					entry
				)

	var back_button: Button = Button.new()

	back_button.text = "BACK"

	back_button.custom_minimum_size = Vector2(
		260.0,
		46.0
	)

	back_button.pressed.connect(
		_on_codex_back_pressed
	)

	layout.add_child(
		back_button
	)


func _on_relic_codex_pressed() -> void:
	root_background.visible = false
	codex_layer.visible = true


func _on_codex_back_pressed() -> void:
	codex_layer.visible = false
	root_background.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _get_relic_system() -> Node:
	var system_value: Node = (
		get_tree().get_first_node_in_group(
			"relic_system"
		)
	)

	if not is_instance_valid(
		system_value
	):
		return null

	return system_value


func _clear_children(
	target: Node
) -> void:
	for child: Node in target.get_children():
		child.queue_free()