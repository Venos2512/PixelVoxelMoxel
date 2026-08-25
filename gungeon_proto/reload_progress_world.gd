extends Node2D

const BAR_WIDTH: float = 46.0
const BAR_HEIGHT: float = 6.0

var player: Node2D = null

var reload_progress: float = 0.0
var reload_visible: bool = false

var last_progress: float = -1.0
var last_visible: bool = false


func _ready() -> void:
	z_index = 120

	# Node này nằm trong dungeon root,
	# nên dùng global_position để bám player.
	top_level = true

	queue_redraw()


func _process(
	_delta: float
) -> void:
	if not is_instance_valid(
		player
	):
		player = _get_player()

	if not is_instance_valid(
		player
	):
		reload_visible = false

		_update_redraw()

		return

	global_position = (
		player.global_position
		+ Vector2(
			0.0,
			-48.0
		)
	)

	var weapon_system: Object = (
		_get_weapon_system(
			player
		)
	)

	if not is_instance_valid(
		weapon_system
	):
		reload_visible = false

		_update_redraw()

		return

	var state: Dictionary = (
		_get_reload_state(
			weapon_system
		)
	)

	reload_visible = bool(
		state.get(
			"visible",
			false
		)
	)

	reload_progress = clampf(
		float(
			state.get(
				"progress",
				0.0
			)
		),
		0.0,
		1.0
	)

	_update_redraw()


func _update_redraw() -> void:
	if (
		reload_visible != last_visible
		or absf(
			reload_progress
			- last_progress
		) > 0.002
	):
		last_visible = reload_visible
		last_progress = reload_progress

		queue_redraw()


func _get_reload_state(
	weapon_system: Object
) -> Dictionary:
	# ------------------------------------------------
	# 1. Nếu weapon system đã có getter progress.
	# ------------------------------------------------

	var direct_progress: float = (
		_try_get_direct_progress(
			weapon_system
		)
	)

	var direct_reloading: int = (
		_try_get_reload_bool(
			weapon_system
		)
	)

	if direct_progress >= 0.0:
		var active: bool = (
			direct_progress < 0.999
		)

		if direct_reloading >= 0:
			active = bool(
				direct_reloading
			)

		return {
			"visible": active,
			"progress": direct_progress
		}

	# ------------------------------------------------
	# 2. Đọc timer còn lại.
	# ------------------------------------------------

	var remaining: float = (
		_read_first_float_property(
			weapon_system,
			[
				"reload_timer",
				"reload_time_left",
				"reload_remaining",
				"reload_remaining_time",
				"reload_timer_left"
			]
		)
	)

	var total: float = (
		_read_first_float_property(
			weapon_system,
			[
				"reload_duration",
				"reload_total_time",
				"current_reload_time"
			]
		)
	)

	# ------------------------------------------------
	# 3. Nếu total không nằm trong state,
	# lấy reload_time từ weapon config hiện tại.
	# ------------------------------------------------

	if total <= 0.0:
		total = _get_current_weapon_reload_time(
			weapon_system
		)

	var reloading: bool = false

	if direct_reloading >= 0:
		reloading = bool(
			direct_reloading
		)

	else:
		reloading = (
			remaining > 0.0
			and total > 0.0
		)

	if not reloading:
		return {
			"visible": false,
			"progress": 0.0
		}

	if (
		remaining >= 0.0
		and total > 0.0
	):
		return {
			"visible": true,

			"progress": clampf(
				1.0
				- remaining
				/ total,
				0.0,
				1.0
			)
		}

	return {
		"visible": true,
		"progress": 0.0
	}


func _try_get_direct_progress(
	weapon_system: Object
) -> float:
	var property_names: Array[String] = [
		"reload_progress",
		"current_reload_progress"
	]

	for property_name: String in property_names:
		if not _has_property(
			weapon_system,
			property_name
		):
			continue

		var value: Variant = weapon_system.get(
			property_name
		)

		if (
			typeof(value) == TYPE_FLOAT
			or typeof(value) == TYPE_INT
		):
			return clampf(
				float(value),
				0.0,
				1.0
			)

	var method_names: Array[String] = [
		"get_reload_progress",
		"get_current_reload_progress"
	]

	for method_name: String in method_names:
		if not weapon_system.has_method(
			method_name
		):
			continue

		var result: Variant = weapon_system.call(
			method_name
		)

		if (
			typeof(result) == TYPE_FLOAT
			or typeof(result) == TYPE_INT
		):
			return clampf(
				float(result),
				0.0,
				1.0
			)

	return -1.0


func _try_get_reload_bool(
	weapon_system: Object
) -> int:
	var property_names: Array[String] = [
		"is_reloading",
		"reloading",
		"reload_active"
	]

	for property_name: String in property_names:
		if not _has_property(
			weapon_system,
			property_name
		):
			continue

		var value: Variant = weapon_system.get(
			property_name
		)

		if typeof(value) == TYPE_BOOL:
			return int(
				bool(value)
			)

	var method_names: Array[String] = [
		"is_reloading",
		"get_is_reloading"
	]

	for method_name: String in method_names:
		if not weapon_system.has_method(
			method_name
		):
			continue

		var result: Variant = weapon_system.call(
			method_name
		)

		if typeof(result) == TYPE_BOOL:
			return int(
				bool(result)
			)

	return -1


func _get_current_weapon_reload_time(
	weapon_system: Object
) -> float:
	if not weapon_system.has_method(
		"get_current_weapon"
	):
		return -1.0

	var weapon_value: Variant = weapon_system.call(
		"get_current_weapon"
	)

	if typeof(
		weapon_value
	) != TYPE_DICTIONARY:
		return -1.0

	var weapon: Dictionary = weapon_value

	if not weapon.has(
		"reload_time"
	):
		return -1.0

	var value: Variant = weapon[
		"reload_time"
	]

	if (
		typeof(value) != TYPE_FLOAT
		and typeof(value) != TYPE_INT
	):
		return -1.0

	return float(
		value
	)


func _read_first_float_property(
	target: Object,
	property_names: Array
) -> float:
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
			typeof(value) == TYPE_FLOAT
			or typeof(value) == TYPE_INT
		):
			return float(
				value
			)

	return -1.0


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


func _draw() -> void:
	if not reload_visible:
		return

	var background_rect: Rect2 = Rect2(
		Vector2(
			-BAR_WIDTH * 0.5,
			0.0
		),
		Vector2(
			BAR_WIDTH,
			BAR_HEIGHT
		)
	)

	draw_rect(
		background_rect,
		Color(
			0.03,
			0.03,
			0.04,
			0.90
		),
		true
	)

	draw_rect(
		background_rect,
		Color(
			0.15,
			0.14,
			0.16,
			1.0
		),
		false,
		1.0
	)

	var inner_width: float = (
		(BAR_WIDTH - 4.0)
		* reload_progress
	)

	if inner_width <= 0.0:
		return

	draw_rect(
		Rect2(
			Vector2(
				-BAR_WIDTH * 0.5 + 2.0,
				2.0
			),
			Vector2(
				inner_width,
				BAR_HEIGHT - 4.0
			)
		),
		Color(
			0.95,
			0.74,
			0.26,
			1.0
		),
		true
	)