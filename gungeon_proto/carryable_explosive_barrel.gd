extends StaticBody2D

var prop_id: String = ""

var health: int = 1

var hit_radius: float = 15.0

var collision_size := Vector2(
	22,
	28
)

var interaction_radius: float = 44.0

var activated: bool = false

var fuse_duration: float = 0.32
var fuse_timer: float = 0.0

var thrown_fuse_duration: float = 0.16

var explosion_radius: float = 95.0
var explosion_damage: int = 4

var blink_timer: float = 0.0

var is_carried: bool = false
var is_thrown: bool = false

var carried_by: Node2D = null

var throw_velocity := Vector2.ZERO

var throw_speed: float = 455.0

var e_key_was_down: bool = false
var q_key_was_down: bool = false

var collision_shape: CollisionShape2D
var prompt_label: Label


func _ready() -> void:
	z_index = 6

	add_to_group("room_props")
	add_to_group("bullet_blockers")
	add_to_group("destructibles")

	add_to_group(
		"explosive_barrels"
	)

	add_to_group(
		"carryable_objects"
	)

	collision_shape = CollisionShape2D.new()

	var shape := RectangleShape2D.new()

	shape.size = collision_size

	collision_shape.shape = shape

	add_child(
		collision_shape
	)

	_create_prompt()

	queue_redraw()


