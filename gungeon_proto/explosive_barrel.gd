extends StaticBody2D

var prop_id: String = ""

var health: int = 1

var hit_radius: float = 15.0
var collision_size := Vector2(22, 28)

var activated: bool = false

var fuse_duration: float = 0.32
var fuse_timer: float = 0.0

var explosion_radius: float = 95.0
var explosion_damage: int = 4

var blink_timer: float = 0.0

var interaction_radius: float = 42.0

var is_carried: bool = false
var is_thrown: bool = false

var carried_by: Node2D = null

var throw_velocity := Vector2.ZERO
var throw_speed: float = 410.0
var throw_drag: float = 480.0
var throw_timer: float = 0.0
var max_throw_time: float = 0.72

var throw_impact_damage: int = 2

var e_key_was_down: bool = false
var q_key_was_down: bool = false

var collision_shape: CollisionShape2D
var prompt_label: Label


func _ready() -> void:
	z_index = 6

	add_to_group("room_props")
	add_to_group("bullet_blockers")
	add_to_group("destructibles")
	add_to_group("explosive_barrels")
	add_to_group("interactable_barrels")

	collision_shape = CollisionShape2D.new()

	var shape := RectangleShape2D.new()

	shape.size = collision_size
	collision_shape.shape = shape

	add_child(collision_shape)

	prompt_label = Label.new()

	prompt_label.position = Vector2(
		-55,
		-40
	)

	prompt_label.size = Vector2(
		110,
		22
	)

	prompt_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	prompt_label.add_theme_font_size_override(
		"font_size",
		9
	)

	prompt_label.z_index = 50
	prompt_label.visible = false

	add_child(prompt_label)

	queue_redraw()


func _process(delta: float) -> void:
	var e_down: bool = Input.is_key_pressed(
		KEY_E
	)

	var q_down: bool = Input.is_key_pressed(
		KEY_Q
	)

	if is_carried:
		_update_carried_state()

		if (
			e_down
			and not e_key_was_down
		):
			_throw_barrel()

		elif (
			q_down
			and not q_key_was_down
		):
			_place_barrel()

		e_key_was_down = e_down
		q_key_was_down = q_down

		queue_redraw()
		return

	if is_thrown:
		_update_throw(
			delta
		)

		e_key_was_down = e_down
		q_key_was_down = q_down

		queue_redraw()
		return

	_update_interaction_prompt()

	if (
		not activated
		and e_down
		and not e_key_was_down
		and _can_be_picked_up()
	):
		_pick_up()

	e_key_was_down = e_down
	q_key_was_down = q_down

	if not activated:
		return

	fuse_timer -= delta
	blink_timer += delta

	if fuse_timer <= 0.0:
		_explode()
		return

	queue_redraw()


func _get_player() -> Node2D:
	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if not is_instance_valid(
		player_value
	):
		return null

	return player_value as Node2D


func _get_player_aim_direction(
	player: Node2D
) -> Vector2:
	var aim_value = player.get(
		"aim_direction"
	)

	if typeof(aim_value) == TYPE_VECTOR2:
		var direction: Vector2 = aim_value

		if direction.length_squared() > 0.001:
			return direction.normalized()

	var mouse_direction: Vector2 = (
		get_global_mouse_position()
		- player.global_position
	)

	if mouse_direction.length_squared() > 0.001:
		return mouse_direction.normalized()

	return Vector2.RIGHT


func _is_nearest_available_barrel(
	player: Node2D
) -> bool:
	var my_distance: float = (
		global_position.distance_squared_to(
			player.global_position
		)
	)

	for barrel_value in get_tree().get_nodes_in_group(
		"interactable_barrels"
	):
		if not is_instance_valid(
			barrel_value
		):
			continue

		if barrel_value == self:
			continue

		if barrel_value.is_queued_for_deletion():
			continue

		var barrel: Node2D = (
			barrel_value as Node2D
		)

		if not is_instance_valid(barrel):
			continue

		var other_carried_value = barrel.get(
			"is_carried"
		)

		var other_thrown_value = barrel.get(
			"is_thrown"
		)

		var other_activated_value = barrel.get(
			"activated"
		)

		if bool(other_carried_value):
			continue

		if bool(other_thrown_value):
			continue

		if bool(other_activated_value):
			continue

		var other_distance: float = (
			barrel.global_position.distance_squared_to(
				player.global_position
			)
		)

		if other_distance < my_distance:
			return false

	return true


