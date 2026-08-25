extends Node

var host: Node

var active: bool = false

var waves: Array = []

var current_wave: int = -1

var pending_wave: int = -1

var reinforcement_timer: float = 0.0

var reinforcement_delay: float = 1.15

var encounter_room: Vector2i = Vector2i.ZERO


func setup(
	host_node: Node
) -> void:
	host = host_node


func start_encounter(
	room_position: Vector2i,
	floor_number: int,
	base_enemy_count: int
) -> void:
	cancel()

	encounter_room = room_position

	waves = _build_waves(
		floor_number,
		base_enemy_count
	)

	if waves.is_empty():
		return

	active = true

	_start_wave(0)


func cancel() -> void:
	active = false

	waves.clear()

	current_wave = -1
	pending_wave = -1

	reinforcement_timer = 0.0


func _process(delta: float) -> void:
	if not active:
		return

	if not is_instance_valid(host):
		cancel()
		return

	var current_room_value = host.get(
		"current_room"
	)

	if typeof(current_room_value) == TYPE_VECTOR2I:
		var current_room: Vector2i = current_room_value

		if current_room != encounter_room:
			cancel()
			return

	if pending_wave >= 0:
		reinforcement_timer -= delta

		if reinforcement_timer <= 0.0:
			var wave_index: int = pending_wave

			pending_wave = -1

			_start_wave(
				wave_index
			)

		return

	if not _has_alive_enemies():
		var next_wave: int = (
			current_wave + 1
		)

		if next_wave >= waves.size():
			active = false

			if host.has_method(
				"notify_director_encounter_complete"
			):
				host.call(
					"notify_director_encounter_complete"
				)

			return

		pending_wave = next_wave

		reinforcement_timer = (
			reinforcement_delay
		)

		if host.has_method(
			"spawn_room_fx"
		):
			host.call(
				"spawn_room_fx",
				Vector2.ZERO,
				"reinforcement"
			)


func _build_waves(
	floor_number: int,
	base_enemy_count: int
) -> Array:
	var result: Array = []

	var total_count: int = maxi(
		2,
		base_enemy_count
	)

	var wave_count: int = 2

	if (
		floor_number >= 3
		or total_count >= 6
	):
		wave_count = 3

	var remaining: int = total_count

	for i in range(wave_count):
		var waves_left: int = (
			wave_count - i
		)

		var count: int = int(
			ceil(
				float(remaining)
				/ float(waves_left)
			)
		)

		count = maxi(
			1,
			count
		)

		remaining -= count

		var wave: Array[String] = []

		for enemy_index in range(count):
			wave.append(
				_pick_enemy_type(
					floor_number,
					i,
					enemy_index
				)
			)

		result.append(wave)

	return result


func _pick_enemy_type(
	floor_number: int,
	wave_index: int,
	enemy_index: int
) -> String:
	var roll: float = randf()

	if floor_number <= 1:
		if roll < 0.45:
			return "gunner"

		if roll < 0.75:
			return "chaser"

		return "spread"

	if wave_index >= 2:
		if roll < 0.20:
			return "elite"

	if floor_number >= 3:
		if roll < 0.20:
			return "elite"

		if roll < 0.47:
			return "spread"

		if roll < 0.72:
			return "chaser"

		return "gunner"

	if roll < 0.38:
		return "gunner"

	if roll < 0.70:
		return "chaser"

	return "spread"


func _start_wave(
	wave_index: int
) -> void:
	if wave_index < 0:
		return

	if wave_index >= waves.size():
		return

	current_wave = wave_index

	var wave_value = waves[
		wave_index
	]

	if typeof(wave_value) != TYPE_ARRAY:
		return

	var wave: Array = wave_value

	for i in range(wave.size()):
		var enemy_type: String = str(
			wave[i]
		)

		var desired_position: Vector2 = (
			_get_spawn_position(
				i,
				wave.size()
			)
		)

		if host.has_method(
			"spawn_director_enemy"
		):
			host.call(
				"spawn_director_enemy",
				desired_position,
				enemy_type
			)


func _get_spawn_position(
	index: int,
	count: int
) -> Vector2:
	if count <= 0:
		return Vector2.ZERO

	var angle_offset: float = (
		randf_range(
			-0.30,
			0.30
		)
	)

	var angle: float = (
		TAU
		* float(index)
		/ float(count)
		+ angle_offset
	)

	var radius: float = randf_range(
		155.0,
		245.0
	)

	return Vector2(
		cos(angle),
		sin(angle)
	) * radius


func _has_alive_enemies() -> bool:
	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		return true

	return false