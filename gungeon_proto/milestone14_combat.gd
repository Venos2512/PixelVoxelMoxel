extends RefCounted

const Milestone14FxScript = preload(
	"res://gungeon_proto/milestone14_fx.gd"
)


static func record_attack_tags(
	player: Node2D,
	weapon: Dictionary
) -> void:
	if not is_instance_valid(
		player
	):
		return

	var tags: Array[String] = (
		get_weapon_tags(
			weapon
		)
	)

	player.set_meta(
		"last_attack_synergy_tags",
		tags
	)


static func get_weapon_tags(
	weapon: Dictionary
) -> Array[String]:
	var result: Array[String] = []

	var raw_tags: Variant = weapon.get(
		"synergy_tags",
		[]
	)

	if typeof(
		raw_tags
	) == TYPE_ARRAY:
		var tag_array: Array = raw_tags

		for tag_value: Variant in tag_array:
			var tag: String = str(
				tag_value
			).to_lower()

			if (
				not tag.is_empty()
				and not result.has(
					tag
				)
			):
				result.append(
					tag
				)

	var style: String = str(
		weapon.get(
			"melee_style",
			""
		)
	).to_lower()

	if (
		not style.is_empty()
		and not result.has(
			style
		)
	):
		result.append(
			style
		)

	return result


static func has_weapon_tag(
	weapon: Dictionary,
	tag: String
) -> bool:
	return get_weapon_tags(
		weapon
	).has(
		tag.to_lower()
	)


static func try_sword_parry(
	player: Node2D,
	aim_direction: Vector2
) -> int:
	if not is_instance_valid(
		player
	):
		return 0

	var direction: Vector2 = aim_direction

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	var parry_range: float = 76.0
	var parry_half_arc: float = deg_to_rad(
		70.0
	)

	var parried_count: int = 0

	var bullets: Array[Node] = (
		player.get_tree().get_nodes_in_group(
			"enemy_bullets"
		)
	)

	for bullet_value: Node in bullets:
		if not is_instance_valid(
			bullet_value
		):
			continue

		if bullet_value.is_queued_for_deletion():
			continue

		var bullet: Node2D = (
			bullet_value as Node2D
		)

		if not is_instance_valid(
			bullet
		):
			continue

		var offset: Vector2 = (
			bullet.global_position
			- player.global_position
		)

		var distance: float = offset.length()

		if (
			distance <= 0.001
			or distance > parry_range
		):
			continue

		var bullet_direction: Vector2 = (
			offset / distance
		)

		var dot_value: float = clampf(
			direction.dot(
				bullet_direction
			),
			-1.0,
			1.0
		)

		var angle: float = acos(
			dot_value
		)

		if angle > parry_half_arc:
			continue

		var reflected_direction: Vector2 = (
			bullet.global_position
			- player.global_position
		)

		if reflected_direction.length_squared() <= 0.001:
			reflected_direction = direction

		reflected_direction = (
			reflected_direction.normalized()
		)

		if bullet.has_method(
			"reflect"
		):
			bullet.call(
				"reflect",
				reflected_direction
			)

		else:
			# Projectile cũ chưa hỗ trợ reflect:
			# vẫn được Sword parry và hủy an toàn.
			bullet.queue_free()

		parried_count += 1

	if parried_count > 0:
		_spawn_fx(
			player,
			player.global_position,
			"parry",
			direction,
			parry_range
		)

		_request_gamefeel(
			player,
			4.0,
			0.045,
			0.10
		)

	return parried_count


static func hammer_shockwave(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2
) -> void:
	if not is_instance_valid(
		player
	):
		return

	var direction: Vector2 = aim_direction

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	var attack_range: float = float(
		weapon.get(
			"range",
			48.0
		)
	)

	var impact_center: Vector2 = (
		player.global_position
		+ direction
		* attack_range
		* 0.75
	)

	var shock_radius: float = maxf(
		68.0,
		attack_range * 1.45
	)

	var shock_damage: int = 1
	var shock_knockback: float = 190.0

	var hit_count: int = 0

	for enemy_value: Node in player.get_tree().get_nodes_in_group(
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

		if enemy.global_position.distance_squared_to(
			impact_center
		) > (
			shock_radius
			* shock_radius
		):
			continue

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				impact_center,
				shock_knockback
			)

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				shock_damage
			)

		var launch_direction: Vector2 = (
			enemy.global_position
			- impact_center
		)

		if launch_direction.length_squared() <= 0.001:
			launch_direction = direction

		try_wall_slam(
			player,
			enemy,
			launch_direction.normalized(),
			shock_knockback,
			"smash"
		)

		hit_count += 1

	_spawn_fx(
		player,
		impact_center,
		"shockwave",
		direction,
		shock_radius
	)

	_request_gamefeel(
		player,
		6.5,
		0.060,
		0.08
	)