func _create_prompt() -> void:
	prompt_label = Label.new()

	prompt_label.position = Vector2(
		-70,
		-44
	)

	prompt_label.size = Vector2(
		140,
		26
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

	add_child(
		prompt_label
	)


func _process(delta: float) -> void:
	var e_down: bool = Input.is_key_pressed(
		KEY_E
	)

	var q_down: bool = Input.is_key_pressed(
		KEY_Q
	)

	if is_carried:
		_update_carried()

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

		_update_fuse(
			delta
		)

		e_key_was_down = e_down
		q_key_was_down = q_down

		queue_redraw()

		return

	if is_thrown:
		_update_thrown(
			delta
		)

		_update_fuse(
			delta
		)

		e_key_was_down = e_down
		q_key_was_down = q_down

		queue_redraw()

		return

	_update_prompt()

	if (
		not activated
		and e_down
		and not e_key_was_down
		and _can_pick_up()
	):
		_pick_up()

	_update_fuse(
		delta
	)

	e_key_was_down = e_down
	q_key_was_down = q_down


func _update_fuse(
	delta: float
) -> void:
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


func _get_aim_direction(
	player: Node2D
) -> Vector2:
	var aim_value = player.get(
		"aim_direction"
	)

	if typeof(aim_value) == TYPE_VECTOR2:
		var aim_direction: Vector2 = aim_value

		if aim_direction.length_squared() > 0.001:
			return aim_direction.normalized()

	var mouse_direction: Vector2 = (
		get_global_mouse_position()
		- player.global_position
	)

	if mouse_direction.length_squared() > 0.001:
		return mouse_direction.normalized()

	return Vector2.RIGHT


func _player_has_carried_object(
	player: Node2D
) -> bool:
	var value = player.get_meta(
		"carried_object",
		null
	)

	if value == null:
		return false

	return is_instance_valid(
		value
	)


func _is_nearest_carryable(
	player: Node2D
) -> bool:
	var my_distance: float = (
		global_position.distance_squared_to(
			player.global_position
		)
	)

	for object_value in get_tree().get_nodes_in_group(
		"carryable_objects"
	):
		if not is_instance_valid(
			object_value
		):
			continue

		if object_value == self:
			continue

		if object_value.is_queued_for_deletion():
			continue

		var object_node: Node2D = (
			object_value as Node2D
		)

		if not is_instance_valid(
			object_node
		):
			continue

		var other_carried = object_node.get(
			"is_carried"
		)

		if (
			other_carried != null
			and bool(other_carried)
		):
			continue

		var other_thrown = object_node.get(
			"is_thrown"
		)

		if (
			other_thrown != null
			and bool(other_thrown)
		):
			continue

		var distance: float = (
			object_node.global_position.distance_squared_to(
				player.global_position
			)
		)

		if distance < my_distance:
			return false

	return true


func _can_pick_up() -> bool:
	if activated:
		return false

	if is_carried:
		return false

	if is_thrown:
		return false

	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return false

	if _player_has_carried_object(
		player
	):
		return false

	if global_position.distance_to(
		player.global_position
	) > interaction_radius:
		return false

	return _is_nearest_carryable(
		player
	)


func _update_prompt() -> void:
	if not is_instance_valid(
		prompt_label
	):
		return

	prompt_label.visible = false

	if activated:
		return

	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	if _player_has_carried_object(
		player
	):
		return

	if global_position.distance_to(
		player.global_position
	) > interaction_radius:
		return

	if not _is_nearest_carryable(
		player
	):
		return

	prompt_label.text = "[E] PICK UP"
	prompt_label.visible = true


func _pick_up() -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	is_carried = true
	is_thrown = false

	carried_by = player

	throw_velocity = Vector2.ZERO

	rotation = 0.0
	z_index = 25

	player.set_meta(
		"carried_object",
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

	add_to_group(
		"carried_explosives"
	)

	if is_instance_valid(
		collision_shape
	):
		collision_shape.set_deferred(
			"disabled",
			true
		)

	_update_carried()


func _update_carried() -> void:
	if not is_instance_valid(
		carried_by
	):
		_release_carrier()

		return

	var direction: Vector2 = (
		_get_aim_direction(
			carried_by
		)
	)

	global_position = (
		carried_by.global_position
		+ direction * 31.0
		+ Vector2(
			0,
			-14
		)
	)

	rotation = 0.0

	if is_instance_valid(
		prompt_label
	):
		if activated:
			prompt_label.text = (
				"!!! LIVE !!!  [E] THROW  [Q] DROP"
			)

		else:
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
		_get_aim_direction(
			player
		)
	)

	_release_carrier()

	is_carried = false
	is_thrown = true

	throw_velocity = (
		direction
		* throw_speed
	)

	z_index = 25

	if is_in_group(
		"carried_explosives"
	):
		remove_from_group(
			"carried_explosives"
		)

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

	if not activated:
		_activate(
			thrown_fuse_duration
		)

	else:
		fuse_timer = minf(
			fuse_timer,
			thrown_fuse_duration
		)


func _place_barrel() -> void:
	if not is_instance_valid(
		carried_by
	):
		return

	var player: Node2D = carried_by

	var direction: Vector2 = (
		_get_aim_direction(
			player
		)
	)

	var desired_position: Vector2 = (
		player.global_position
		+ direction * 45.0
	)

	var safe_position: Vector2 = (
		_find_safe_place_position(
			player,
			desired_position
		)
	)

	_release_carrier()

	is_carried = false
	is_thrown = false

	global_position = safe_position

	throw_velocity = Vector2.ZERO

	rotation = 0.0
	z_index = 6

	if is_in_group(
		"carried_explosives"
	):
		remove_from_group(
			"carried_explosives"
		)

	_restore_world_state()

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false


func _find_safe_place_position(
	player: Node2D,
	desired_position: Vector2
) -> Vector2:
	var scene: Node = (
		get_tree().current_scene
	)

	if not scene.has_method(
		"is_enemy_position_walkable"
	):
		return desired_position

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
			+ direction * 38.0
			+ side * 26.0,

		player.global_position
			+ direction * 38.0
			- side * 26.0,

		player.global_position
			- direction * 38.0
	]

	for candidate in candidates:
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


func _update_thrown(
	delta: float
) -> void:
	if not is_thrown:
		return

	var next_position: Vector2 = (
		global_position
		+ throw_velocity * delta
	)

	if _check_enemy_impact(
		next_position
	):
		return

	if _check_world_impact(
		next_position
	):
		_explode()

		return

	global_position = next_position

	rotation += (
		12.0 * delta
	)


