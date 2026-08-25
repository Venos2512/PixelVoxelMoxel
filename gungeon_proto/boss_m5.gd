extends Node2D

const EnemyBulletScript = preload(
	"res://gungeon_proto/enemy_bullet.gd"
)

var boss_floor: int = 1

var max_health: int = 60
var health: int = 60

var attack_timer: float = 1.0
var pattern_index: int = 0

var hit_flash: float = 0.0

var spawn_duration: float = 0.85
var spawn_timer: float = 0.85

var life_time: float = 0.0
var base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 20

	add_to_group("enemies")
	add_to_group("boss")

	max_health = (
		60
		+ max(
			0,
			boss_floor - 1
		) * 18
	)

	health = max_health

	base_position = position

	queue_redraw()


func _process(delta: float) -> void:
	life_time += delta

	spawn_timer = maxf(
		0.0,
		spawn_timer - delta
	)

	if spawn_timer > 0.0:
		queue_redraw()
		return

	hit_flash = maxf(
		0.0,
		hit_flash - delta
	)

	attack_timer -= delta

	position = (
		base_position
		+ Vector2(
			sin(life_time * 1.25) * 115.0,
			cos(life_time * 0.75) * 24.0
		)
	)

	if attack_timer > 0.0:
		queue_redraw()
		return

	var target_value = get_tree().get_first_node_in_group(
		"player"
	)

	if not is_instance_valid(target_value):
		return

	var target: Node2D = target_value as Node2D

	var phase_two: bool = (
		health <= max_health / 2
	)

	if phase_two:
		if pattern_index % 2 == 0:
			_radial_pattern(12)
		else:
			_aimed_pattern(
				target,
				7,
				60.0
			)

		attack_timer = 0.72

	else:
		if pattern_index % 2 == 0:
			_aimed_pattern(
				target,
				5,
				42.0
			)
		else:
			_radial_pattern(8)

		attack_timer = 1.0

	pattern_index += 1

	queue_redraw()


func _aimed_pattern(
	target: Node2D,
	count: int,
	total_spread: float
) -> void:
	var base_direction: Vector2 = (
		target.global_position
		- global_position
	).normalized()

	for i in range(count):
		var ratio: float = 0.5

		if count > 1:
			ratio = float(i) / float(
				count - 1
			)

		var angle_deg: float = lerpf(
			-total_spread * 0.5,
			total_spread * 0.5,
			ratio
		)

		var direction: Vector2 = (
			base_direction.rotated(
				deg_to_rad(angle_deg)
			)
		)

		_spawn_bullet(
			direction,
			190.0
		)


func _radial_pattern(count: int) -> void:
	var angle_offset: float = (
		life_time * 0.8
	)

	for i in range(count):
		var angle: float = (
			TAU
			* float(i)
			/ float(count)
			+ angle_offset
		)

		var direction := Vector2(
			cos(angle),
			sin(angle)
		)

		_spawn_bullet(
			direction,
			155.0
		)


func _spawn_bullet(
	direction: Vector2,
	projectile_speed: float
) -> void:
	var bullet = EnemyBulletScript.new()

	bullet.direction = direction
	bullet.speed = projectile_speed

	get_tree().current_scene.add_child(
		bullet
	)

	bullet.global_position = (
		global_position
		+ direction * 24.0
	)


func take_damage(amount: int) -> void:
	health -= amount

	hit_flash = 0.07

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_damage_number"
	):
		scene.call(
			"spawn_damage_number",
			global_position + Vector2(0, -34),
			amount,
			false
		)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"impact"
		)

	if health <= 0:
		health = 0

		if scene.has_method(
			"spawn_currency_drop"
		):
			scene.call(
				"spawn_currency_drop",
				global_position,
				18 + boss_floor * 4
			)

		if scene.has_method(
			"spawn_room_fx"
		):
			scene.call(
				"spawn_room_fx",
				global_position,
				"death"
			)

		if scene.has_method(
			"request_camera_shake"
		):
			scene.call(
				"request_camera_shake",
				10.0
			)

		if scene.has_method(
			"request_hit_stop"
		):
			scene.call(
				"request_hit_stop",
				0.09,
				0.10
			)

		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	if spawn_timer > 0.0:
		var progress: float = (
			1.0
			- spawn_timer
			/ spawn_duration
		)

		var size_value: float = lerpf(
			70.0,
			42.0,
			progress
		)

		draw_rect(
			Rect2(
				-size_value * 0.5,
				-size_value * 0.5,
				size_value,
				size_value
			),
			Color(
				0.85,
				0.18,
				0.30,
				0.9
			),
			false,
			3.0
		)

		draw_rect(
			Rect2(
				-size_value * 0.35,
				-size_value * 0.35,
				size_value * 0.70,
				size_value * 0.70
			),
			Color(
				1.0,
				0.55,
				0.25,
				0.8
			),
			false,
			2.0
		)

		return

	draw_ellipse_shadow()

	var body_color := Color8(
		145,
		45,
		55
	)

	if hit_flash > 0.0:
		body_color = Color8(
			255,
			235,
			215
		)

	draw_rect(
		Rect2(-25, -19, 50, 38),
		body_color,
		true
	)

	draw_rect(
		Rect2(-20, -25, 9, 10),
		Color8(185, 70, 60),
		true
	)

	draw_rect(
		Rect2(11, -25, 9, 10),
		Color8(185, 70, 60),
		true
	)

	# Eyes.
	draw_rect(
		Rect2(-14, -6, 7, 5),
		Color8(245, 205, 70),
		true
	)

	draw_rect(
		Rect2(7, -6, 7, 5),
		Color8(245, 205, 70),
		true
	)

	draw_rect(
		Rect2(-12, -5, 3, 3),
		Color8(30, 15, 20),
		true
	)

	draw_rect(
		Rect2(9, -5, 3, 3),
		Color8(30, 15, 20),
		true
	)

	# Gun arms.
	draw_rect(
		Rect2(-35, -4, 13, 8),
		Color8(95, 80, 75),
		true
	)

	draw_rect(
		Rect2(22, -4, 13, 8),
		Color8(95, 80, 75),
		true
	)

	# Phase 2 crown.
	if health <= max_health / 2:
		draw_rect(
			Rect2(-15, -32, 30, 4),
			Color8(250, 190, 60),
			true
		)

		draw_rect(
			Rect2(-12, -37, 5, 6),
			Color8(250, 190, 60),
			true
		)

		draw_rect(
			Rect2(-2, -39, 5, 8),
			Color8(250, 190, 60),
			true
		)

		draw_rect(
			Rect2(8, -37, 5, 6),
			Color8(250, 190, 60),
			true
		)


func draw_ellipse_shadow() -> void:
	draw_rect(
		Rect2(-27, 18, 54, 8),
		Color8(8, 8, 12, 160),
		true
	)