func _can_be_picked_up() -> bool:
	if activated:
		return false

	if is_carried:
		return false

	if is_thrown:
		return false

	var player: Node2D = _get_player()

	if not is_instance_valid(player):
		return false

	if global_position.distance_to(
		player.global_position
	) > interaction_radius:
		return false

	var carried_value = player.get_meta(
		"carried_barrel",
		null
	)

	if (
		carried_value != null
		and is_instance_valid(carried_value)
	):
		return false

	return _is_nearest_available_barrel(
		player
	)


func _update_interaction_prompt() -> void:
	if not is_instance_valid(
		prompt_label
	):
		return

	prompt_label.visible = false

	if activated:
		return

	var player: Node2D = _get_player()

	if not is_instance_valid(player):
		return

	if global_position.distance_to(
		player.global_position
	) > interaction_radius:
		return

	if not _is_nearest_available_barrel(
		player
	):
		return

	var carried_value = player.get_meta(
		"carried_barrel",
		null
	)

	if (
		carried_value != null
		and is_instance_valid(carried_value)
	):
		return

	prompt_label.text = "[E] PICK UP"

	prompt_label.visible = true


func _pick_up() -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(player):
		return

	is_carried = true
	is_thrown = false

	carried_by = player

	throw_velocity = Vector2.ZERO
	throw_timer = 0.0

	z_index = 25
	rotation = 0.0

	player.set_meta(
		"carried_barrel",
		self
	)

	if is_in_group(
		"bullet_blockers"
	):
		remove_from_group(
			"bullet_blockers"
		)

	if is_in_group(
		"destructibles"
	):
		remove_from_group(
			"destructibles"
		)

	if is_instance_valid(
		collision_shape
	):
		collision_shape.set_deferred(
			"disabled",
			true
		)

	if is_instance_valid(
		prompt_label
	):
		prompt_label.text = (
			"[E] THROW   [Q] PLACE"
		)

		prompt_label.visible = true

	_update_carried_state()


func _update_carried_state() -> void:
	if not is_instance_valid(
		carried_by
	):
		_release_carrier_reference()
		queue_free()
		return

	var direction: Vector2 = (
		_get_player_aim_direction(
			carried_by
		)
	)

	global_position = (
		carried_by.global_position
		+ direction * 29.0
		+ Vector2(
			0,
			-13
		)
	)

	rotation = 0.0

	if is_instance_valid(
		prompt_label
	):
		prompt_label.text = (
			"[E] THROW   [Q] PLACE"
		)

		prompt_label.visible = true


func _throw_barrel() -> void:
	if not is_instance_valid(
		carried_by
	):
		return

	var player: Node2D = carried_by

	var direction: Vector2 = (
		_get_player_aim_direction(
			player
		)
	)

	_release_carrier_reference()

	is_carried = false
	is_thrown = true

	throw_velocity = (
		direction
		* throw_speed
	)

	throw_timer = 0.0

	z_index = 25

	if not is_in_group(
		"bullet_blockers"
	):
		add_to_group(
			"bullet_blockers"
		)

	if not is_in_group(
		"destructibles"
	):
		add_to_group(
			"destructibles"
		)

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false


func _place_barrel() -> void:
	if not is_instance_valid(
		carried_by
	):
		return

	var player: Node2D = carried_by

	var direction: Vector2 = (
		_get_player_aim_direction(
			player
		)
	)

	var desired_position: Vector2 = (
		player.global_position
		+ direction * 38.0
	)

	var safe_position: Vector2 = (
		_find_safe_drop_position(
			player,
			desired_position
		)
	)

	_release_carrier_reference()

	is_carried = false
	is_thrown = false

	global_position = safe_position

	throw_velocity = Vector2.ZERO

	rotation = 0.0
	z_index = 6

	_restore_world_collision()

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false


