extends Node2D

const EnemyBulletScript = preload(
	"res://gungeon_proto/enemy_bullet.gd"
)

var enemy_type: String = "gunner"

var health: int = 4
var max_health: int = 4

var move_speed: float = 42.0
var preferred_distance: float = 105.0

var fire_interval: float = 1.15
var fire_timer: float = 0.8

var contact_timer: float = 0.0
var hit_flash: float = 0.0

var spawn_duration: float = 0.45
var spawn_timer: float = 0.45

var navigation_timer: float = 0.0

var cached_navigation_target := Vector2.ZERO
var cached_navigation_direction := Vector2.ZERO

var strafe_sign: float = 1.0
var strafe_timer: float = 1.0

var stuck_timer: float = 0.0

var knockback_velocity := Vector2.ZERO


func _ready() -> void:
	z_index = 20

	add_to_group("enemies")

	_configure_type()

	fire_timer += randf_range(
		0.0,
		0.55
	)

	if randf() < 0.5:
		strafe_sign = -1.0
	else:
		strafe_sign = 1.0

	strafe_timer = randf_range(
		0.8,
		1.6
	)

	queue_redraw()


func _configure_type() -> void:
	match enemy_type:
		"chaser":
			max_health = 5
			health = 5
			move_speed = 95.0
			preferred_distance = 18.0
			fire_interval = 99.0

		"spread":
			max_health = 5
			health = 5
			move_speed = 27.0
			preferred_distance = 150.0
			fire_interval = 1.4

		"elite":
			max_health = 15
			health = 15
			move_speed = 58.0
			preferred_distance = 120.0
			fire_interval = 0.68

		_:
			enemy_type = "gunner"

			max_health = 4
			health = 4
			move_speed = 42.0
			preferred_distance = 105.0
			fire_interval = 1.15


func _process(delta: float) -> void:
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

	fire_timer = maxf(
		0.0,
		fire_timer - delta
	)

	contact_timer = maxf(
		0.0,
		contact_timer - delta
	)

	navigation_timer = maxf(
		0.0,
		navigation_timer - delta
	)

	if knockback_velocity.length_squared() > 1.0:
		_move_safely(
			knockback_velocity.normalized(),
			knockback_velocity.length(),
			delta
		)

		knockback_velocity = (
			knockback_velocity.move_toward(
				Vector2.ZERO,
				720.0 * delta
			)
		)

	strafe_timer -= delta

	if strafe_timer <= 0.0:
		strafe_sign *= -1.0

		strafe_timer = randf_range(
			0.8,
			1.6
		)

	var target_value = get_tree().get_first_node_in_group(
		"player"
	)

	if not is_instance_valid(target_value):
		queue_redraw()
		return

	var target: Node2D = target_value as Node2D

	var to_player: Vector2 = (
		target.global_position
		- global_position
	)

	var distance: float = to_player.length()

	if distance <= 0.001:
		return

	var direct_direction: Vector2 = (
		to_player.normalized()
	)

	var line_of_sight: bool = (
		_has_line_of_sight(
			target
		)
	)

	if enemy_type == "chaser":
		var chase_direction: Vector2 = (
			_navigate_to(
				target.global_position
			)
		)

		chase_direction = _apply_separation(
			chase_direction
		)

		_process_chaser(
			target,
			chase_direction,
			distance,
			delta
		)

	else:
		_process_ranged_movement(
			target,
			direct_direction,
			distance,
			delta,
			line_of_sight
		)

		if (
			fire_timer <= 0.0
			and distance < 360.0
			and line_of_sight
		):
			_fire_weapon(target)

	_clamp_to_room()

	queue_redraw()


func _process_chaser(
	target: Node2D,
	direction: Vector2,
	distance: float,
	delta: float
) -> void:
	if distance > preferred_distance:
		_move_safely(
			direction,
			move_speed,
			delta
		)

	if (
		distance < 19.0
		and contact_timer <= 0.0
	):
		if target.has_method("take_damage"):
			target.call(
				"take_damage",
				1
			)

		contact_timer = 0.8


func _process_ranged_movement(
	target: Node2D,
	direct_direction: Vector2,
	distance: float,
	delta: float,
	line_of_sight: bool
) -> void:
	var desired_position: Vector2 = (
		global_position
	)

	var should_move: bool = false

	# If cover blocks the shot, reposition.
	if not line_of_sight:
		desired_position = (
			_get_tactical_position(
				target
			)
		)

		should_move = true

	elif distance > preferred_distance * 1.12:
		desired_position = target.global_position
		should_move = true

	elif distance < preferred_distance * 0.62:
		desired_position = (
			global_position
			- direct_direction * 100.0
		)

		should_move = true

	elif (
		enemy_type == "spread"
		or enemy_type == "elite"
	):
		var tangent := Vector2(
			-direct_direction.y,
			direct_direction.x
		)

		tangent *= strafe_sign

		desired_position = (
			global_position
			+ tangent * 90.0
		)

		should_move = true

	if not should_move:
		return

	var movement_direction: Vector2 = (
		_navigate_to(
			desired_position
		)
	)

	movement_direction = _apply_separation(
		movement_direction
	)

	var speed_multiplier: float = 1.0

	if distance < preferred_distance * 0.62:
		speed_multiplier = 0.72

	_move_safely(
		movement_direction,
		move_speed * speed_multiplier,
		delta
	)


