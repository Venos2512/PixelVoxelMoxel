extends CanvasLayer

const TrainingArenaScript = preload(
	"res://gungeon_proto/training_arena_v2.gd"
)

const TrainingDummyScript = preload(
	"res://gungeon_proto/training_dummy_v2.gd"
)

const TrainingTurretScript = preload(
	"res://gungeon_proto/training_turret.gd"
)

const WeaponPickupScript = preload(
	"res://gungeon_proto/weapon_pickup.gd"
)

const BASE_WIDTH: float = 768.0
const BASE_HEIGHT: float = 432.0

const WEAPON_SPACING_X: float = 92.0
const WEAPON_SPACING_Y: float = 76.0

var training_bounds: Rect2

var player: Node2D = null
var dummy: Node2D = null
var turret: Node2D = null
var arena: Node2D = null

var weapon_ids: Array[String] = []

var escape_was_down: bool = false

var status_label: Label
var turret_button: Button


func _ready() -> void:
	layer = 420

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_build_ui()

	call_deferred(
		"_enter_training_room"
	)


func _enter_training_room() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	scene.set_meta(
		"training_mode",
		true
	)

	# Không disable process của dungeon root.
	# Một số gameplay system như shooting / projectile spawning
	# vẫn phụ thuộc vào cây scene đang hoạt động.
	_clear_old_training_and_room_objects()

	await get_tree().process_frame

	player = _get_player()

	if not is_instance_valid(
		player
	):
		status_label.text = "PLAYER NOT FOUND"

		return

	var weapon_system: Object = (
		_get_weapon_system(
			player
		)
	)

	if is_instance_valid(
		weapon_system
	):
		weapon_ids = _find_weapon_ids(
			weapon_system
		)

	# Fallback chắc chắn cho toàn bộ weapon hiện tại.
	# Nếu introspection không tìm được catalog thì Training Room
	# vẫn luôn có đủ weapon để test.
	if weapon_ids.is_empty():
		weapon_ids = [
			"pistol",
			"shotgun",
			"machine_gun",
			"sword",
			"spear",
			"hammer"
		]

	_calculate_training_bounds()

	_disable_old_room_boundary()

	_configure_navigation_for_training()

	_create_arena()

	_position_player()

	_spawn_dummy()

	_spawn_turret()

	_spawn_all_weapons()

	status_label.text = (
		"WEAPONS "
		+ str(
			weapon_ids.size()
		)
		+ "  •  F2 DEV TOOLS  •  ESC MAIN MENU"
	)


func _process(
	_delta: float
) -> void:
	var escape_down: bool = Input.is_key_pressed(
		KEY_ESCAPE
	)

	if (
		escape_down
		and not escape_was_down
	):
		_return_to_menu()

	escape_was_down = escape_down

	if not is_instance_valid(
		player
	):
		player = _get_player()

	if is_instance_valid(
		player
	):
		_keep_player_inside_training_room()


func _calculate_training_bounds() -> void:
	var weapon_count: int = maxi(
		1,
		weapon_ids.size()
	)

	var desired_columns: int = int(
		ceil(
			sqrt(
				float(
					weapon_count
				) * 1.6
			)
		)
	)

	var columns: int = clampi(
		desired_columns,
		4,
		10
	)

	var rows: int = int(
		ceil(
			float(
				weapon_count
			)
			/ float(
				columns
			)
		)
	)

	var required_width: float = (
		260.0
		+ float(columns)
		* WEAPON_SPACING_X
	)

	var required_height: float = (
		250.0
		+ float(rows)
		* WEAPON_SPACING_Y
	)

	var width: float = maxf(
		BASE_WIDTH,
		required_width
	)

	var height: float = maxf(
		BASE_HEIGHT,
		required_height
	)

	training_bounds = Rect2(
		-width * 0.5,
		-height * 0.5,
		width,
		height
	)


func _create_arena() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	arena = (
		TrainingArenaScript.new()
		as Node2D
	)

	arena.call(
		"configure",
		training_bounds
	)

	scene.add_child(
		arena
	)

	arena.global_position = Vector2.ZERO


func _position_player() -> void:
	# Đảm bảo player tiếp tục xử lý input/combat trong phòng tập.
	player.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_force_process_mode_always(
		player
	)

	player.global_position = Vector2(
		training_bounds.position.x
			+ 135.0,
		30.0
	)

	if player is CharacterBody2D:
		var player_body: CharacterBody2D = (
			player as CharacterBody2D
		)

		player_body.velocity = Vector2.ZERO


func _force_process_mode_always(
	node: Node
) -> void:
	node.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	for child: Node in node.get_children():
		_force_process_mode_always(
			child
		)


func _spawn_dummy() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	dummy = (
		TrainingDummyScript.new()
		as Node2D
	)

	scene.add_child(
		dummy
	)

	dummy.call(
		"set_training_position",
		Vector2(
			50.0,
			45.0
		)
	)