func _find_safe_drop_position(
	player: Node2D,
	desired_position: Vector2
) -> Vector2:
	var scene: Node = (
		get_tree().current_scene
	)

	var direction: Vector2 = (
		desired_position
		- player.global_position
	)

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	var side := Vector2(
		-direction.y,
		direction.x
	)

	var candidates: Array[Vector2] = [
		desired_position,
		player.global_position
			+ direction * 30.0
			+ side * 22.0,
		player.global_position
			+ direction * 30.0
			- side * 22.0,
		player.global_position
			- direction * 34.0
	]

	for candidate in candidates:
		if not scene.has_method(
			"is_enemy_position_walkable"
		):
			return candidate

		var walkable: bool = bool(
			scene.call(
				"is_enemy_position_walkable",
				candidate,
				hit_radius
			)
		)

		if walkable:
			return candidate

	return desired_position


func _update_throw(
	delta: float
) -> void:
	throw_timer += delta

	var next_position: Vector2 = (
		global_position
		+ throw_velocity * delta
	)

	if _would_hit_world(
		next_position
	):
		_finish_throw()
		return

	global_position = next_position

	rotation += (
		delta * 11.0
	)

	if _check_thrown_enemy_hit():
		return

	throw_velocity = (
		throw_velocity.move_toward(
			Vector2.ZERO,
			throw_drag * delta
		)
	)

	if (
		throw_timer >= max_throw_time
		or throw_velocity.length() < 65.0
	):
		_finish_throw()


func _would_hit_world(
	next_position: Vector2
) -> bool:
	for blocker_value in get_tree().get_nodes_in_group(
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

		if not is_instance_valid(blocker):
			continue

		if blocker.has_method(
			"contains_projectile_point"
		):
			var hit: bool = bool(
				blocker.call(
					"contains_projectile_point",
					next_position,
					hit_radius
				)
			)

			if hit:
				if blocker.has_method(
					"take_damage"
				):
					blocker.call(
						"take_damage",
						1
					)

				return true

		else:
			var radius_value = blocker.get(
				"hit_radius"
			)

			if radius_value == null:
				continue

			var blocker_radius: float = float(
				radius_value
			)

			var combined_radius: float = (
				hit_radius
				+ blocker_radius
			)

			if next_position.distance_squared_to(
				blocker.global_position
			) <= (
				combined_radius
				* combined_radius
			):
				return true

	return false


func _check_thrown_enemy_hit() -> bool:
	for enemy_value in get_tree().get_nodes_in_group(
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

		if not is_instance_valid(enemy):
			continue

		if global_position.distance_to(
			enemy.global_position
		) > hit_radius + 14.0:
			continue

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				global_position
				- throw_velocity.normalized()
				* 15.0,
				220.0
			)

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				throw_impact_damage
			)

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

		if scene.has_method(
			"request_camera_shake"
		):
			scene.call(
				"request_camera_shake",
				4.0
			)

		if scene.has_method(
			"request_hit_stop"
		):
			scene.call(
				"request_hit_stop",
				0.04,
				0.12
			)

		_finish_throw()

		return true

	return false


func _finish_throw() -> void:
	is_thrown = false

	throw_velocity = Vector2.ZERO
	throw_timer = 0.0

	rotation = 0.0
	z_index = 6

	_restore_world_collision()


func _restore_world_collision() -> void:
	if not is_in_group(
		"bullet_blockers"
	):
		add_to_group(
			"bullet_blockers"
		)

	if not is_in_group(
		"destructibles"
	):
		add_to_group(
			"destructibles"
		)

	if is_instance_valid(
		collision_shape
	):
		collision_shape.set_deferred(
			"disabled",
			false
		)


func _release_carrier_reference() -> void:
	if not is_instance_valid(
		carried_by
	):
		carried_by = null
		return

	var carried_value = carried_by.get_meta(
		"carried_barrel",
		null
	)

	if carried_value == self:
		carried_by.remove_meta(
			"carried_barrel"
		)

	carried_by = null


