extends Node2D

var direction: Vector2 = Vector2.RIGHT

var speed: float = 780.0

var damage: int = 5
var knockback: float = 150.0

var max_distance: float = 220.0
var travelled_distance: float = 0.0

var hit_radius: float = 9.0

var hit_enemy_ids: Array[int] = []


func _ready() -> void:
	z_index = 42

	add_to_group(
		"player_projectiles"
	)

	add_to_group(
		"spear_projectiles"
	)

	queue_redraw()


func configure(
	direction_value: Vector2,
	distance_value: float,
	damage_value: int,
	knockback_value: float
) -> void:
	direction = direction_value

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	max_distance = distance_value
	damage = damage_value
	knockback = knockback_value

	rotation = direction.angle()


func _process(
	delta: float
) -> void:
	var movement: Vector2 = (
		direction
		* speed
		* delta
	)

	global_position += movement

	travelled_distance += movement.length()

	_hit_enemies()

	if _hit_world():
		queue_free()
		return

	if travelled_distance >= max_distance:
		queue_free()


func _hit_enemies() -> void:
	for enemy_value: Node in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy_id: int = (
			enemy_value.get_instance_id()
		)

		if hit_enemy_ids.has(
			enemy_id
		):
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		var combined_radius: float = (
			hit_radius + 16.0
		)

		if global_position.distance_squared_to(
			enemy.global_position
		) > (
			combined_radius
			* combined_radius
		):
			continue

		hit_enemy_ids.append(
			enemy_id
		)

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				global_position
					- direction
					* 20.0,
				knockback
			)

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				damage
			)


func _hit_world() -> bool:
	for blocker_value: Node in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(
			blocker_value
		):
			continue

		if blocker_value.is_queued_for_deletion():
			continue

		if not blocker_value.has_method(
			"contains_projectile_point"
		):
			continue

		var hit: bool = bool(
			blocker_value.call(
				"contains_projectile_point",
				global_position,
				hit_radius
			)
		)

		if hit:
			return true

	return false


func _draw() -> void:
	draw_line(
		Vector2(
			-30.0,
			0.0
		),
		Vector2(
			19.0,
			0.0
		),
		Color(
			0.60,
			0.38,
			0.18,
			1.0
		),
		5.0
	)

	var tip: PackedVector2Array = PackedVector2Array(
		[
			Vector2(
				31.0,
				0.0
			),
			Vector2(
				17.0,
				-7.0
			),
			Vector2(
				17.0,
				7.0
			)
		]
	)

	draw_colored_polygon(
		tip,
		Color(
			0.90,
			0.93,
			0.98,
			1.0
		)
	)

	draw_line(
		Vector2(
			-38.0,
			0.0
		),
		Vector2(
			-28.0,
			0.0
		),
		Color(
			1.0,
			0.68,
			0.20,
			0.60
		),
		3.0
	)