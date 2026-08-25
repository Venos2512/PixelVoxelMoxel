extends Node2D


var controller: Node = null
var target: Node2D = null
var original_parent: Node = null

var travel_direction: Vector2 = Vector2.RIGHT
var travel_speed: float = 500.0
var remaining_distance: float = 100.0

var source_damage: int = 1
var knockback_force: float = 300.0
var charge_power: float = 0.0

var target_is_object: bool = false

var chain_depth: int = 0
var max_chain_depth: int = 3

var hit_enemy_ids: Dictionary = {}

var target_radius: float = 14.0

var original_rotation: float = 0.0
var original_scale: Vector2 = Vector2.ONE
var original_z_index: int = 0
var original_process_mode: int = 0

var spin_speed: float = 0.0

var finishing: bool = false


func setup(
	target_value: Node2D,
	controller_value: Node,
	direction_value: Vector2,
	distance_value: float,
	duration_value: float,
	damage_value: int,
	knockback_value: float,
	power_value: float,
	is_object_value: bool,
	chain_depth_value: int
) -> void:
	target = target_value
	controller = controller_value

	if not is_instance_valid(
		target
	):
		queue_free()
		return

	travel_direction = direction_value

	if travel_direction.length_squared() <= 0.001:
		travel_direction = Vector2.RIGHT

	travel_direction = (
		travel_direction.normalized()
	)

	remaining_distance = maxf(
		0.0,
		distance_value
	)

	var safe_duration: float = maxf(
		0.08,
		duration_value
	)

	travel_speed = (
		remaining_distance
		/ safe_duration
	)

	source_damage = damage_value
	knockback_force = knockback_value

	charge_power = clampf(
		power_value,
		0.0,
		1.0
	)

	target_is_object = is_object_value

	chain_depth = chain_depth_value

	target_radius = (
		_get_node_radius(
			target
		)
	)

	original_parent = target.get_parent()

	original_rotation = target.rotation
	original_scale = target.scale
	original_z_index = target.z_index
	original_process_mode = int(
		target.process_mode
	)

	global_position = (
		target.global_position
	)

	target.set_meta(
		"hammer_airborne",
		true
	)

	target.set_meta(
		"hammer_airborne_chain_depth",
		chain_depth
	)

	# Khóa hoàn toàn logic riêng của target trong lúc bay.
	# Điều này ngăn carryable prop / room prop tự kéo mình
	# trở lại vị trí cũ.
	target.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)

	target.z_index = (
		original_z_index + 20
	)

	target.reparent(
		self,
		true
	)

	# Carrier được đặt đúng tại vị trí target.
	# Sau reparent target phải nằm tương đối tại đây.
	target.global_position = global_position

	var spin_sign: float = 1.0

	if randf() < 0.5:
		spin_sign = -1.0

	spin_speed = (
		lerpf(
			4.0,
			14.0,
			charge_power
		)
		* spin_sign
	)

	if target_is_object:
		spin_speed *= 1.25


func _physics_process(
	delta: float
) -> void:
	if finishing:
		return

	if not is_instance_valid(
		target
	):
		queue_free()
		return

	var frame_distance: float = minf(
		travel_speed * delta,
		remaining_distance
	)

	if frame_distance <= 0.0:
		_finish_airborne(
			false
		)

		return

	var next_position: Vector2 = (
		global_position
		+ travel_direction
		* frame_distance
	)

	if _is_world_blocked(
		next_position
	):
		_finish_airborne(
			true
		)

		return

	global_position = next_position

	remaining_distance -= frame_distance

	target.rotation += (
		spin_speed * delta
	)

	_check_enemy_collision()

	if remaining_distance <= 0.01:
		_finish_airborne(
			false
		)


func _check_enemy_collision() -> void:
	if not is_instance_valid(
		target
	):
		return

	for enemy_value: Node in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		if enemy_value == target:
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		if bool(
			enemy.get_meta(
				"hammer_airborne",
				false
			)
		):
			continue

		var enemy_id: int = (
			enemy.get_instance_id()
		)

		if hit_enemy_ids.has(
			enemy_id
		):
			continue

		var enemy_radius: float = (
			_get_node_radius(
				enemy
			)
		)

		var combined_radius: float = (
			target_radius
			+ enemy_radius
			+ 5.0
		)

		if target.global_position.distance_squared_to(
			enemy.global_position
		) > (
			combined_radius
			* combined_radius
		):
			continue

		hit_enemy_ids[
			enemy_id
		] = true

		_on_enemy_impact(
			enemy
		)