func _spawn_turret() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	turret = (
		TrainingTurretScript.new()
		as Node2D
	)

	scene.add_child(
		turret
	)

	turret.global_position = Vector2(
		training_bounds.end.x
			- 95.0,
		45.0
	)

	_update_turret_button()


func _spawn_all_weapons() -> void:
	if weapon_ids.is_empty():
		return

	var scene: Node = (
		get_tree().current_scene
	)

	var weapon_count: int = weapon_ids.size()

	var desired_columns: int = int(
		ceil(
			sqrt(
				float(
					weapon_count
				) * 1.6
			)
		)
	)

	var columns: int = clampi(
		desired_columns,
		4,
		10
	)

	var rows: int = int(
		ceil(
			float(
				weapon_count
			)
			/ float(
				columns
			)
		)
	)

	var rack_width: float = (
		float(
			mini(
				columns,
				weapon_count
			)
		)
		* WEAPON_SPACING_X
	)

	var start_x: float = (
		-rack_width * 0.5
		+ WEAPON_SPACING_X * 0.5
	)

	var start_y: float = (
		training_bounds.position.y
		+ 78.0
	)

	for index: int in range(
		weapon_count
	):
		var weapon_id: String = (
			weapon_ids[index]
		)

		var column: int = (
			index % columns
		)

		var row: int = (
			index / columns
		)

		var pickup: Node2D = (
			WeaponPickupScript.new()
			as Node2D
		)

		if not is_instance_valid(
			pickup
		):
			continue

		if not _configure_weapon_pickup(
			pickup,
			weapon_id
		):
			pickup.queue_free()

			continue

		scene.add_child(
			pickup
		)

		pickup.global_position = Vector2(
			start_x
				+ float(column)
				* WEAPON_SPACING_X,
			start_y
				+ float(row)
				* WEAPON_SPACING_Y
		)


func _configure_weapon_pickup(
	pickup: Node,
	weapon_id: String
) -> bool:
	var property_names: Array[String] = [
		"weapon_id",
		"weapon_type",
		"weapon_name",
		"pickup_weapon_id"
	]

	for property_name: String in property_names:
		if not _has_property(
			pickup,
			property_name
		):
			continue

		pickup.set(
			property_name,
			weapon_id
		)

		return true

	var method_names: Array[String] = [
		"setup",
		"configure",
		"set_weapon"
	]

	for method_name: String in method_names:
		if not pickup.has_method(
			method_name
		):
			continue

		if _get_method_argument_count(
			pickup,
			method_name
		) != 1:
			continue

		pickup.call(
			method_name,
			weapon_id
		)

		return true

	return false


func _find_weapon_ids(
	weapon_system: Object
) -> Array[String]:
	var result: Array[String] = []

	for property_data: Dictionary in weapon_system.get_property_list():
		var property_name: String = str(
			property_data.get(
				"name",
				""
			)
		)

		if property_name.is_empty():
			continue

		var value: Variant = weapon_system.get(
			property_name
		)

		if typeof(
			value
		) != TYPE_DICTIONARY:
			continue

		var dictionary: Dictionary = (
			value
		)

		for key_value: Variant in dictionary.keys():
			var weapon_value: Variant = (
				dictionary[
					key_value
				]
			)

			if typeof(
				weapon_value
			) != TYPE_DICTIONARY:
				continue

			var weapon_data: Dictionary = (
				weapon_value
			)

			if not (
				weapon_data.has(
					"damage"
				)
				and weapon_data.has(
					"fire_interval"
				)
			):
				continue

			var weapon_id: String = str(
				key_value
			)

			if not result.has(
				weapon_id
			):
				result.append(
					weapon_id
				)

	return _sort_weapon_ids(
		result
	)


func _sort_weapon_ids(
	source: Array[String]
) -> Array[String]:
	var preferred: Array[String] = [
		"pistol",
		"shotgun",
		"machine_gun",
		"sword",
		"spear",
		"hammer"
	]

	var result: Array[String] = []

	# Các weapon chuẩn luôn có mặt trong Training Room.
	for weapon_id: String in preferred:
		if not result.has(
			weapon_id
		):
			result.append(
				weapon_id
			)

	# Weapon mới trong catalog tự nối tiếp phía sau.
	var remaining: Array[String] = []

	for weapon_id: String in source:
		if result.has(
			weapon_id
		):
			continue

		remaining.append(
			weapon_id
		)

	remaining.sort()

	result.append_array(
		remaining
	)

	return result


func _clear_old_training_and_room_objects() -> void:
	var groups: Array[String] = [
		"enemies",
		"room_props",
		"room_hazards",
		"training_projectiles",
		"training_turrets"
	]

	for group_name: String in groups:
		for node: Node in get_tree().get_nodes_in_group(
			group_name
		):
			if not is_instance_valid(
				node
			):
				continue

			node.queue_free()

	_clear_old_weapon_pickups()


