extends Node

const CARDINAL_DIRECTIONS = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]

const DIAGONAL_DIRECTIONS = [
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(1, -1),
	Vector2i(-1, -1)
]

var room_rect: Rect2 = Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)

var cell_size: float = 20.0

var room_margin: float = 18.0


func configure(
	new_room_rect: Rect2
) -> void:
	room_rect = new_room_rect


func get_move_direction(
	from_position: Vector2,
	target_position: Vector2,
	agent_radius: float = 10.0
) -> Vector2:
	var direct_vector: Vector2 = (
		target_position
		- from_position
	)

	if direct_vector.length_squared() <= 1.0:
		return Vector2.ZERO

	if has_line_of_sight(
		from_position,
		target_position,
		agent_radius
	):
		return direct_vector.normalized()

	var path: Array[Vector2] = _find_path(
		from_position,
		target_position,
		agent_radius
	)

	if path.size() >= 2:
		var best_waypoint: Vector2 = path[1]

		# Skip unnecessary intermediate cells when possible.
		for i in range(
			path.size() - 1,
			0,
			-1
		):
			if has_line_of_sight(
				from_position,
				path[i],
				agent_radius
			):
				best_waypoint = path[i]
				break

		var path_direction: Vector2 = (
			best_waypoint
			- from_position
		)

		if path_direction.length_squared() > 1.0:
			return path_direction.normalized()

	return _fallback_steer(
		from_position,
		target_position,
		agent_radius
	)


func has_line_of_sight(
	from_position: Vector2,
	target_position: Vector2,
	radius: float = 6.0
) -> bool:
	var difference: Vector2 = (
		target_position
		- from_position
	)

	var distance: float = difference.length()

	if distance <= 1.0:
		return true

	var direction: Vector2 = (
		difference / distance
	)

	var sample_distance: float = 12.0

	var steps: int = maxi(
		1,
		int(
			ceil(
				distance
				/ sample_distance
			)
		)
	)

	# Do not test exact start/end points.
	for i in range(1, steps):
		var ratio: float = (
			float(i)
			/ float(steps)
		)

		var sample_position: Vector2 = (
			from_position
			+ difference * ratio
		)

		if not is_position_walkable(
			sample_position,
			radius
		):
			return false

	return true


func is_position_walkable(
	global_position: Vector2,
	radius: float = 10.0
) -> bool:
	var walkable_rect: Rect2 = room_rect.grow(
		-room_margin
	)

	if not walkable_rect.has_point(
		global_position
	):
		return false

	for blocker_value in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(blocker_value):
			continue

		if blocker_value.is_queued_for_deletion():
			continue

		var blocker: Node2D = (
			blocker_value as Node2D
		)

		if not is_instance_valid(blocker):
			continue

		var blocked: bool = false

		if blocker.has_method(
			"contains_navigation_point"
		):
			blocked = bool(
				blocker.call(
					"contains_navigation_point",
					global_position,
					radius
				)
			)

		elif blocker.has_method(
			"contains_projectile_point"
		):
			blocked = bool(
				blocker.call(
					"contains_projectile_point",
					global_position,
					radius
				)
			)

		else:
			var hit_radius_value = blocker.get(
				"hit_radius"
			)

			if hit_radius_value != null:
				var blocker_radius: float = float(
					hit_radius_value
				)

				var total_radius: float = (
					blocker_radius
					+ radius
				)

				blocked = (
					global_position.distance_squared_to(
						blocker.global_position
					)
					<= total_radius
					* total_radius
				)

		if blocked:
			return false

	return true