func _on_enemy_impact(
	enemy: Node2D
) -> void:
	if not is_instance_valid(
		enemy
	):
		return

	var collision_damage: int = maxi(
		1,
		int(
			round(
				float(source_damage)
				* lerpf(
					0.30,
					0.55,
					charge_power
				)
			)
		)
	)

	var chain_force: float = (
		knockback_force
		* 0.58
	)

	# Mỗi va chạm làm vật đang bay mất một phần động lượng.
	travel_speed *= 0.78

	remaining_distance *= 0.88

	if (
		chain_depth < max_chain_depth
		and is_instance_valid(
			controller
		)
		and controller.has_method(
			"_hammer_chain_launch_target"
		)
	):
		controller.call(
			"_hammer_chain_launch_target",
			enemy,
			target.global_position,
			travel_direction,
			chain_force,
			collision_damage,
			charge_power,
			chain_depth + 1
		)

	else:
		# Đã đạt giới hạn chain:
		# vẫn gây damage + knockback bình thường.
		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				target.global_position
					- travel_direction
					* 20.0,
				chain_force
			)

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				collision_damage
			)


func _is_world_blocked(
	position_value: Vector2
) -> bool:
	for blocker_value: Node in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(
			blocker_value
		):
			continue

		if blocker_value == target:
			continue

		if blocker_value.is_queued_for_deletion():
			continue

		if not blocker_value.has_method(
			"contains_projectile_point"
		):
			continue

		if bool(
			blocker_value.call(
				"contains_projectile_point",
				position_value,
				target_radius
			)
		):
			return true

	return false


func _finish_airborne(
	hit_wall: bool
) -> void:
	if finishing:
		return

	finishing = true

	if not is_instance_valid(
		target
	):
		queue_free()
		return

	var landing_position: Vector2 = (
		target.global_position
	)

	var landing_rotation: float = (
		target.rotation
	)

	var new_parent: Node = (
		original_parent
	)

	if not is_instance_valid(
		new_parent
	):
		new_parent = (
			get_tree().current_scene
		)

	if is_instance_valid(
		new_parent
	):
		target.reparent(
			new_parent,
			true
		)

	target.global_position = (
		landing_position
	)

	target.rotation = (
		landing_rotation
	)

	target.scale = (
		original_scale
	)

	target.z_index = (
		original_z_index
	)

	# Với props có anchor/home position riêng,
	# cập nhật luôn vị trí nghỉ mới để chúng không snap-back.
	if target_is_object:
		_update_object_rest_position(
			target,
			landing_position
		)

	if hit_wall:
		var wall_bonus_damage: int = maxi(
			1,
			int(
				round(
					lerpf(
						1.0,
						4.0,
						charge_power
					)
				)
			)
		)

		source_damage += (
			wall_bonus_damage
		)

		if (
			is_instance_valid(
				controller
			)
			and controller.has_method(
				"_hammer_airborne_world_impact"
			)
		):
			controller.call(
				"_hammer_airborne_world_impact",
				landing_position,
				charge_power
			)

	# Damage chính của Hammer chỉ commit sau khi bay xong.
	# Lethal prop/enemy vì thế vỡ/chết tại vị trí landing,
	# không phải tại vị trí ban đầu.
	if target.has_method(
		"take_damage"
	):
		target.call(
			"take_damage",
			source_damage
		)

	if not is_instance_valid(
		target
	):
		queue_free()
		return

	if target.is_queued_for_deletion():
		queue_free()
		return

	target.rotation = (
		original_rotation
	)

	target.scale = (
		original_scale
	)

	target.z_index = (
		original_z_index
	)

	target.set_meta(
		"hammer_airborne",
		false
	)

	target.set_meta(
		"hammer_airborne_chain_depth",
		0
	)

	target.process_mode = (
		original_process_mode
	)

	# Xóa velocity cũ nếu là CharacterBody2D để enemy
	# không cộng thêm movement ngay sau khi landing.
	if target is CharacterBody2D:
		var body: CharacterBody2D = (
			target as CharacterBody2D
		)

		body.velocity = Vector2.ZERO

	queue_free()


func _update_object_rest_position(
	object_node: Node2D,
	position_value: Vector2
) -> void:
	var possible_properties: Array[String] = [
		"anchor_position",
		"home_position",
		"rest_position",
		"spawn_position"
	]

	for property_name: String in possible_properties:
		if not _has_property(
			object_node,
			property_name
		):
			continue

		var current_value: Variant = object_node.get(
			property_name
		)

		if typeof(
			current_value
		) != TYPE_VECTOR2:
			continue

		object_node.set(
			property_name,
			position_value
		)


func _get_node_radius(
	node: Node
) -> float:
	if _has_property(
		node,
		"hit_radius"
	):
		var radius_value: Variant = node.get(
			"hit_radius"
		)

		if (
			typeof(radius_value) == TYPE_FLOAT
			or typeof(radius_value) == TYPE_INT
		):
			return clampf(
				float(
					radius_value
				),
				7.0,
				34.0
			)

	return 14.0


func _has_property(
	target_value: Object,
	property_name: String
) -> bool:
	for property_data: Dictionary in target_value.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false