func _exit_tree() -> void:
	_release_carrier_reference()


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	var local_point: Vector2 = to_local(
		global_point
	)

	var rect := Rect2(
		-collision_size * 0.5,
		collision_size
	)

	rect = rect.grow(
		projectile_radius
	)

	return rect.has_point(
		local_point
	)


func take_damage(amount: int) -> void:
	if is_carried:
		return

	if activated:
		return

	health -= maxi(
		1,
		amount
	)

	if health <= 0:
		_activate()


func _activate() -> void:
	if activated:
		return

	if is_carried:
		return

	activated = true
	fuse_timer = fuse_duration
	blink_timer = 0.0

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false

	queue_redraw()


func _explode() -> void:
	var scene: Node = get_tree().current_scene

	# Enemy + boss damage.
	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(enemy_value):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = enemy_value as Node2D

		if not is_instance_valid(enemy):
			continue

		var distance: float = global_position.distance_to(
			enemy.global_position
		)

		if distance > explosion_radius:
			continue

		if enemy.has_method("take_damage"):
			enemy.call(
				"take_damage",
				explosion_damage
			)

	# Player also takes damage.
	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if is_instance_valid(player_value):
		var player: Node2D = player_value as Node2D

		var player_distance: float = global_position.distance_to(
			player.global_position
		)

		if player_distance <= explosion_radius:
			if player.has_method("take_damage"):
				player.call(
					"take_damage",
					explosion_damage
				)

	# Destroy crates / pots and trigger nearby barrels.
	for prop_value in get_tree().get_nodes_in_group(
		"destructibles"
	):
		if not is_instance_valid(prop_value):
			continue

		if prop_value == self:
			continue

		if prop_value.is_queued_for_deletion():
			continue

		var prop: Node2D = prop_value as Node2D

		if not is_instance_valid(prop):
			continue

		var prop_distance: float = global_position.distance_to(
			prop.global_position
		)

		if prop_distance > explosion_radius:
			continue

		if prop.has_method("take_damage"):
			prop.call(
				"take_damage",
				explosion_damage
			)

	if scene.has_method(
		"notify_prop_destroyed"
	):
		scene.call(
			"notify_prop_destroyed",
			prop_id
		)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"explosion"
		)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			11.0
		)

	if scene.has_method(
		"request_hit_stop"
	):
		scene.call(
			"request_hit_stop",
			0.075,
			0.08
		)

	queue_free()


func _draw() -> void:
	draw_rect(
		Rect2(
			-12,
			11,
			24,
			5
		),
		Color8(
			8,
			8,
			12,
			150
		),
		true
	)

	var barrel_color := Color8(
		165,
		48,
		40
	)

	if activated:
		var blink_on: bool = (
			int(blink_timer * 18.0) % 2
			== 0
		)

		if blink_on:
			barrel_color = Color8(
				255,
				215,
				90
			)

	draw_rect(
		Rect2(
			-10,
			-14,
			20,
			28
		),
		barrel_color,
		true
	)

	draw_rect(
		Rect2(
			-11,
			-10,
			22,
			4
		),
		Color8(
			65,
			50,
			48
		),
		true
	)

	draw_rect(
		Rect2(
			-11,
			6,
			22,
			4
		),
		Color8(
			65,
			50,
			48
		),
		true
	)

	# Warning mark.
	draw_rect(
		Rect2(
			-2,
			-7,
			4,
			10
		),
		Color8(
			255,
			220,
			90
		),
		true
	)

	draw_rect(
		Rect2(
			-2,
			6,
			4,
			3
		),
		Color8(
			255,
			220,
			90
		),
		true
	)

	if activated:
		var fuse_progress: float = clampf(
			fuse_timer / fuse_duration,
			0.0,
			1.0
		)

		var ring_radius: float = lerpf(
			20.0,
			explosion_radius,
			1.0 - fuse_progress
		)

		draw_arc(
			Vector2.ZERO,
			ring_radius,
			0.0,
			TAU,
			32,
			Color(
				1.0,
				0.3,
				0.1,
				0.45
			),
			2.0
		)