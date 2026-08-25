extends Node2D

var active_radius: float = 23.0

var cycle_duration: float = 2.2
var warning_duration: float = 0.55
var active_duration: float = 0.32

var cycle_timer: float = 0.0

var damage: int = 2

var triggered_this_cycle: Dictionary = {}


func _ready() -> void:
	z_index = 1

	add_to_group("room_hazards")
	add_to_group("danger_zones")

	cycle_timer = randf_range(
		0.0,
		cycle_duration
	)

	queue_redraw()


func _process(delta: float) -> void:
	cycle_timer += delta

	if cycle_timer >= cycle_duration:
		cycle_timer -= cycle_duration

		triggered_this_cycle.clear()

	if is_active():
		_damage_targets()

	queue_redraw()


func is_warning() -> bool:
	var active_start: float = (
		cycle_duration
		- active_duration
	)

	var warning_start: float = (
		active_start
		- warning_duration
	)

	return (
		cycle_timer >= warning_start
		and cycle_timer < active_start
	)


func is_active() -> bool:
	return (
		cycle_timer
		>= cycle_duration - active_duration
	)


func is_dangerous_for_ai() -> bool:
	return (
		is_warning()
		or is_active()
	)


func contains_danger_point(
	global_point: Vector2,
	radius: float
) -> bool:
	if not is_dangerous_for_ai():
		return false

	var combined_radius: float = (
		active_radius + radius
	)

	return (
		global_position.distance_squared_to(
			global_point
		)
		<= combined_radius
		* combined_radius
	)


func _damage_targets() -> void:
	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if is_instance_valid(player_value):
		_try_damage_target(
			player_value
		)

	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(enemy_value):
			continue

		_try_damage_target(
			enemy_value
		)


func _try_damage_target(
	target_value
) -> void:
	if not is_instance_valid(target_value):
		return

	if target_value.is_queued_for_deletion():
		return

	var target: Node2D = (
		target_value as Node2D
	)

	if not is_instance_valid(target):
		return

	var target_id: int = (
		target.get_instance_id()
	)

	if triggered_this_cycle.has(
		target_id
	):
		return

	if global_position.distance_to(
		target.global_position
	) > active_radius:
		return

	if target.has_method(
		"take_damage"
	):
		target.call(
			"take_damage",
			damage
		)

	triggered_this_cycle[
		target_id
	] = true

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			2.0
		)


func _draw() -> void:
	var plate_color := Color8(
		65,
		61,
		66
	)

	if is_warning():
		plate_color = Color8(
			150,
			85,
			45
		)

	if is_active():
		plate_color = Color8(
			185,
			55,
			45
		)

	draw_rect(
		Rect2(
			-20,
			-20,
			40,
			40
		),
		plate_color,
		true
	)

	draw_rect(
		Rect2(
			-20,
			-20,
			40,
			40
		),
		Color8(
			95,
			88,
			90
		),
		false,
		2.0
	)

	if is_warning():
		draw_arc(
			Vector2.ZERO,
			25.0,
			0.0,
			TAU,
			24,
			Color(
				1.0,
				0.45,
				0.15,
				0.65
			),
			2.0
		)

	if not is_active():
		return

	var spike_color := Color8(
		225,
		220,
		205
	)

	for x in range(-1, 2):
		for y in range(-1, 2):
			var center := Vector2(
				float(x) * 11.0,
				float(y) * 11.0
			)

			var points := PackedVector2Array([
				center + Vector2(0, -7),
				center + Vector2(-5, 5),
				center + Vector2(5, 5)
			])

			draw_colored_polygon(
				points,
				spike_color
			)