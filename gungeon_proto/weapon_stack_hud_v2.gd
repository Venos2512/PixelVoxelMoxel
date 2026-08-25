extends CanvasLayer

const GameHudIconScript = preload(
	"res://gungeon_proto/game_hud_icon.gd"
)

const ICON_SIZE: float = 58.0
const AMMO_HEIGHT: float = 18.0
const SLOT_HEIGHT: float = 82.0

const RIGHT_MARGIN: float = 18.0
const BOTTOM_MARGIN: float = 16.0

var weapon_slots: Array[Control] = []

var last_signature: String = ""
var refresh_timer: float = 0.0


func _ready() -> void:
	layer = 90

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_refresh_hud()


func _process(
	delta: float
) -> void:
	refresh_timer -= delta

	if refresh_timer > 0.0:
		return

	refresh_timer = 0.08

	_refresh_hud()


func _refresh_hud() -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	_hide_old_weapon_label(
		player
	)

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
		return

	var current_weapon_id: String = (
		_get_current_weapon_id(
			weapon_system,
			weapon_order
		)
	)

	var ammo_signature_parts: Array[String] = []

	for weapon_id: String in weapon_order:
		ammo_signature_parts.append(
			weapon_id
			+ ":"
			+ _get_ammo_text(
				player,
				weapon_system,
				weapon_id,
				weapon_id
					== current_weapon_id
			)
		)

	var signature: String = (
		"|".join(
			ammo_signature_parts
		)
		+ "#"
		+ current_weapon_id
	)

	if signature == last_signature:
		return

	last_signature = signature

	_rebuild_slots(
		weapon_system,
		weapon_order,
		current_weapon_id
	)


func _rebuild_slots(
	weapon_system: Object,
	weapon_order: Array[String],
	current_weapon_id: String
) -> void:
	for slot: Control in weapon_slots:
		if is_instance_valid(
			slot
		):
			slot.queue_free()

	weapon_slots.clear()

	for index: int in range(
		weapon_order.size()
	):
		var weapon_id: String = (
			weapon_order[index]
		)

		var slot: Control = Control.new()

		slot.anchor_left = 1.0
		slot.anchor_top = 1.0
		slot.anchor_right = 1.0
		slot.anchor_bottom = 1.0

		slot.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		var vertical_offset: float = (
			float(index)
			* SLOT_HEIGHT
		)

		slot.offset_left = (
			-RIGHT_MARGIN
			- ICON_SIZE
		)

		slot.offset_right = (
			-RIGHT_MARGIN
		)

		slot.offset_top = (
			-BOTTOM_MARGIN
			- SLOT_HEIGHT
			- vertical_offset
		)

		slot.offset_bottom = (
			-BOTTOM_MARGIN
			- vertical_offset
		)

		add_child(
			slot
		)

		var icon: Control = (
			GameHudIconScript.new()
		)

		icon.position = Vector2.ZERO

		icon.size = Vector2(
			ICON_SIZE,
			ICON_SIZE
		)

		icon.custom_minimum_size = Vector2(
			ICON_SIZE,
			ICON_SIZE
		)

		icon.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		icon.call(
			"configure",
			"weapon",
			weapon_id,
			"COMMON"
		)

		if weapon_id == current_weapon_id:
			icon.modulate = Color(
				1.0,
				1.0,
				1.0,
				1.0
			)

		else:
			icon.modulate = Color(
				0.64,
				0.64,
				0.68,
				0.52
			)

		slot.add_child(
			icon
		)

		var ammo_label: Label = Label.new()

		ammo_label.position = Vector2(
			-8.0,
			ICON_SIZE + 1.0
		)

		ammo_label.size = Vector2(
			ICON_SIZE + 16.0,
			AMMO_HEIGHT
		)

		ammo_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		ammo_label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		ammo_label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		ammo_label.add_theme_font_size_override(
			"font_size",
			12
		)

		if weapon_id == current_weapon_id:
			ammo_label.add_theme_color_override(
				"font_color",
				Color(
					0.96,
					0.94,
					0.85,
					1.0
				)
			)

		else:
			ammo_label.add_theme_color_override(
				"font_color",
				Color(
					0.64,
					0.64,
					0.68,
					0.72
				)
			)

		var player: Node2D = _get_player()

		ammo_label.text = (
			_get_ammo_text(
				player,
				weapon_system,
				weapon_id,
				weapon_id
					== current_weapon_id
			)
		)

		slot.add_child(
			ammo_label
		)

		weapon_slots.append(
			slot
		)


