extends CanvasLayer

const GameHudIconScript = preload(
	"res://gungeon_proto/game_hud_icon.gd"
)

const ICON_SIZE: float = 62.0
const ICON_SPACING: float = 7.0
const RIGHT_MARGIN: float = 18.0
const BOTTOM_MARGIN: float = 18.0

const MINIMAP_RIGHT_MARGIN: float = 18.0
const MINIMAP_TOP_MARGIN: float = 18.0

var weapon_icons: Array[Control] = []

var last_weapon_signature: String = ""
var last_current_weapon: String = ""

var refresh_timer: float = 0.0
var minimap_refresh_timer: float = 0.0


func _ready() -> void:
	layer = 90

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_refresh_weapon_stack()


func _process(
	delta: float
) -> void:
	refresh_timer -= delta
	minimap_refresh_timer -= delta

	if refresh_timer <= 0.0:
		refresh_timer = 0.12

		_refresh_weapon_stack()

	if minimap_refresh_timer <= 0.0:
		minimap_refresh_timer = 0.35

		_move_minimap_to_top_right()


func _refresh_weapon_stack() -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	var weapon_system: Object = (
		_get_weapon_system(
			player
		)
	)

	if not is_instance_valid(
		weapon_system
	):
		return

	var weapon_order: Array[String] = (
		_get_weapon_order(
			player,
			weapon_system
		)
	)

	if weapon_order.is_empty():
		var fallback_weapon: String = (
			_get_current_weapon_id(
				weapon_system,
				weapon_order
			)
		)

		if not fallback_weapon.is_empty():
			weapon_order.append(
				fallback_weapon
			)

	var current_weapon: String = (
		_get_current_weapon_id(
			weapon_system,
			weapon_order
		)
	)

	var signature: String = (
		"|".join(
			weapon_order
		)
	)

	if (
		signature == last_weapon_signature
		and current_weapon == last_current_weapon
	):
		return

	last_weapon_signature = signature
	last_current_weapon = current_weapon

	_rebuild_weapon_icons(
		weapon_order,
		current_weapon
	)


func _rebuild_weapon_icons(
	weapon_order: Array[String],
	current_weapon: String
) -> void:
	for icon: Control in weapon_icons:
		if is_instance_valid(
			icon
		):
			icon.queue_free()

	weapon_icons.clear()

	for index: int in range(
		weapon_order.size()
	):
		var weapon_id: String = (
			weapon_order[index]
		)

		var icon: Control = (
			GameHudIconScript.new()
		)

		icon.anchor_left = 1.0
		icon.anchor_top = 1.0
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0

		var vertical_offset: float = (
			float(index)
			* (
				ICON_SIZE
				+ ICON_SPACING
			)
		)

		icon.offset_left = (
			-RIGHT_MARGIN
			- ICON_SIZE
		)

		icon.offset_right = (
			-RIGHT_MARGIN
		)

		icon.offset_top = (
			-BOTTOM_MARGIN
			- ICON_SIZE
			- vertical_offset
		)

		icon.offset_bottom = (
			-BOTTOM_MARGIN
			- vertical_offset
		)

		icon.custom_minimum_size = Vector2(
			ICON_SIZE,
			ICON_SIZE
		)

		icon.size = Vector2(
			ICON_SIZE,
			ICON_SIZE
		)

		icon.tooltip_text = (
			_format_weapon_name(
				weapon_id
			)
		)

		icon.call(
			"configure",
			"weapon",
			weapon_id,
			"COMMON"
		)

		if weapon_id == current_weapon:
			icon.modulate = Color(
				1.0,
				1.0,
				1.0,
				1.0
			)

		else:
			icon.modulate = Color(
				0.72,
				0.72,
				0.72,
				0.58
			)

		add_child(
			icon
		)

		weapon_icons.append(
			icon
		)


func _get_weapon_order(
	player: Node2D,
	weapon_system: Object
) -> Array[String]:
	var result: Array[String] = []

	if _has_property(
		weapon_system,
		"weapon_order"
	):
		var order_value: Variant = (
			weapon_system.get(
				"weapon_order"
			)
		)

		_append_weapon_order(
			result,
			order_value
		)

	if result.is_empty():
		if _has_property(
			player,
			"weapon_order"
		):
			var player_order_value: Variant = (
				player.get(
					"weapon_order"
				)
			)

			_append_weapon_order(
				result,
				player_order_value
			)

	return _remove_duplicate_weapon_ids(
		result
	)


func _append_weapon_order(
	result: Array[String],
	order_value: Variant
) -> void:
	if typeof(
		order_value
	) != TYPE_ARRAY:
		return

	var order_array: Array = (
		order_value
	)

	for weapon_value: Variant in order_array:
		var weapon_id: String = str(
			weapon_value
		)

		if weapon_id.is_empty():
			continue

		result.append(
			_normalize_weapon_id(
				weapon_id
			)
		)


func _remove_duplicate_weapon_ids(
	source: Array[String]
) -> Array[String]:
	var result: Array[String] = []

	for weapon_id: String in source:
		if result.has(
			weapon_id
		):
			continue

		result.append(
			weapon_id
		)

	return result


