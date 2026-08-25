extends RefCounted

const MeleeAttackFxScript = preload(
	"res://gungeon_proto/melee_attack_fx.gd"
)

const Milestone14CombatScript = preload(
	"res://gungeon_proto/milestone14_combat.gd"
)


static func perform_attack(
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

	var style: String = _get_melee_style(
		weapon
	)

	var attack_range: float = float(
		weapon.get(
			"range",
			55.0
		)
	)

	var arc_deg: float = float(
		weapon.get(
			"arc_deg",
			90.0
		)
	)

	var damage: int = int(
		weapon.get(
			"damage",
			3
		)
	)

	var knockback: float = float(
		weapon.get(
			"knockback",
			_get_default_knockback(
				style
			)
		)
	)

	var hit_something: bool = false

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

		if not _target_is_inside_attack(
			player.global_position,
			enemy.global_position,
			direction,
			attack_range,
			arc_deg,
			style,
			14.0
		):
			continue

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				player.global_position,
				knockback
			)

		if enemy.has_method(
			"take_damage"
		):
			enemy.call(
				"take_damage",
				damage
			)

		# Milestone 14:
		# knockback mạnh về phía tường gây impact damage.
		Milestone14CombatScript.try_wall_slam(
			player,
			enemy,
			direction,
			knockback,
			style
		)

		hit_something = true

		_spawn_impact_fx(
			player,
			enemy.global_position
		)

	_hit_destructibles(
		player,
		direction,
		attack_range,
		arc_deg,
		style,
		damage
	)

	_spawn_attack_fx(
		player,
		direction,
		style,
		attack_range,
		arc_deg
	)

	_apply_lunge(
		player,
		direction,
		float(
			weapon.get(
				"lunge",
				0.0
			)
		)
	)

	if hit_something:
		_apply_gamefeel(
			player,
			style
		)


static func _get_melee_style(
	weapon: Dictionary
) -> String:
	var style: String = str(
		weapon.get(
			"melee_style",
			""
		)
	).to_lower()

	if not style.is_empty():
		return style

	var weapon_name: String = str(
		weapon.get(
			"name",
			""
		)
	).to_lower()

	if "spear" in weapon_name:
		return "thrust"

	if "hammer" in weapon_name:
		return "smash"

	return "slash"


static func _get_default_knockback(
	style: String
) -> float:
	match style:
		"thrust":
			return 135.0

		"smash":
			return 310.0

	return 165.0


static func _target_is_inside_attack(
	origin: Vector2,
	target_position: Vector2,
	direction: Vector2,
	attack_range: float,
	arc_deg: float,
	style: String,
	target_radius: float
) -> bool:
	var offset: Vector2 = (
		target_position - origin
	)

	var distance: float = offset.length()

	if distance <= 0.001:
		return true

	if distance > (
		attack_range
		+ target_radius
	):
		return false

	if style == "thrust":
		return _target_is_inside_thrust(
			offset,
			direction,
			attack_range,
			arc_deg,
			target_radius
		)

	return _target_is_inside_arc(
		offset,
		direction,
		arc_deg
	)


static func _target_is_inside_arc(
	offset: Vector2,
	direction: Vector2,
	arc_deg: float
) -> bool:
	var target_direction: Vector2 = (
		offset.normalized()
	)

	var dot_value: float = clampf(
		direction.dot(
			target_direction
		),
		-1.0,
		1.0
	)

	var angle: float = acos(
		dot_value
	)

	return angle <= deg_to_rad(
		arc_deg * 0.5
	)


static func _target_is_inside_thrust(
	offset: Vector2,
	direction: Vector2,
	attack_range: float,
	arc_deg: float,
	target_radius: float
) -> bool:
	var forward_distance: float = (
		offset.dot(
			direction
		)
	)

	if forward_distance < 0.0:
		return false

	if forward_distance > (
		attack_range
		+ target_radius
	):
		return false

	var side_direction: Vector2 = Vector2(
		-direction.y,
		direction.x
	)

	var lateral_distance: float = absf(
		offset.dot(
			side_direction
		)
	)

	var half_angle: float = deg_to_rad(
		arc_deg * 0.5
	)

	var allowed_width: float = (
		tan(
			half_angle
		)
		* maxf(
			12.0,
			forward_distance
		)
		+ target_radius
	)

	return lateral_distance <= allowed_width


static func _hit_destructibles(
	player: Node2D,
	direction: Vector2,
	attack_range: float,
	arc_deg: float,
	style: String,
	damage: int
) -> void:
	for object_value: Node in player.get_tree().get_nodes_in_group(
		"destructibles"
	):
		if not is_instance_valid(
			object_value
		):
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

		var carried_value: Variant = object_node.get(
			"is_carried"
		)

		if (
			carried_value != null
			and bool(carried_value)
		):
			continue

		var radius: float = 12.0

		var radius_value: Variant = object_node.get(
			"hit_radius"
		)

		if (
			radius_value != null
			and (
				typeof(radius_value) == TYPE_FLOAT
				or typeof(radius_value) == TYPE_INT
			)
		):
			radius = float(
				radius_value
			)

		if not _target_is_inside_attack(
			player.global_position,
			object_node.global_position,
			direction,
			attack_range,
			arc_deg,
			style,
			radius
		):
			continue

		if object_node.has_method(
			"take_damage"
		):
			object_node.call(
				"take_damage",
				damage
			)


static func _spawn_attack_fx(
	player: Node2D,
	direction: Vector2,
	style: String,
	attack_range: float,
	arc_deg: float
) -> void:
	var scene: Node = (
		player.get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var fx: Node2D = (
		MeleeAttackFxScript.new()
		as Node2D
	)

	if not is_instance_valid(
		fx
	):
		return

	fx.z_index = 35

	scene.add_child(
		fx
	)

	fx.global_position = (
		player.global_position
	)

	fx.call(
		"configure",
		style,
		attack_range,
		arc_deg,
		direction
	)


static func _spawn_impact_fx(
	player: Node2D,
	position: Vector2
) -> void:
	var scene: Node = (
		player.get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			position,
			"impact"
		)


static func _apply_lunge(
	player: Node2D,
	direction: Vector2,
	lunge_distance: float
) -> void:
	if lunge_distance <= 0.0:
		return

	var scene: Node = (
		player.get_tree().current_scene
	)

	var desired_position: Vector2 = (
		player.global_position
		+ direction * lunge_distance
	)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"is_enemy_position_walkable"
		)
	):
		var walkable: bool = bool(
			scene.call(
				"is_enemy_position_walkable",
				desired_position,
				11.0
			)
		)

		if not walkable:
			return

	player.global_position = desired_position


static func _apply_gamefeel(
	player: Node2D,
	style: String
) -> void:
	var scene: Node = (
		player.get_tree().current_scene
	)

	var shake_amount: float = 2.5
	var hit_stop_duration: float = 0.035
	var slow_scale: float = 0.14

	if style == "smash":
		shake_amount = 7.0
		hit_stop_duration = 0.070
		slow_scale = 0.08

	if player.has_method(
		"add_camera_shake"
	):
		player.call(
			"add_camera_shake",
			shake_amount
		)

	elif (
		is_instance_valid(scene)
		and scene.has_method(
			"request_camera_shake"
		)
	):
		scene.call(
			"request_camera_shake",
			shake_amount
		)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"request_hit_stop"
		)
	):
		scene.call(
			"request_hit_stop",
			hit_stop_duration,
			slow_scale
		)