func _find_path(
	from_position: Vector2,
	target_position: Vector2,
	agent_radius: float
) -> Array[Vector2]:
	var result: Array[Vector2] = []

	var start_cell: Vector2i = _world_to_cell(
		from_position
	)

	var goal_cell: Vector2i = _world_to_cell(
		target_position
	)

	start_cell = _find_nearest_walkable_cell(
		start_cell,
		agent_radius
	)

	goal_cell = _find_nearest_walkable_cell(
		goal_cell,
		agent_radius
	)

	var queue: Array[Vector2i] = []
	var queue_index: int = 0

	var visited: Dictionary = {}
	var came_from: Dictionary = {}

	queue.append(
		start_cell
	)

	visited[start_cell] = true

	var found: bool = false

	while (
		queue_index < queue.size()
		and visited.size() < 2200
	):
		var current: Vector2i = queue[
			queue_index
		]

		queue_index += 1

		if current == goal_cell:
			found = true
			break

		for offset_value in CARDINAL_DIRECTIONS:
			var offset: Vector2i = offset_value

			var neighbor: Vector2i = (
				current + offset
			)

			if visited.has(neighbor):
				continue

			if not _is_cell_walkable(
				neighbor,
				agent_radius
			):
				continue

			visited[neighbor] = true
			came_from[neighbor] = current

			queue.append(neighbor)

		# Diagonal movement.
		for offset_value in DIAGONAL_DIRECTIONS:
			var offset: Vector2i = offset_value

			var neighbor: Vector2i = (
				current + offset
			)

			if visited.has(neighbor):
				continue

			if not _is_cell_walkable(
				neighbor,
				agent_radius
			):
				continue

			# Prevent diagonal corner cutting.
			var side_a := Vector2i(
				current.x + offset.x,
				current.y
			)

			var side_b := Vector2i(
				current.x,
				current.y + offset.y
			)

			if not _is_cell_walkable(
				side_a,
				agent_radius
			):
				continue

			if not _is_cell_walkable(
				side_b,
				agent_radius
			):
				continue

			visited[neighbor] = true
			came_from[neighbor] = current

			queue.append(neighbor)

	if not found:
		return result

	var reversed_cells: Array[Vector2i] = []

	var step: Vector2i = goal_cell

	reversed_cells.append(step)

	while step != start_cell:
		if not came_from.has(step):
			break

		var previous_value = came_from[step]

		step = previous_value

		reversed_cells.append(step)

	reversed_cells.reverse()

	for cell in reversed_cells:
		result.append(
			_cell_to_world(cell)
		)

	return result


func _find_nearest_walkable_cell(
	origin: Vector2i,
	agent_radius: float
) -> Vector2i:
	if _is_cell_walkable(
		origin,
		agent_radius
	):
		return origin

	for search_radius in range(1, 4):
		for x in range(
			-search_radius,
			search_radius + 1
		):
			for y in range(
				-search_radius,
				search_radius + 1
			):
				var candidate := (
					origin
					+ Vector2i(x, y)
				)

				if _is_cell_walkable(
					candidate,
					agent_radius
				):
					return candidate

	return origin


func find_nearest_walkable_position(
	origin: Vector2,
	agent_radius: float = 10.0
) -> Vector2:
	if is_position_walkable(
		origin,
		agent_radius
	):
		return origin

	var origin_cell: Vector2i = _world_to_cell(
		origin
	)

	for search_radius in range(1, 13):
		var best_position := Vector2.ZERO
		var best_distance: float = INF

		for x in range(
			-search_radius,
			search_radius + 1
		):
			for y in range(
				-search_radius,
				search_radius + 1
			):
				if (
					abs(x) != search_radius
					and abs(y) != search_radius
				):
					continue

				var cell := (
					origin_cell
					+ Vector2i(x, y)
				)

				if not _is_cell_walkable(
					cell,
					agent_radius
				):
					continue

				var candidate: Vector2 = (
					_cell_to_world(cell)
				)

				var distance: float = (
					candidate.distance_squared_to(
						origin
					)
				)

				if distance < best_distance:
					best_distance = distance
					best_position = candidate

		if best_distance < INF:
			return best_position

	return origin


func find_tactical_position(
	from_position: Vector2,
	target_position: Vector2,
	desired_distance: float,
	agent_radius: float = 10.0
) -> Vector2:
	var best_position := target_position
	var best_score: float = INF

	var radii := [
		desired_distance,
		desired_distance * 0.78,
		desired_distance * 1.18
	]

	for radius_value in radii:
		var radius: float = float(
			radius_value
		)

		for i in range(16):
			var angle: float = (
				TAU
				* float(i)
				/ 16.0
			)

			var candidate := (
				target_position
				+ Vector2(
					cos(angle),
					sin(angle)
				) * radius
			)

			if not _is_position_navigation_safe(
				candidate,
				agent_radius
			):
				continue

			if not has_line_of_sight(
				candidate,
				target_position,
				6.0
			):
				continue

			var travel_score: float = (
				from_position.distance_squared_to(
					candidate
				)
			)

			var distance_error: float = absf(
				candidate.distance_to(
					target_position
				)
				- desired_distance
			)

			var score: float = (
				travel_score
				+ distance_error
				* distance_error
				* 3.0
			)

			if score < best_score:
				best_score = score
				best_position = candidate

	if best_score < INF:
		return best_position

	return find_nearest_walkable_position(
		target_position,
		agent_radius
	)