func _get_current_weapon_id(
	weapon_system: Object,
	weapon_order: Array[String]
) -> String:
	if _has_property(
		weapon_system,
		"current_weapon_id"
	):
		var id_value: String = str(
			weapon_system.get(
				"current_weapon_id"
			)
		)

		if not id_value.is_empty():
			return _normalize_weapon_id(
				id_value
			)

	if (
		_has_property(
			weapon_system,
			"current_weapon_index"
		)
		and not weapon_order.is_empty()
	):
		var index: int = int(
			weapon_system.get(
				"current_weapon_index"
			)
		)

		if (
			index >= 0
			and index < weapon_order.size()
		):
			return weapon_order[
				index
			]

	if weapon_system.has_method(
		"get_current_weapon"
	):
		var weapon_value: Variant = (
			weapon_system.call(
				"get_current_weapon"
			)
		)

		if typeof(
			weapon_value
		) == TYPE_DICTIONARY:
			var weapon: Dictionary = (
				weapon_value
			)

			var weapon_name: String = str(
				weapon.get(
					"name",
					"pistol"
				)
			)

			return _normalize_weapon_id(
				weapon_name
			)

	if not weapon_order.is_empty():
		return weapon_order[
			0
		]

	return "pistol"


func _normalize_weapon_id(
	value: String
) -> String:
	var normalized: String = (
		value
		.strip_edges()
		.to_lower()
		.replace(
			" ",
			"_"
		)
		.replace(
			"-",
			"_"
		)
	)

	if (
		"machine" in normalized
		or normalized == "mg"
		or "smg" in normalized
	):
		return "machine_gun"

	if "shotgun" in normalized:
		return "shotgun"

	if (
		"sword" in normalized
		or "katana" in normalized
	):
		return "sword"

	if "pistol" in normalized:
		return "pistol"

	return normalized


func _format_weapon_name(
	weapon_id: String
) -> String:
	match weapon_id:
		"pistol":
			return "PISTOL"

		"shotgun":
			return "SHOTGUN"

		"machine_gun":
			return "MACHINE GUN"

		"sword":
			return "SWORD"

		_:
			return (
				weapon_id
				.replace(
					"_",
					" "
				)
				.to_upper()
			)


func _get_weapon_system(
	player: Node2D
) -> Object:
	if not _has_property(
		player,
		"weapon_system"
	):
		return null

	var value: Variant = player.get(
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


func _has_property(
	target: Object,
	property_name: String
) -> bool:
	for property_value: Dictionary in target.get_property_list():
		if str(
			property_value.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false


func _move_minimap_to_top_right() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var minimap_node: Node = (
		_find_minimap_node(
			scene
		)
	)

	if not is_instance_valid(
		minimap_node
	):
		return

	var minimap_control: Control = (
		_find_minimap_visual_control(
			minimap_node
		)
	)

	if not is_instance_valid(
		minimap_control
	):
		return

	_place_control_top_right(
		minimap_control
	)


func _find_minimap_node(
	root: Node
) -> Node:
	if _node_is_minimap(
		root
	):
		return root

	for child: Node in root.get_children():
		var result: Node = (
			_find_minimap_node(
				child
			)
		)

		if is_instance_valid(
			result
		):
			return result

	return null


func _node_is_minimap(
	node: Node
) -> bool:
	var lower_name: String = (
		node.name
		.to_lower()
	)

	if "minimap" in lower_name:
		return true

	var script_value: Variant = (
		node.get_script()
	)

	if (
		typeof(script_value)
		== TYPE_OBJECT
		and is_instance_valid(
			script_value
		)
	):
		var script: Script = (
			script_value as Script
		)

		var path: String = (
			script.resource_path
			.to_lower()
		)

		if (
			"dungeon_minimap_m5.gd"
			in path
		):
			return true

		if (
			"dungeon_minimap.gd"
			in path
		):
			return true

	return false


func _find_minimap_visual_control(
	minimap_node: Node
) -> Control:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)

	var candidates: Array[Control] = []

	_collect_control_candidates(
		minimap_node,
		candidates
	)

	var best_control: Control = null
	var best_area: float = -1.0

	for control: Control in candidates:
		if not is_instance_valid(
			control
		):
			continue

		var width: float = maxf(
			control.size.x,
			control.custom_minimum_size.x
		)

		var height: float = maxf(
			control.size.y,
			control.custom_minimum_size.y
		)

		if (
			width < 40.0
			or height < 40.0
		):
			continue

		# Bỏ qua Control fullscreen.
		if (
			width > viewport_size.x * 0.72
			and height > viewport_size.y * 0.72
		):
			continue

		var area: float = (
			width * height
		)

		if area > best_area:
			best_area = area
			best_control = control

	return best_control


func _collect_control_candidates(
	node: Node,
	result: Array[Control]
) -> void:
	if node is Control:
		result.append(
			node as Control
		)

	for child: Node in node.get_children():
		_collect_control_candidates(
			child,
			result
		)


func _place_control_top_right(
	control: Control
) -> void:
	var width: float = maxf(
		control.size.x,
		control.custom_minimum_size.x
	)

	var height: float = maxf(
		control.size.y,
		control.custom_minimum_size.y
	)

	if width <= 1.0:
		width = 180.0

	if height <= 1.0:
		height = 140.0

	control.anchor_left = 1.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0

	control.offset_left = (
		-MINIMAP_RIGHT_MARGIN
		- width
	)

	control.offset_right = (
		-MINIMAP_RIGHT_MARGIN
	)

	control.offset_top = (
		MINIMAP_TOP_MARGIN
	)

	control.offset_bottom = (
		MINIMAP_TOP_MARGIN
		+ height
	)