static func try_wall_slam(
	player: Node2D,
	enemy: Node2D,
	launch_direction: Vector2,
	knockback_force: float,
	attack_style: String
) -> bool:
	if (
		not is_instance_valid(
			player
		)
		or not is_instance_valid(
			enemy
		)
	):
		return false

	var direction: Vector2 = launch_direction

	if direction.length_squared() <= 0.001:
		return false

	direction = direction.normalized()

	var probe_distance: float = clampf(
		knockback_force * 0.24,
		28.0,
		92.0
	)

	var desired_position: Vector2 = (
		enemy.global_position
		+ direction * probe_distance
	)

	if _is_position_walkable(
		player,
		desired_position
	):
		return false

	var wall_damage: int = 1

	if attack_style == "smash":
		wall_damage = 3

	elif attack_style == "thrust":
		wall_damage = 2

	if enemy.has_method(
		"take_damage"
	):
		enemy.call(
			"take_damage",
			wall_damage
		)

	enemy.set_meta(
		"milestone14_last_wall_slam",
		Time.get_ticks_msec()
	)

	_spawn_fx(
		player,
		enemy.global_position,
		"wall_slam",
		direction,
		30.0
	)

	_request_gamefeel(
		player,
		5.0,
		0.050,
		0.09
	)

	return true


static func _is_position_walkable(
	player: Node2D,
	position_value: Vector2
) -> bool:
	var scene: Node = (
		player.get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return true

	if scene.has_method(
		"is_enemy_position_walkable"
	):
		var arg_count: int = (
			_get_method_argument_count(
				scene,
				"is_enemy_position_walkable"
			)
		)

		if arg_count >= 2:
			return bool(
				scene.call(
					"is_enemy_position_walkable",
					position_value,
					13.0
				)
			)

		if arg_count == 1:
			return bool(
				scene.call(
					"is_enemy_position_walkable",
					position_value
				)
			)

	if _has_property(
		scene,
		"room_navigation"
	):
		var navigation_value: Variant = scene.get(
			"room_navigation"
		)

		if (
			typeof(navigation_value) == TYPE_OBJECT
			and is_instance_valid(
				navigation_value
			)
		):
			var navigation: Object = (
				navigation_value as Object
			)

			if navigation.has_method(
				"is_position_walkable"
			):
				var nav_arg_count: int = (
					_get_method_argument_count(
						navigation,
						"is_position_walkable"
					)
				)

				if nav_arg_count >= 2:
					return bool(
						navigation.call(
							"is_position_walkable",
							position_value,
							13.0
						)
					)

				if nav_arg_count == 1:
					return bool(
						navigation.call(
							"is_position_walkable",
							position_value
						)
					)

	return true


static func _spawn_fx(
	player: Node2D,
	position_value: Vector2,
	effect_type: String,
	direction: Vector2,
	radius: float
) -> void:
	var scene: Node = (
		player.get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var fx: Node2D = (
		Milestone14FxScript.new()
		as Node2D
	)

	if not is_instance_valid(
		fx
	):
		return

	fx.z_index = 50

	scene.add_child(
		fx
	)

	fx.global_position = position_value

	fx.call(
		"configure",
		effect_type,
		direction,
		radius
	)


static func _request_gamefeel(
	player: Node2D,
	shake_amount: float,
	hit_stop_duration: float,
	slow_scale: float
) -> void:
	var scene: Node = (
		player.get_tree().current_scene
	)

	if player.has_method(
		"add_camera_shake"
	):
		player.call(
			"add_camera_shake",
			shake_amount
		)

	elif (
		is_instance_valid(
			scene
		)
		and scene.has_method(
			"request_camera_shake"
		)
	):
		scene.call(
			"request_camera_shake",
			shake_amount
		)

	if (
		is_instance_valid(
			scene
		)
		and scene.has_method(
			"request_hit_stop"
		)
	):
		scene.call(
			"request_hit_stop",
			hit_stop_duration,
			slow_scale
		)


static func _get_method_argument_count(
	target: Object,
	method_name: String
) -> int:
	for method_data: Dictionary in target.get_method_list():
		if str(
			method_data.get(
				"name",
				""
			)
		) != method_name:
			continue

		var args_value: Variant = method_data.get(
			"args",
			[]
		)

		if typeof(
			args_value
		) != TYPE_ARRAY:
			return -1

		var args: Array = args_value

		return args.size()

	return -1


static func _has_property(
	target: Object,
	property_name: String
) -> bool:
	for property_data: Dictionary in target.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false