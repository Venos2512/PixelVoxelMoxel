extends Node2D

var direction: Vector2 = Vector2.LEFT

var speed: float = 285.0
var damage: int = 1

var hit_radius: float = 5.0

var life_timer: float = 0.0
var max_life: float = 6.0

var reflected: bool = false


func _ready() -> void:
	z_index = 30

	add_to_group(
		"enemy_bullets"
	)

	add_to_group(
		"training_projectiles"
	)

	queue_redraw()


func configure(
	direction_value: Vector2,
	speed_value: float = 285.0
) -> void:
	direction = direction_value

	if direction.length_squared() <= 0.001:
		direction = Vector2.LEFT

	direction = direction.normalized()

	speed = speed_value

	rotation = direction.angle()


func _process(
	delta: float
) -> void:
	life_timer += delta

	if life_timer >= max_life:
		queue_free()

		return

	global_position += (
		direction
		* speed
		* delta
	)

	if reflected:
		if _check_reflected_enemy_hit():
			return

	else:
		if _check_carried_explosive():
			return

		if _check_player_hit():
			return

	if _check_world_hit():
		return


func reflect(
	new_direction: Vector2
) -> void:
	reflected = true

	if new_direction.length_squared() > 0.001:
		direction = new_direction.normalized()

	speed *= 1.25

	rotation = direction.angle()

	if is_in_group(
		"enemy_bullets"
	):
		remove_from_group(
			"enemy_bullets"
		)

	add_to_group(
		"player_projectiles"
	)


func _check_carried_explosive() -> bool:
	for value: Node in get_tree().get_nodes_in_group(
		"carried_explosives"
	):
		if not is_instance_valid(
			value
		):
			continue

		if value.is_queued_for_deletion():
			continue

		var explosive: Node2D = (
			value as Node2D
		)

		if not is_instance_valid(
			explosive
		):
			continue

		var radius: float = 16.0

		var radius_value: Variant = explosive.get(
			"hit_radius"
		)

		if (
			typeof(radius_value) == TYPE_FLOAT
			or typeof(radius_value) == TYPE_INT
		):
			radius = float(
				radius_value
			)

		var combined_radius: float = (
			radius
			+ hit_radius
			+ 5.0
		)

		if global_position.distance_squared_to(
			explosive.global_position
		) > (
			combined_radius
			* combined_radius
		):
			continue

		if explosive.has_method(
			"trigger_from_enemy_bullet"
		):
			explosive.call(
				"trigger_from_enemy_bullet"
			)

		elif explosive.has_method(
			"take_damage"
		):
			explosive.call(
				"take_damage",
				damage
			)

		queue_free()

		return true

	return false


func _check_player_hit() -> bool:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return false

	var player: Node2D = (
		player_value as Node2D
	)

	if not is_instance_valid(
		player
	):
		return false

	var combined_radius: float = (
		hit_radius + 13.0
	)

	if global_position.distance_squared_to(
		player.global_position
	) > (
		combined_radius
		* combined_radius
	):
		return false

	if player.has_method(
		"take_damage"
	):
		player.call(
			"take_damage",
			damage
		)

	queue_free()

	return true


func _check_reflected_enemy_hit() -> bool:
	for value: Node in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			value
		):
			continue

		if value.is_queued_for_deletion():
			continue

		var enemy: Node2D = (
			value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		var combined_radius: float = (
			hit_radius + 15.0
		)

		if global_position.distance_squared_to(
			enemy.global_position
		) > (
			combined_radius
			* combined_radius
		):
			continue

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				2
			)

		queue_free()

		return true

	return false


func _check_world_hit() -> bool:
	for blocker_value: Node in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(
			blocker_value
		):
			continue

		if blocker_value == self:
			continue

		if blocker_value.is_queued_for_deletion():
			continue

		var blocker: Node2D = (
			blocker_value as Node2D
		)

		if not is_instance_valid(
			blocker
		):
			continue

		var hit: bool = false

		if blocker.has_method(
			"contains_projectile_point"
		):
			hit = bool(
				blocker.call(
					"contains_projectile_point",
					global_position,
					hit_radius
				)
			)

		else:
			var radius_value: Variant = blocker.get(
				"hit_radius"
			)

			if (
				typeof(radius_value) == TYPE_FLOAT
				or typeof(radius_value) == TYPE_INT
			):
				var blocker_radius: float = float(
					radius_value
				)

				var combined_radius: float = (
					hit_radius
					+ blocker_radius
				)

				hit = (
					global_position.distance_squared_to(
						blocker.global_position
					)
					<= combined_radius
					* combined_radius
				)

		if not hit:
			continue

		if blocker.has_method(
			"take_damage"
		):
			blocker.call(
				"take_damage",
				damage
			)

		_spawn_impact_fx()

		queue_free()

		return true

	return false


func _spawn_impact_fx() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"impact"
		)


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		5.0,
		Color(
			1.0,
			0.28,
			0.18,
			1.0
		)
	)

	draw_circle(
		Vector2.ZERO,
		2.2,
		Color(
			1.0,
			0.90,
			0.42,
			1.0
		)
	)

	draw_line(
		Vector2(
			-12.0,
			0.0
		),
		Vector2(
			-3.0,
			0.0
		),
		Color(
			1.0,
			0.25,
			0.12,
			0.55
		),
		3.0
	)