func _clear_old_weapon_pickups() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	_clear_nodes_with_script_path(
		scene,
		"weapon_pickup.gd"
	)


func _clear_nodes_with_script_path(
	node: Node,
	path_fragment: String
) -> void:
	for child: Node in node.get_children():
		_clear_nodes_with_script_path(
			child,
			path_fragment
		)

	var script_value: Variant = node.get_script()

	if (
		typeof(script_value) != TYPE_OBJECT
		or not is_instance_valid(
			script_value
		)
	):
		return

	var script: Script = (
		script_value as Script
	)

	if path_fragment in script.resource_path:
		node.queue_free()


func _disable_old_room_boundary() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	_disable_boundary_recursive(
		scene
	)


func _disable_boundary_recursive(
	node: Node
) -> void:
	for child: Node in node.get_children():
		_disable_boundary_recursive(
			child
		)

	var script_value: Variant = node.get_script()

	if (
		typeof(script_value) != TYPE_OBJECT
		or not is_instance_valid(
			script_value
		)
	):
		return

	var script: Script = (
		script_value as Script
	)

	if not (
		"room_boundary_blocker.gd"
		in script.resource_path
	):
		return

	if node.is_in_group(
		"bullet_blockers"
	):
		node.remove_from_group(
			"bullet_blockers"
		)


func _configure_navigation_for_training() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not _has_property(
		scene,
		"room_navigation"
	):
		return

	var navigation_value: Variant = scene.get(
		"room_navigation"
	)

	if (
		typeof(navigation_value) != TYPE_OBJECT
		or not is_instance_valid(
			navigation_value
		)
	):
		return

	var navigation: Object = (
		navigation_value as Object
	)

	if navigation.has_method(
		"configure"
	):
		navigation.call(
			"configure",
			training_bounds
		)


func _keep_player_inside_training_room() -> void:
	var margin: float = 24.0

	var position_value: Vector2 = (
		player.global_position
	)

	position_value.x = clampf(
		position_value.x,
		training_bounds.position.x
			+ margin,
		training_bounds.end.x
			- margin
	)

	position_value.y = clampf(
		position_value.y,
		training_bounds.position.y
			+ margin,
		training_bounds.end.y
			- margin
	)

	player.global_position = (
		position_value
	)


func _build_ui() -> void:
	var top_panel: PanelContainer = (
		PanelContainer.new()
	)

	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5

	top_panel.offset_left = -310.0
	top_panel.offset_right = 310.0

	top_panel.offset_top = 12.0
	top_panel.offset_bottom = 106.0

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
		"LOADING TRAINING ROOM..."
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

	turret_button = Button.new()

	turret_button.text = "TURRET"

	turret_button.pressed.connect(
		_toggle_turret
	)

	buttons.add_child(
		turret_button
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


func _toggle_turret() -> void:
	if not is_instance_valid(
		turret
	):
		return

	var enabled_value: bool = true

	if turret.has_method(
		"is_enabled"
	):
		enabled_value = bool(
			turret.call(
				"is_enabled"
			)
		)

	if turret.has_method(
		"set_enabled"
	):
		turret.call(
			"set_enabled",
			not enabled_value
		)

	_update_turret_button()


func _update_turret_button() -> void:
	if not is_instance_valid(
		turret_button
	):
		return

	if not is_instance_valid(
		turret
	):
		turret_button.text = "TURRET"

		return

	var enabled_value: bool = true

	if turret.has_method(
		"is_enabled"
	):
		enabled_value = bool(
			turret.call(
				"is_enabled"
			)
		)

	if enabled_value:
		turret_button.text = "TURRET: ON"

	else:
		turret_button.text = "TURRET: OFF"


func _return_to_menu() -> void:
	get_tree().paused = false

	get_tree().reload_current_scene()


func _get_weapon_system(
	target_player: Node2D
) -> Object:
	if not _has_property(
		target_player,
		"weapon_system"
	):
		return null

	var value: Variant = target_player.get(
		"weapon_system"
	)

	if typeof(
		value
	) != TYPE_OBJECT:
		return null

	if not is_instance_valid(
		value
	):
		return null

	return value as Object


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


func _get_method_argument_count(
	target: Object,
	method_name: String
) -> int:
	for method_data: Dictionary in target.get_method_list():
		if str(
			method_data.get(
				"name",
				""
			)
		) != method_name:
			continue

		var args_value: Variant = method_data.get(
			"args",
			[]
		)

		if typeof(
			args_value
		) != TYPE_ARRAY:
			return -1

		var args: Array = args_value

		return args.size()

	return -1


func _has_property(
	target: Object,
	property_name: String
) -> bool:
	for property_data: Dictionary in target.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false