func _get_ammo_text(
	player: Node2D,
	weapon_system: Object,
	weapon_id: String,
	is_current: bool
) -> String:
	if weapon_id in [
		"sword",
		"spear",
		"hammer"
	]:
		return "∞"

	var magazine: int = -1
	var reserve: int = -1

	# 1. Nested state:
	# ammo_state["pistol"] = {
	#     "current_ammo": 5,
	#     "reserve_ammo": 30
	# }
	var state: Dictionary = (
		_find_weapon_ammo_state(
			weapon_system,
			weapon_id
		)
	)

	if not state.is_empty():
		magazine = _read_first_int(
			state,
			[
				"ammo_in_mag",
				"current_ammo",
				"current_mag",
				"mag_ammo",
				"magazine_ammo",
				"loaded_ammo",
				"clip_ammo",
				"clip",
				"ammo"
			]
		)

		reserve = _read_first_int(
			state,
			[
				"reserve_ammo",
				"ammo_reserve",
				"reserve",
				"stored_ammo",
				"remaining_ammo",
				"extra_ammo"
			]
		)

	# 2. Dictionary trực tiếp:
	#
	# current_ammo = {
	#     "pistol": 5,
	#     "shotgun": 2
	# }
	if magazine < 0:
		magazine = _read_weapon_dictionary_value(
			weapon_system,
			weapon_id,
			[
				"ammo_in_mag",
				"current_ammo",
				"current_mag",
				"mag_ammo",
				"magazine_ammo",
				"loaded_ammo",
				"clip_ammo",
				"weapon_ammo",
				"ammo"
			]
		)

	if reserve < 0:
		reserve = _read_weapon_dictionary_value(
			weapon_system,
			weapon_id,
			[
				"reserve_ammo",
				"ammo_reserve",
				"reserve",
				"stored_ammo",
				"remaining_ammo",
				"extra_ammo"
			]
		)

	# 3. Một số project giữ ammo ở player thay vì
	# weapon_system.
	if is_instance_valid(
		player
	):
		if magazine < 0:
			magazine = _read_weapon_dictionary_value(
				player,
				weapon_id,
				[
					"ammo_in_mag",
					"current_ammo",
					"current_mag",
					"mag_ammo",
					"magazine_ammo",
					"loaded_ammo",
					"clip_ammo",
					"weapon_ammo",
					"ammo"
				]
			)

		if reserve < 0:
			reserve = _read_weapon_dictionary_value(
				player,
				weapon_id,
				[
					"reserve_ammo",
					"ammo_reserve",
					"reserve",
					"stored_ammo",
					"remaining_ammo",
					"extra_ammo"
				]
			)

	# 4. Current weapon thường dùng scalar:
	#
	# current_ammo = 5
	# reserve_ammo = 30
	if is_current:
		if magazine < 0:
			magazine = _read_object_int(
				weapon_system,
				[
					"ammo_in_mag",
					"current_ammo",
					"current_mag",
					"mag_ammo",
					"magazine_ammo",
					"loaded_ammo",
					"clip_ammo",
					"clip"
				]
			)

		if reserve < 0:
			reserve = _read_object_int(
				weapon_system,
				[
					"reserve_ammo",
					"ammo_reserve",
					"reserve",
					"stored_ammo",
					"remaining_ammo",
					"extra_ammo"
				]
			)

		if is_instance_valid(
			player
		):
			if magazine < 0:
				magazine = _read_object_int(
					player,
					[
						"ammo_in_mag",
						"current_ammo",
						"current_mag",
						"mag_ammo",
						"magazine_ammo",
						"loaded_ammo",
						"clip_ammo"
					]
				)

			if reserve < 0:
				reserve = _read_object_int(
					player,
					[
						"reserve_ammo",
						"ammo_reserve",
						"reserve",
						"stored_ammo",
						"remaining_ammo"
					]
				)

	# 5. Thử getter của weapon system.
	if is_current:
		if magazine < 0:
			magazine = _call_ammo_getter(
				weapon_system,
				weapon_id,
				[
					"get_current_ammo",
					"get_ammo_in_mag",
					"get_mag_ammo",
					"get_loaded_ammo",
					"get_clip_ammo"
				]
			)

		if reserve < 0:
			reserve = _call_ammo_getter(
				weapon_system,
				weapon_id,
				[
					"get_reserve_ammo",
					"get_ammo_reserve",
					"get_remaining_ammo"
				]
			)

	# 6. get_current_weapon() đôi khi trả luôn runtime state.
	if is_current and weapon_system.has_method(
		"get_current_weapon"
	):
		var current_value: Variant = (
			weapon_system.call(
				"get_current_weapon"
			)
		)

		if typeof(
			current_value
		) == TYPE_DICTIONARY:
			var current_weapon: Dictionary = (
				current_value
			)

			if magazine < 0:
				magazine = _read_first_int(
					current_weapon,
					[
						"ammo_in_mag",
						"current_ammo",
						"current_mag",
						"mag_ammo",
						"magazine_ammo",
						"loaded_ammo",
						"clip_ammo",
						"ammo"
					]
				)

			if reserve < 0:
				reserve = _read_first_int(
					current_weapon,
					[
						"reserve_ammo",
						"ammo_reserve",
						"reserve",
						"stored_ammo",
						"remaining_ammo"
					]
				)

	if magazine >= 0 and reserve >= 0:
		return (
			str(magazine)
			+ "/"
			+ str(reserve)
		)

	if magazine >= 0:
		return (
			str(magazine)
			+ "/—"
		)

	if reserve >= 0:
		return (
			"—/"
			+ str(reserve)
		)

	# Không dùng mag_size làm ammo nữa.
	# Nếu HUD không tìm thấy runtime ammo thì hiển thị —
	# để tránh "-/5" gây hiểu nhầm.
	return "—"


