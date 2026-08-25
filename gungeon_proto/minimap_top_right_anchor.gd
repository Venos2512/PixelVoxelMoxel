extends Node

const RIGHT_MARGIN: float = 18.0
const TOP_MARGIN: float = 18.0

var refresh_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_move_minimap()


func _process(
	delta: float
) -> void:
	refresh_timer -= delta

	if refresh_timer > 0.0:
		return

	refresh_timer = 0.25

	_move_minimap()


func _move_minimap() -> void:
	var scene: Node = get_tree().current_scene

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

	_place_top_right(
		minimap_control
	)


func _find_minimap_node(
	root: Node
) -> Node:
	if _is_minimap_node(
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


func _is_minimap_node(
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
		typeof(script_value) == TYPE_OBJECT
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

		if "dungeon_minimap" in path:
			return true

	return false


func _find_minimap_visual_control(
	minimap_node: Node
) -> Control:
	var candidates: Array[Control] = []

	_collect_controls(
		minimap_node,
		candidates
	)

	if minimap_node is Control:
		candidates.push_front(
			minimap_node as Control
		)

	var viewport_size: Vector2 = (
		get_viewport()
		.get_visible_rect()
		.size
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

		# Không chọn fullscreen root/control.
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


func _collect_controls(
	node: Node,
	result: Array[Control]
) -> void:
	if node is Control:
		result.append(
			node as Control
		)

	for child: Node in node.get_children():
		_collect_controls(
			child,
			result
		)


func _place_top_right(
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
		-RIGHT_MARGIN
		- width
	)

	control.offset_right = (
		-RIGHT_MARGIN
	)

	control.offset_top = TOP_MARGIN

	control.offset_bottom = (
		TOP_MARGIN
		+ height
	)