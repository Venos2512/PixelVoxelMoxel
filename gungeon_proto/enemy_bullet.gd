extends Node2D

var direction := Vector2.RIGHT

var speed := 150.0
var lifetime := 5.0

var hit_radius := 10.0


func _ready() -> void:
	add_to_group("enemy_bullets")
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	for player in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(player):
			continue

		var distance_sq := global_position.distance_squared_to(
			player.global_position
		)

		if distance_sq <= hit_radius * hit_radius:
			if player.has_method("take_damage"):
				player.take_damage(1)

			queue_free()
			return

	# Explosive barrel đang nằm trên tay player không còn là
	# bullet_blocker vật lý, nhưng enemy bullet vẫn có thể bắn trúng.
	for explosive_value in get_tree().get_nodes_in_group(
		"carried_explosives"
	):
		if not is_instance_valid(
			explosive_value
		):
			continue

		if explosive_value.is_queued_for_deletion():
			continue

		var explosive: Node2D = (
			explosive_value as Node2D
		)

		if not is_instance_valid(
			explosive
		):
			continue

		var explosive_radius_value = explosive.get(
			"hit_radius"
		)

		if explosive_radius_value == null:
			continue

		var explosive_radius: float = float(
			explosive_radius_value
		)

		# Tăng nhẹ vùng intercept khi đang cầm để barrel
		# thực sự có thể đỡ viên đạn bay về phía player.
		var combined_explosive_radius: float = (
			explosive_radius
			+ hit_radius
			+ 5.0
		)

		var explosive_distance_sq: float = (
			global_position.distance_squared_to(
				explosive.global_position
			)
		)

		if explosive_distance_sq > (
			combined_explosive_radius
			* combined_explosive_radius
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
				1
			)

		queue_free()

		return

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

		var projectile_hit: bool = false

		if blocker.has_method(
			"contains_projectile_point"
		):
			projectile_hit = bool(
				blocker.call(
					"contains_projectile_point",
					global_position,
					hit_radius
				)
			)

		else:
			var blocker_radius: float = float(
				blocker.get("hit_radius")
			)

			var combined_radius: float = (
				hit_radius
				+ blocker_radius
			)

			var blocker_distance_sq: float = (
				global_position.distance_squared_to(
					blocker.global_position
				)
			)

			projectile_hit = (
				blocker_distance_sq
				<= combined_radius
				* combined_radius
			)

		if projectile_hit:
			if blocker.has_method(
				"take_damage"
			):
				blocker.call(
					"take_damage",
					1
				)

			queue_free()
			return


func _draw() -> void:
	# Dark outline.
	draw_circle(
		Vector2.ZERO,
		5.0,
		Color8(76, 18, 25)
	)

	draw_circle(
		Vector2.ZERO,
		3.0,
		Color8(244, 70, 76)
	)

	draw_circle(
		Vector2(-1, -1),
		1.0,
		Color8(255, 190, 156)
	)