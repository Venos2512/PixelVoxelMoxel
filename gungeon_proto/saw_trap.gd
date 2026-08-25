extends Node2D

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO

var move_speed: float = 115.0

var direction_sign: float = 1.0

var damage_radius: float = 19.0
var damage: int = 2

var hit_cooldowns: Dictionary = {}

var rotation_value: float = 0.0


func _ready() -> void:
	z_index = 2

	add_to_group("room_hazards")
	add_to_group("danger_zones")

	if start_position == end_position:
		start_position = position
		end_position = position + Vector2(
			120,
			0
		)

	global_position = start_position

	queue_redraw()


func _process(delta: float) -> void:
	rotation_value += (
		delta * 9.0
	)

	_update_hit_cooldowns(
		delta
	)

	var target_position: Vector2 = (
		end_position
		if direction_sign > 0.0
		else start_position
	)

	var to_target: Vector2 = (
		target_position
		- global_position
	)

	var distance: float = (
		to_target.length()
	)

	if distance <= 3.0:
		direction_sign *= -1.0

	elif distance > 0.001:
		var movement: Vector2 = (
			to_target.normalized()
			* move_speed
			* delta
		)

		if movement.length() > distance:
			movement = to_target

		global_position += movement

	_damage_targets()

	queue_redraw()


func is_dangerous_for_ai() -> bool:
	return true


func contains_danger_point(
	global_point: Vector2,
	radius: float
) -> bool:
	var combined_radius: float = (
		damage_radius
		+ radius
		+ 6.0
	)

	return (
		global_position.distance_squared_to(
			global_point
		)
		<= combined_radius
		* combined_radius
	)


func _update_hit_cooldowns(
	delta: float
) -> void:
	var keys: Array = (
		hit_cooldowns.keys()
	)

	for key_value in keys:
		var time_left: float = (
			float(
				hit_cooldowns[
					key_value
				]
			)
			- delta
		)

		if time_left <= 0.0:
			hit_cooldowns.erase(
				key_value
			)

		else:
			hit_cooldowns[
				key_value
			] = time_left


func _damage_targets() -> void:
	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if is_instance_valid(player_value):
		_try_damage(
			player_value
		)

	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(enemy_value):
			continue

		_try_damage(
			enemy_value
		)


func _try_damage(
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

	if hit_cooldowns.has(
		target_id
	):
		return

	var distance: float = (
		global_position.distance_to(
			target.global_position
		)
	)

	if distance > damage_radius:
		return

	if target.has_method(
		"take_damage"
	):
		target.call(
			"take_damage",
			damage
		)

	hit_cooldowns[
		target_id
	] = 0.65

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"impact"
		)


func _draw() -> void:
	# Rail.
	var local_start: Vector2 = (
		to_local(start_position)
	)

	var local_end: Vector2 = (
		to_local(end_position)
	)

	draw_line(
		local_start,
		local_end,
		Color8(
			65,
			60,
			62
		),
		5.0
	)

	draw_circle(
		Vector2.ZERO,
		17.0,
		Color8(
			105,
			105,
			110
		)
	)

	for i in range(12):
		var angle: float = (
			TAU
			* float(i)
			/ 12.0
			+ rotation_value
		)

		var direction := Vector2(
			cos(angle),
			sin(angle)
		)

		var side := Vector2(
			-direction.y,
			direction.x
		)

		var outer: Vector2 = (
			direction * 24.0
		)

		var points := PackedVector2Array([
			direction * 14.0
				+ side * 5.0,
			outer,
			direction * 14.0
				- side * 5.0
		])

		draw_colored_polygon(
			points,
			Color8(
				190,
				190,
				195
			)
		)

	draw_circle(
		Vector2.ZERO,
		6.0,
		Color8(
			70,
			55,
			55
		)
	)