func _check_enemy_impact(
	next_position: Vector2
) -> bool:
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

		if not is_instance_valid(
			enemy
		):
			continue

		var collision_radius: float = (
			hit_radius + 15.0
		)

		if next_position.distance_squared_to(
			enemy.global_position
		) > (
			collision_radius
			* collision_radius
		):
			continue

		_explode()

		return true

	return false


func _check_world_impact(
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
					next_position,
					hit_radius
				)
			)

		else:
			var radius_value = blocker.get(
				"hit_radius"
			)

			if radius_value != null:
				var blocker_radius: float = float(
					radius_value
				)

				var combined_radius: float = (
					hit_radius
					+ blocker_radius
				)

				hit = (
					next_position.distance_squared_to(
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
				explosion_damage
			)

		return true

	return false


func _activate(
	duration: float = -1.0
) -> void:
	if activated:
		return

	activated = true
	blink_timer = 0.0

	if duration > 0.0:
		fuse_timer = duration

	else:
		fuse_timer = fuse_duration

	queue_redraw()


func take_damage(
	_amount: int
) -> void:
	if activated:
		return

	# Đặc biệt:
	# barrel đang trên tay vẫn có thể bị enemy bullet kích nổ.
	_activate()


func trigger_from_enemy_bullet() -> void:
	if not activated:
		_activate()


func _explode() -> void:
	if is_queued_for_deletion():
		return

	var explosion_position: Vector2 = (
		global_position
	)

	_release_carrier()

	is_carried = false
	is_thrown = false

	if is_in_group(
		"carried_explosives"
	):
		remove_from_group(
			"carried_explosives"
		)

	var scene: Node = (
		get_tree().current_scene
	)

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

		if not is_instance_valid(
			enemy
		):
			continue

		var distance: float = (
			explosion_position.distance_to(
				enemy.global_position
			)
		)

		if distance > explosion_radius:
			continue

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				explosion_position,
				280.0
			)

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				explosion_damage
			)

	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if is_instance_valid(
		player_value
	):
		var player: Node2D = (
			player_value as Node2D
		)

		if is_instance_valid(
			player
		):
			var player_distance: float = (
				explosion_position.distance_to(
					player.global_position
				)
			)

			if player_distance <= explosion_radius:
				if player.has_method(
					"take_damage"
				):
					player.call(
						"take_damage",
						explosion_damage
					)

	for prop_value in get_tree().get_nodes_in_group(
		"destructibles"
	):
		if not is_instance_valid(
			prop_value
		):
			continue

		if prop_value == self:
			continue

		if prop_value.is_queued_for_deletion():
			continue

		var prop: Node2D = (
			prop_value as Node2D
		)

		if not is_instance_valid(
			prop
		):
			continue

		var prop_distance: float = (
			explosion_position.distance_to(
				prop.global_position
			)
		)

		if prop_distance > explosion_radius:
			continue

		if prop.has_method(
			"take_damage"
		):
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
			explosion_position,
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


func _restore_world_state() -> void:
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


func _release_carrier() -> void:
	if not is_instance_valid(
		carried_by
	):
		carried_by = null

		return

	var value = carried_by.get_meta(
		"carried_object",
		null
	)

	if value == self:
		carried_by.remove_meta(
			"carried_object"
		)

	carried_by = null


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	if is_carried:
		return false

	var local_point: Vector2 = (
		to_local(
			global_point
		)
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


func _exit_tree() -> void:
	_release_carrier()


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
			int(
				blink_timer * 20.0
			) % 2
			== 0
		)

		if blink_on:
			barrel_color = Color8(
				255,
				215,
				70
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
			fuse_timer
			/ maxf(
				0.001,
				fuse_duration
			),
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
				0.22,
				0.08,
				0.45
			),
			2.0
		)