func _read_weapon_dictionary_value(
	target: Object,
	weapon_id: String,
	property_names: Array
) -> int:
	if not is_instance_valid(
		target
	):
		return -1

	for property_name_value: Variant in property_names:
		var property_name: String = str(
			property_name_value
		)

		if not _has_property(
			target,
			property_name
		):
			continue

		var property_value: Variant = target.get(
			property_name
		)

		if typeof(
			property_value
		) != TYPE_DICTIONARY:
			continue

		var dictionary: Dictionary = (
			property_value
		)

		var candidate_keys: Array[String] = [
			weapon_id,
			weapon_id.to_lower(),
			weapon_id.to_upper()
		]

		for candidate_key: String in candidate_keys:
			if not dictionary.has(
				candidate_key
			):
				continue

			var ammo_value: Variant = dictionary[
				candidate_key
			]

			if (
				typeof(ammo_value) == TYPE_INT
				or typeof(ammo_value) == TYPE_FLOAT
			):
				return int(
					ammo_value
				)

	return -1


func _call_ammo_getter(
	target: Object,
	weapon_id: String,
	method_names: Array
) -> int:
	if not is_instance_valid(
		target
	):
		return -1

	var method_list: Array[Dictionary] = (
		target.get_method_list()
	)

	for method_name_value: Variant in method_names:
		var method_name: String = str(
			method_name_value
		)

		if not target.has_method(
			method_name
		):
			continue

		var argument_count: int = -1

		for method_data: Dictionary in method_list:
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
			) == TYPE_ARRAY:
				var args_array: Array = args_value

				argument_count = args_array.size()

			break

		var result: Variant = null

		if argument_count == 0:
			result = target.call(
				method_name
			)

		elif argument_count == 1:
			result = target.call(
				method_name,
				weapon_id
			)

		else:
			continue

		if (
			typeof(result) == TYPE_INT
			or typeof(result) == TYPE_FLOAT
		):
			return int(
				result
			)

	return -1


func _find_weapon_ammo_state(
	weapon_system: Object,
	weapon_id: String
) -> Dictionary:
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

		if typeof(value) != TYPE_DICTIONARY:
			continue

		var dictionary: Dictionary = value

		if not dictionary.has(
			weapon_id
		):
			continue

		var weapon_value: Variant = dictionary[
			weapon_id
		]

		if typeof(
			weapon_value
		) != TYPE_DICTIONARY:
			continue

		var state: Dictionary = weapon_value

		if (
			_dictionary_has_any_key(
				state,
				[
					"ammo_in_mag",
					"current_ammo",
					"mag_ammo",
					"magazine_ammo",
					"loaded_ammo",
					"reserve_ammo",
					"ammo_reserve",
					"reserve",
					"stored_ammo"
				]
			)
		):
			return state

	return {}


func _find_weapon_config(
	weapon_system: Object,
	weapon_id: String
) -> Dictionary:
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

		if typeof(value) != TYPE_DICTIONARY:
			continue

		var dictionary: Dictionary = value

		if not dictionary.has(
			weapon_id
		):
			continue

		var weapon_value: Variant = dictionary[
			weapon_id
		]

		if typeof(
			weapon_value
		) != TYPE_DICTIONARY:
			continue

		var weapon: Dictionary = weapon_value

		if (
			weapon.has("mag_size")
			or weapon.has("fire_interval")
			or weapon.has("damage")
		):
			return weapon

	return {}