func _is_position_dangerous_for_ai(
	global_position: Vector2,
	radius: float
) -> bool:
	for danger_value in get_tree().get_nodes_in_group(
		"danger_zones"
	):
		if not is_instance_valid(
			danger_value
		):
			continue

		if danger_value.is_queued_for_deletion():
			continue

		var danger: Node2D = (
			danger_value as Node2D
		)

		if not is_instance_valid(danger):
			continue

		if not danger.has_method(
			"is_dangerous_for_ai"
		):
			continue

		if not bool(
			danger.call(
				"is_dangerous_for_ai"
			)
		):
			continue

		if not danger.has_method(
			"contains_danger_point"
		):
			continue

		var dangerous: bool = bool(
			danger.call(
				"contains_danger_point",
				global_position,
				radius
			)
		)

		if dangerous:
			return true

	return false


func _is_position_navigation_safe(
	global_position: Vector2,
	radius: float
) -> bool:
	if not is_position_walkable(
		global_position,
		radius
	):
		return false

	return not _is_position_dangerous_for_ai(
		global_position,
		radius
	)


func _fallback_steer(
	from_position: Vector2,
	target_position: Vector2,
	agent_radius: float
) -> Vector2:
	var desired: Vector2 = (
		target_position
		- from_position
	)

	if desired.length_squared() <= 1.0:
		return Vector2.ZERO

	desired = desired.normalized()

	var angles := [
		0.0,
		30.0,
		-30.0,
		60.0,
		-60.0,
		90.0,
		-90.0,
		135.0,
		-135.0,
		180.0
	]

	var best_direction := Vector2.ZERO
	var best_score: float = INF

	for angle_value in angles:
		var angle: float = float(
			angle_value
		)

		var candidate_direction: Vector2 = (
			desired.rotated(
				deg_to_rad(angle)
			)
		)

		var test_position: Vector2 = (
			from_position
			+ candidate_direction * 26.0
		)

		if not _is_position_navigation_safe(
			test_position,
			agent_radius
		):
			continue

		var score: float = (
			test_position.distance_squared_to(
				target_position
			)
		)

		if score < best_score:
			best_score = score
			best_direction = candidate_direction

	return best_direction


func _world_to_cell(
	world_position: Vector2
) -> Vector2i:
	var local_position: Vector2 = (
		world_position
		- room_rect.position
	)

	var grid_size: Vector2i = _get_grid_size()

	var cell := Vector2i(
		int(
			floor(
				local_position.x
				/ cell_size
			)
		),
		int(
			floor(
				local_position.y
				/ cell_size
			)
		)
	)

	cell.x = clampi(
		cell.x,
		0,
		grid_size.x - 1
	)

	cell.y = clampi(
		cell.y,
		0,
		grid_size.y - 1
	)

	return cell


func _cell_to_world(
	cell: Vector2i
) -> Vector2:
	return (
		room_rect.position
		+ Vector2(
			(
				float(cell.x)
				+ 0.5
			) * cell_size,
			(
				float(cell.y)
				+ 0.5
			) * cell_size
		)
	)


func _get_grid_size() -> Vector2i:
	return Vector2i(
		maxi(
			1,
			int(
				floor(
					room_rect.size.x
					/ cell_size
				)
			)
		),
		maxi(
			1,
			int(
				floor(
					room_rect.size.y
					/ cell_size
				)
			)
		)
	)


func _is_cell_walkable(
	cell: Vector2i,
	agent_radius: float
) -> bool:
	var grid_size: Vector2i = _get_grid_size()

	if cell.x < 0:
		return false

	if cell.y < 0:
		return false

	if cell.x >= grid_size.x:
		return false

	if cell.y >= grid_size.y:
		return false

	var cell_position: Vector2 = (
		_cell_to_world(cell)
	)

	if not is_position_walkable(
		cell_position,
		agent_radius
	):
		return false

	if _is_position_dangerous_for_ai(
		cell_position,
		agent_radius
	):
		return false

	return true