func _navigate_to(
	target_position: Vector2
) -> Vector2:
	var target_moved: bool = (
		cached_navigation_target.distance_squared_to(
			target_position
		)
		> 40.0 * 40.0
	)

	if (
		navigation_timer <= 0.0
		or target_moved
	):
		var scene: Node = (
			get_tree().current_scene
		)

		var result = null

		if scene.has_method(
			"get_enemy_navigation_direction"
		):
			result = scene.call(
				"get_enemy_navigation_direction",
				global_position,
				target_position,
				11.0
			)

		if typeof(result) == TYPE_VECTOR2:
			cached_navigation_direction = result

		else:
			var direct: Vector2 = (
				target_position
				- global_position
			)

			if direct.length_squared() > 1.0:
				cached_navigation_direction = (
					direct.normalized()
				)

			else:
				cached_navigation_direction = (
					Vector2.ZERO
				)

		cached_navigation_target = target_position

		navigation_timer = randf_range(
			0.12,
			0.20
		)

	return cached_navigation_direction


func _has_line_of_sight(
	target: Node2D
) -> bool:
	var scene: Node = (
		get_tree().current_scene
	)

	if not scene.has_method(
		"enemy_has_line_of_sight"
	):
		return true

	return bool(
		scene.call(
			"enemy_has_line_of_sight",
			global_position,
			target.global_position,
			6.0
		)
	)


