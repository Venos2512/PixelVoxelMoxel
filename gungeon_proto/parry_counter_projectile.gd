extends Node2D

var direction: Vector2 = Vector2.RIGHT

var speed: float = 760.0
var damage: int = 4

var life_timer: float = 0.0
var life_time: float = 2.0

var hit_radius: float = 6.0


func _ready() -> void:
	z_index = 45

	add_to_group(
		"player_projectiles"
	)

	queue_redraw()


func configure(
	position_value: Vector2,
	direction_value: Vector2
) -> void:
	global_position = position_value

	direction = direction_value

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	rotation = direction.angle()


func _process(
	delta: float
) -> void:
	life_timer += delta

	if life_timer >= life_time:
		queue_free()
		return

	global_position += (
		direction
		* speed
		* delta
	)

	if _hit_enemy():
		queue_free()
		return

	if _hit_world():
		queue_free()


func _hit_enemy() -> bool:
	for enemy_value: Node in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
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
				damage
			)

		return true

	return false


func _hit_world() -> bool:
	for blocker: Node in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(
			blocker
		):
			continue

		if not blocker.has_method(
			"contains_projectile_point"
		):
			continue

		if bool(
			blocker.call(
				"contains_projectile_point",
				global_position,
				hit_radius
			)
		):
			return true

	return false


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		5.5,
		Color(
			0.56,
			0.90,
			1.0,
			1.0
		)
	)

	draw_line(
		Vector2(
			-16.0,
			0.0
		),
		Vector2(
			-3.0,
			0.0
		),
		Color(
			0.55,
			0.90,
			1.0,
			0.55
		),
		3.0
	)