func _read_first_int(
	dictionary: Dictionary,
	keys: Array
) -> int:
	for key_value: Variant in keys:
		var key: String = str(
			key_value
		)

		if not dictionary.has(
			key
		):
			continue

		var value: Variant = dictionary[
			key
		]

		if (
			typeof(value) == TYPE_INT
			or typeof(value) == TYPE_FLOAT
		):
			return int(
				value
			)

	return -1


func _read_object_int(
	target: Object,
	property_names: Array
) -> int:
	for property_name_value: Variant in property_names:
		var property_name: String = str(
			property_name_value
		)

		if not _has_property(
			target,
			property_name
		):
			continue

		var value: Variant = target.get(
			property_name
		)

		if (
			typeof(value) == TYPE_INT
			or typeof(value) == TYPE_FLOAT
		):
			return int(
				value
			)

	return -1


func _dictionary_has_any_key(
	dictionary: Dictionary,
	keys: Array
) -> bool:
	for key_value: Variant in keys:
		if dictionary.has(
			str(key_value)
		):
			return true

	return false


func _hide_old_weapon_label(
	player: Node2D
) -> void:
	var possible_names: Array[String] = [
		"weapon_label",
		"weapon_list_label"
	]

	for property_name: String in possible_names:
		if not _has_property(
			player,
			property_name
		):
			continue

		var value: Variant = player.get(
			property_name
		)

		if (
			typeof(value) != TYPE_OBJECT
			or not is_instance_valid(value)
			or not value is CanvasItem
		):
			continue

		var canvas_item: CanvasItem = (
			value as CanvasItem
		)

		# Ẩn text tên / slot vũ khí cũ.
		canvas_item.visible = false

		# Quan trọng:
		# HUD cũ có background riêng nên chỉ ẩn Label
		# vẫn để lại một bảng tối che minimap.
		_hide_old_weapon_container(
			canvas_item
		)


func _hide_old_weapon_container(
	item: CanvasItem
) -> void:
	var current: Node = item.get_parent()

	# Chỉ dò vài cấp cha gần Label.
	# Không đi tới CanvasLayer/root HUD để tránh
	# vô tình tắt GOLD, minimap hoặc HUD khác.
	for depth: int in range(5):
		if not is_instance_valid(
			current
		):
			return

		if current is CanvasLayer:
			return

		if (
			current is Panel
			or current is PanelContainer
			or current is ColorRect
		):
			var background: CanvasItem = (
				current as CanvasItem
			)

			background.visible = false

			return

		current = current.get_parent()


func _get_weapon_order(
	player: Node2D,
	weapon_system: Object
) -> Array[String]:
	var result: Array[String] = []

	if _has_property(
		weapon_system,
		"weapon_order"
	):
		_append_weapon_order(
			result,
			weapon_system.get(
				"weapon_order"
			)
		)

	if (
		result.is_empty()
		and _has_property(
			player,
			"weapon_order"
		)
	):
		_append_weapon_order(
			result,
			player.get(
				"weapon_order"
			)
		)

	return _remove_duplicate_weapon_ids(
		result
	)


func _append_weapon_order(
	result: Array[String],
	value: Variant
) -> void:
	if typeof(value) != TYPE_ARRAY:
		return

	var array_value: Array = value

	for weapon_value: Variant in array_value:
		var weapon_id: String = (
			_normalize_weapon_id(
				str(weapon_value)
			)
		)

		if weapon_id.is_empty():
			continue

		result.append(
			weapon_id
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
		var value: String = str(
			weapon_system.get(
				"current_weapon_id"
			)
		)

		if not value.is_empty():
			return _normalize_weapon_id(
				value
			)

	if _has_property(
		weapon_system,
		"current_weapon_index"
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
		var value: Variant = weapon_system.call(
			"get_current_weapon"
		)

		if typeof(value) == TYPE_DICTIONARY:
			var weapon: Dictionary = value

			return _normalize_weapon_id(
				str(
					weapon.get(
						"name",
						"pistol"
					)
				)
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

	if "spear" in normalized:
		return "spear"

	if (
		"hammer" in normalized
		or "maul" in normalized
	):
		return "hammer"

	if "pistol" in normalized:
		return "pistol"

	return normalized


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

	if typeof(value) != TYPE_OBJECT:
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
	for property_data: Dictionary in target.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false