func _get_tactical_position(
	target: Node2D
) -> Vector2:
	var scene: Node = (
		get_tree().current_scene
	)

	if not scene.has_method(
		"get_enemy_tactical_position"
	):
		return target.global_position

	var result = scene.call(
		"get_enemy_tactical_position",
		global_position,
		target.global_position,
		preferred_distance,
		11.0
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return target.global_position


func _apply_separation(
	base_direction: Vector2
) -> Vector2:
	var separation := Vector2.ZERO

	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(enemy_value):
			continue

		if enemy_value == self:
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var other: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(other):
			continue

		var away: Vector2 = (
			global_position
			- other.global_position
		)

		var distance: float = away.length()

		if (
			distance <= 0.001
			or distance > 30.0
		):
			continue

		var strength: float = (
			1.0
			- distance / 30.0
		)

		separation += (
			away.normalized()
			* strength
		)

	var result: Vector2 = (
		base_direction
		+ separation * 0.85
	)

	if result.length_squared() <= 0.001:
		return Vector2.ZERO

	return result.normalized()


func _move_safely(
	direction: Vector2,
	speed: float,
	delta: float
) -> void:
	if direction.length_squared() <= 0.001:
		return

	var scene: Node = (
		get_tree().current_scene
	)

	var base_direction: Vector2 = (
		direction.normalized()
	)

	var try_directions: Array[Vector2] = [
		base_direction,
		base_direction.rotated(
			deg_to_rad(32.0)
		),
		base_direction.rotated(
			deg_to_rad(-32.0)
		),
		base_direction.rotated(
			deg_to_rad(65.0)
		),
		base_direction.rotated(
			deg_to_rad(-65.0)
		)
	]

	if (
		cached_navigation_direction.length_squared()
		> 0.001
	):
		try_directions.append(
			cached_navigation_direction.normalized()
		)

	var moved: bool = false

	for try_direction in try_directions:
		var movement: Vector2 = (
			try_direction
			* speed
			* delta
		)

		var candidate: Vector2 = (
			global_position
			+ movement
		)

		var can_move: bool = true

		if scene.has_method(
			"is_enemy_position_walkable"
		):
			can_move = bool(
				scene.call(
					"is_enemy_position_walkable",
					candidate,
					10.0
				)
			)

		if not can_move:
			continue

		global_position = candidate

		moved = true
		break

	if moved:
		stuck_timer = 0.0
		return

	stuck_timer += delta

	if stuck_timer < 0.30:
		return

	stuck_timer = 0.0
	navigation_timer = 0.0

	if scene.has_method(
		"find_nearest_walkable_enemy_position"
	):
		var rescue_value = scene.call(
			"find_nearest_walkable_enemy_position",
			global_position,
			11.0
		)

		if typeof(rescue_value) == TYPE_VECTOR2:
			var rescue_position: Vector2 = rescue_value

			if rescue_position.distance_to(
				global_position
			) <= 90.0:
				global_position = rescue_position


func apply_hit_knockback(
	source_position: Vector2,
	force: float
) -> void:
	var away: Vector2 = (
		global_position
		- source_position
	)

	if away.length_squared() <= 0.001:
		return

	knockback_velocity += (
		away.normalized()
		* force
	)


func _fire_weapon(
	target: Node2D
) -> void:
	match enemy_type:
		"spread":
			_fire_spread(
				target,
				3,
				28.0,
				145.0
			)

		"elite":
			_fire_spread(
				target,
				5,
				42.0,
				180.0
			)

		_:
			_fire_spread(
				target,
				1,
				0.0,
				160.0
			)

	fire_timer = fire_interval


func _fire_spread(
	target: Node2D,
	count: int,
	total_spread: float,
	projectile_speed: float
) -> void:
	var base_direction: Vector2 = (
		target.global_position
		- global_position
	).normalized()

	if count <= 1:
		_spawn_bullet(
			base_direction,
			projectile_speed
		)
		return

	for i in range(count):
		var ratio: float = float(i) / float(
			count - 1
		)

		var angle_deg: float = lerpf(
			-total_spread * 0.5,
			total_spread * 0.5,
			ratio
		)

		var shot_direction: Vector2 = (
			base_direction.rotated(
				deg_to_rad(angle_deg)
			)
		)

		_spawn_bullet(
			shot_direction,
			projectile_speed
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
		+ direction * 15.0
	)


func _clamp_to_room() -> void:
	global_position.x = clampf(
		global_position.x,
		-350.0,
		350.0
	)

	global_position.y = clampf(
		global_position.y,
		-180.0,
		180.0
	)


func take_damage(amount: int) -> void:
	health -= amount

	hit_flash = 0.08

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_damage_number"
	):
		scene.call(
			"spawn_damage_number",
			global_position + Vector2(0, -17),
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
		if scene.has_method(
			"spawn_room_fx"
		):
			scene.call(
				"spawn_room_fx",
				global_position,
				"death"
			)

		_drop_currency()
		queue_free()
	else:
		queue_redraw()


func _drop_currency() -> void:
	var amount: int = randi_range(
		1,
		3
	)

	if enemy_type == "elite":
		amount = 8

	var scene: Node = get_tree().current_scene

	if scene.has_method(
		"spawn_currency_drop"
	):
		scene.call(
			"spawn_currency_drop",
			global_position,
			amount
		)


func _draw() -> void:
	if spawn_timer > 0.0:
		var progress: float = (
			1.0
			- spawn_timer
			/ spawn_duration
		)

		var box_size: float = lerpf(
			30.0,
			14.0,
			progress
		)

		draw_rect(
			Rect2(
				-box_size * 0.5,
				-box_size * 0.5,
				box_size,
				box_size
			),
			Color(
				0.75,
				0.35,
				0.95,
				1.0 - progress * 0.5
			),
			false,
			2.0
		)

		draw_rect(
			Rect2(
				-3,
				-3,
				6,
				6
			),
			Color8(
				245,
				210,
				255
			),
			true
		)

		return

	draw_rect(
		Rect2(-9, 8, 18, 5),
		Color8(10, 10, 14, 150),
		true
	)

	var body_color := Color8(
		190,
		55,
		62
	)

	match enemy_type:
		"chaser":
			body_color = Color8(
				220,
				92,
				55
			)

		"spread":
			body_color = Color8(
				165,
				75,
				205
			)

		"elite":
			body_color = Color8(
				225,
				175,
				55
			)

	if hit_flash > 0.0:
		body_color = Color8(
			255,
			240,
			220
		)

	var scale_bonus: float = 0.0

	if enemy_type == "elite":
		scale_bonus = 4.0

	draw_rect(
		Rect2(
			-8 - scale_bonus * 0.5,
			-8 - scale_bonus * 0.5,
			16 + scale_bonus,
			17 + scale_bonus
		),
		body_color,
		true
	)

	if enemy_type == "chaser":
		draw_rect(
			Rect2(-5, -10, 3, 4),
			Color8(255, 205, 90),
			true
		)

		draw_rect(
			Rect2(2, -10, 3, 4),
			Color8(255, 205, 90),
			true
		)

	elif enemy_type == "spread":
		draw_circle(
			Vector2(0, -3),
			4.0,
			Color8(235, 150, 255)
		)

	elif enemy_type == "elite":
		draw_rect(
			Rect2(-11, -13, 22, 3),
			Color8(255, 225, 100),
			true
		)

	else:
		draw_rect(
			Rect2(7, -1, 8, 4),
			Color8(90, 78, 74),
			true
		)

	var pip_count: int = mini(
		health,
		8
	)

	for i in range(pip_count):
		draw_rect(
			Rect2(
				-10 + i * 3,
				-17,
				2,
				2
			),
			Color8(108, 220, 112),
			true
		)