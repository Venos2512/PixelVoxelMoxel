extends Node2D

var direction := Vector2.RIGHT

var speed: float = 480.0
var lifetime: float = 1.4

var damage: int = 1

var hit_radius: float = 9.0


func _ready() -> void:
	add_to_group("player_bullets")
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var distance_sq := global_position.distance_squared_to(
			enemy.global_position
		)

		if distance_sq <= hit_radius * hit_radius:
			if enemy.has_method(
				"apply_hit_knockback"
			):
				enemy.call(
					"apply_hit_knockback",
					global_position,
					90.0
				)

			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

			var scene: Node = (
				get_tree().current_scene
			)

			if scene.has_method(
				"request_hit_stop"
			):
				scene.call(
					"request_hit_stop",
					0.022,
					0.18
				)

			if scene.has_method(
				"request_camera_shake"
			):
				scene.call(
					"request_camera_shake",
					1.3
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
					damage
				)

			queue_free()
			return


func _draw() -> void:
	draw_rect(
		Rect2(-4, -2, 8, 4),
		Color8(255, 225, 102),
		true
	)

	draw_rect(
		Rect2(-2, -1, 4, 2),
		Color8(255, 250, 205),
		true
	)