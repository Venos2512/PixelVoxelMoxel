extends Node

const ProgressScript = preload(
	"res://gungeon_proto/weapon_special_progress.gd"
)

const HammerSpinFxScript = preload(
	"res://gungeon_proto/hammer_spin_fx.gd"
)

const HammerAirborneActorScript = preload(
	"res://gungeon_proto/hammer_airborne_actor.gd"
)

const SpearProjectileScript = preload(
	"res://gungeon_proto/spear_special_projectile.gd"
)

const ParryCounterProjectileScript = preload(
	"res://gungeon_proto/parry_counter_projectile.gd"
)

const Milestone14FxScript = preload(
	"res://gungeon_proto/milestone14_fx.gd"
)


const PARRY_WINDOW: float = 0.16
const PARRY_MISS_PENALTY: float = 0.75

const SPEAR_MAX_CHARGE: float = 1.35

const HAMMER_MAX_CHARGE: float = 1.50


var player: Node2D = null

var progress_bar: Node2D = null
var hammer_spin_fx: Node2D = null

var rmb_was_down: bool = false

var active_weapon_id: String = ""

var parry_active: bool = false
var parry_timer: float = 0.0
var parry_penalty_timer: float = 0.0

var spear_charging: bool = false
var spear_charge_time: float = 0.0

var hammer_charging: bool = false
var hammer_charge_time: float = 0.0


func _ready() -> void:
	call_deferred(
		"_find_player"
	)


func _process(
	delta: float
) -> void:
	if not is_instance_valid(
		player
	):
		_find_player()

		if not is_instance_valid(
			player
		):
			return

	parry_penalty_timer = maxf(
		0.0,
		parry_penalty_timer - delta
	)

	var weapon: Dictionary = (
		_get_current_weapon()
	)

	if weapon.is_empty():
		_cancel_special()
		return

	var weapon_id: String = (
		_get_special_weapon_id(
			weapon
		)
	)

	if (
		not active_weapon_id.is_empty()
		and weapon_id != active_weapon_id
	):
		_cancel_special()

	active_weapon_id = weapon_id

	var rmb_down: bool = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_RIGHT
		)
	)

	var rmb_pressed: bool = (
		rmb_down
		and not rmb_was_down
	)

	var rmb_released: bool = (
		not rmb_down
		and rmb_was_down
	)

	if parry_active:
		_update_parry(
			delta
		)

	match weapon_id:
		"sword":
			if (
				rmb_pressed
				and not parry_active
				and parry_penalty_timer <= 0.0
			):
				_start_parry()

		"spear":
			if rmb_pressed:
				_start_spear_charge()

			if spear_charging:
				_update_spear_charge(
					delta
				)

			if (
				rmb_released
				and spear_charging
			):
				_release_spear()

		"hammer":
			if rmb_pressed:
				_start_hammer_charge()

			if hammer_charging:
				_update_hammer_charge(
					delta
				)

			if (
				rmb_released
				and hammer_charging
			):
				_release_hammer()

	rmb_was_down = rmb_down


func _find_player() -> void:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return

	player = (
		player_value as Node2D
	)

	if not is_instance_valid(
		player
	):
		return

	_create_helper_nodes()


func _create_helper_nodes() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	if not is_instance_valid(
		progress_bar
	):
		progress_bar = (
			ProgressScript.new()
			as Node2D
		)

		scene.add_child(
			progress_bar
		)

		progress_bar.call(
			"set_target",
			player
		)

	if not is_instance_valid(
		hammer_spin_fx
	):
		hammer_spin_fx = (
			HammerSpinFxScript.new()
			as Node2D
		)

		scene.add_child(
			hammer_spin_fx
		)

		hammer_spin_fx.call(
			"set_target",
			player
		)


func _get_current_weapon() -> Dictionary:
	var weapon_system: Object = (
		_get_weapon_system()
	)

	if not is_instance_valid(
		weapon_system
	):
		return {}

	if not weapon_system.has_method(
		"get_current_weapon"
	):
		return {}

	var weapon_value: Variant = (
		weapon_system.call(
			"get_current_weapon"
		)
	)

	if typeof(
		weapon_value
	) != TYPE_DICTIONARY:
		return {}

	return weapon_value as Dictionary


func _get_special_weapon_id(
	weapon: Dictionary
) -> String:
	var weapon_name: String = str(
		weapon.get(
			"name",
			""
		)
	).to_lower()

	var style: String = str(
		weapon.get(
			"melee_style",
			""
		)
	).to_lower()

	if (
		"sword" in weapon_name
		or style == "slash"
	):
		return "sword"

	if (
		"spear" in weapon_name
		or style == "thrust"
	):
		return "spear"

	if (
		"hammer" in weapon_name
		or style == "smash"
	):
		return "hammer"

	return ""


func _start_parry() -> void:
	parry_active = true
	parry_timer = PARRY_WINDOW

	_block_normal_attack(
		PARRY_WINDOW
	)

	_spawn_fx(
		"parry",
		player.global_position,
		_get_aim_direction(),
		72.0
	)


func _update_parry(
	delta: float
) -> void:
	if _try_parry_bullets():
		parry_active = false
		parry_timer = 0.0

		# Parry thành công:
		# không cooldown, không recovery.
		parry_penalty_timer = 0.0

		return

	parry_timer -= delta

	if parry_timer > 0.0:
		return

	parry_active = false
	parry_timer = 0.0

	# Parry hụt = recovery 0.75 giây.
	parry_penalty_timer = (
		PARRY_MISS_PENALTY
	)

	_block_normal_attack(
		PARRY_MISS_PENALTY
	)


func _try_parry_bullets() -> bool:
	var aim: Vector2 = (
		_get_aim_direction()
	)

	var range_value: float = 78.0
	var half_arc: float = deg_to_rad(
		72.0
	)

	var parried: int = 0

	for bullet_value: Node in get_tree().get_nodes_in_group(
		"enemy_bullets"
	):
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

		var distance: float = (
			offset.length()
		)

		if (
			distance <= 0.001
			or distance > range_value
		):
			continue

		var bullet_direction: Vector2 = (
			offset / distance
		)

		var dot_value: float = clampf(
			aim.dot(
				bullet_direction
			),
			-1.0,
			1.0
		)

		if acos(
			dot_value
		) > half_arc:
			continue

		var counter_direction: Vector2 = (
			bullet_direction
		)

		if bullet.has_method(
			"reflect"
		):
			bullet.call(
				"reflect",
				counter_direction
			)

		else:
			var bullet_position: Vector2 = (
				bullet.global_position
			)

			bullet.queue_free()

			_spawn_counter_projectile(
				bullet_position,
				counter_direction
			)

		parried += 1

	if parried <= 0:
		return false

	_spawn_fx(
		"parry",
		player.global_position,
		aim,
		88.0
	)

	_request_gamefeel(
		4.5,
		0.045,
		0.10
	)

	return true


func _spawn_counter_projectile(
	position_value: Vector2,
	direction: Vector2
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var projectile: Node2D = (
		ParryCounterProjectileScript.new()
		as Node2D
	)

	scene.add_child(
		projectile
	)

	projectile.call(
		"configure",
		position_value,
		direction
	)


func _start_spear_charge() -> void:
	spear_charging = true
	spear_charge_time = 0.0

	_show_progress(
		0.0
	)


func _update_spear_charge(
	delta: float
) -> void:
	spear_charge_time = minf(
		SPEAR_MAX_CHARGE,
		spear_charge_time + delta
	)

	var progress: float = (
		spear_charge_time
		/ SPEAR_MAX_CHARGE
	)

	_show_progress(
		progress
	)

	_block_normal_attack(
		0.08
	)


func _release_spear() -> void:
	spear_charging = false

	var progress: float = clampf(
		spear_charge_time
		/ SPEAR_MAX_CHARGE,
		0.0,
		1.0
	)

	_hide_progress()

	var power: float = float(
		pow(
			progress,
			0.72
		)
	)

	var throw_distance: float = lerpf(
		110.0,
		430.0,
		power
	)

	var damage_value: int = int(
		round(
			lerpf(
				4.0,
				8.0,
				power
			)
		)
	)

	var knockback_value: float = lerpf(
		110.0,
		260.0,
		power
	)

	var direction: Vector2 = (
		_get_aim_direction()
	)

	var scene: Node = (
		get_tree().current_scene
	)

	var spear: Node2D = (
		SpearProjectileScript.new()
		as Node2D
	)

	scene.add_child(
		spear
	)

	spear.global_position = (
		player.global_position
		+ direction * 25.0
	)

	spear.call(
		"configure",
		direction,
		throw_distance,
		damage_value,
		knockback_value
	)

	_block_normal_attack(
		0.20
	)

	spear_charge_time = 0.0


func _start_hammer_charge() -> void:
	hammer_charging = true
	hammer_charge_time = 0.0

	_show_progress(
		0.0
	)

	if is_instance_valid(
		hammer_spin_fx
	):
		hammer_spin_fx.call(
			"set_active",
			true
		)


func _update_hammer_charge(
	delta: float
) -> void:
	hammer_charge_time = minf(
		HAMMER_MAX_CHARGE,
		hammer_charge_time + delta
	)

	var progress: float = (
		hammer_charge_time
		/ HAMMER_MAX_CHARGE
	)

	_show_progress(
		progress
	)

	if is_instance_valid(
		hammer_spin_fx
	):
		hammer_spin_fx.call(
			"set_charge",
			progress
		)

	_block_normal_attack(
		0.08
	)


func _release_hammer() -> void:
	hammer_charging = false

	if is_instance_valid(
		hammer_spin_fx
	):
		hammer_spin_fx.call(
			"set_active",
			false
		)

	_hide_progress()

	var progress: float = clampf(
		hammer_charge_time
		/ HAMMER_MAX_CHARGE,
		0.0,
		1.0
	)

	var power: float = float(
		pow(
			progress,
			0.70
		)
	)

	var damage_value: int = int(
		round(
			lerpf(
				8.0,
				16.0,
				power
			)
		)
	)

	var base_knockback: float = lerpf(
		360.0,
		1100.0,
		power
	)

	var attack_range: float = lerpf(
		72.0,
		92.0,
		power
	)

	var attack_arc: float = deg_to_rad(
		75.0
	)

	var direction: Vector2 = (
		_get_aim_direction()
	)

	var hammer_hit_ids: Dictionary = {}

	# Enemy.
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

		if not _is_inside_hammer_special(
			enemy,
			direction,
			attack_range,
			attack_arc
		):
			continue

		var enemy_id: int = (
			enemy.get_instance_id()
		)

		hammer_hit_ids[
			enemy_id
		] = true

		var knockback_multiplier: float = (
			_get_enemy_knockback_multiplier(
				enemy
			)
		)

		_hammer_launch_target_v2(
			enemy,
			damage_value,
			base_knockback
				* knockback_multiplier,
			power,
			false
		)

	# Props / barrel / crate / table...
	# Project hiện có nhiều loại prop dùng group/script khác nhau,
	# nên gom toàn bộ object có thể bị Hammer tác động trước.
	var hammer_objects: Array[Node2D] = (
		_get_hammer_object_candidates()
	)

	for object_node: Node2D in hammer_objects:
		if not is_instance_valid(
			object_node
		):
			continue

		if object_node.is_queued_for_deletion():
			continue

		var object_id: int = (
			object_node.get_instance_id()
		)

		# Tránh hit hai lần nếu object xuất hiện ở nhiều group.
		if hammer_hit_ids.has(
			object_id
		):
			continue

		if bool(
			object_node.get_meta(
				"hammer_airborne",
				false
			)
		):
			continue

		if _is_object_currently_carried(
			object_node
		):
			continue

		if not _is_inside_hammer_special(
			object_node,
			direction,
			attack_range,
			attack_arc
		):
			continue

		var object_multiplier: float = (
			_get_object_knockback_multiplier(
				object_node
			)
		)

		# Pillar / object cố định trả về 0.
		if object_multiplier <= 0.0:
			continue

		hammer_hit_ids[
			object_id
		] = true

		_hammer_launch_target_v2(
			object_node,
			damage_value,
			base_knockback
				* object_multiplier,
			power,
			true
		)

	_spawn_fx(
		"shockwave",
		player.global_position
			+ direction
			* 45.0,
		direction,
		attack_range + 18.0
	)

	_request_gamefeel(
		lerpf(
			5.0,
			10.0,
			power
		),
		lerpf(
			0.045,
			0.10,
			power
		),
		0.07
	)

	_block_normal_attack(
		lerpf(
			0.25,
			0.46,
			power
		)
	)

	hammer_charge_time = 0.0


func _get_hammer_object_candidates() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var known_ids: Dictionary = {}

	var group_names: Array[String] = [
		"destructibles",
		"room_props",
		"carryable_props",
		"carryable_objects",
		"explosive_barrels",
		"barrels"
	]

	for group_name: String in group_names:
		for value: Node in get_tree().get_nodes_in_group(
			group_name
		):
			if not is_instance_valid(
				value
			):
				continue

			var node_2d: Node2D = (
				value as Node2D
			)

			if not is_instance_valid(
				node_2d
			):
				continue

			var instance_id: int = (
				node_2d.get_instance_id()
			)

			if known_ids.has(
				instance_id
			):
				continue

			if not _is_hammer_prop_candidate(
				node_2d
			):
				continue

			known_ids[
				instance_id
			] = true

			result.append(
				node_2d
			)

	# Fallback:
	# một số prop cũ chưa add group nhưng dùng đúng các script
	# room_prop / carryable_prop / barrel của project.
	var scene: Node = (
		get_tree().current_scene
	)

	if is_instance_valid(
		scene
	):
		_collect_hammer_objects_recursive(
			scene,
			result,
			known_ids
		)

	return result


func _collect_hammer_objects_recursive(
	parent: Node,
	result: Array[Node2D],
	known_ids: Dictionary
) -> void:
	for child: Node in parent.get_children():
		_collect_hammer_objects_recursive(
			child,
			result,
			known_ids
		)

	if not parent is Node2D:
		return

	var node_2d: Node2D = (
		parent as Node2D
	)

	if not is_instance_valid(
		node_2d
	):
		return

	var instance_id: int = (
		node_2d.get_instance_id()
	)

	if known_ids.has(
		instance_id
	):
		return

	if not _is_hammer_prop_candidate(
		node_2d
	):
		return

	known_ids[
		instance_id
	] = true

	result.append(
		node_2d
	)


func _is_hammer_prop_candidate(
	target: Node2D
) -> bool:
	if target.is_in_group(
		"enemies"
	):
		return false

	if target.is_in_group(
		"player"
	):
		return false

	var script_value: Variant = (
		target.get_script()
	)

	var script_path: String = ""

	if (
		typeof(script_value) == TYPE_OBJECT
		and is_instance_valid(
			script_value
		)
	):
		var script: Script = (
			script_value as Script
		)

		script_path = (
			script.resource_path.to_lower()
		)

	var name_text: String = (
		target.name.to_lower()
	)

	var searchable: String = (
		name_text
		+ " "
		+ script_path
	)

	var valid_tokens: Array[String] = [
		"room_prop",
		"carryable_prop",
		"explosive_barrel",
		"carryable_explosive",
		"crate",
		"pot",
		"table",
		"barrel",
		"pillar"
	]

	for token: String in valid_tokens:
		if token in searchable:
			return true

	return false


func _is_object_currently_carried(
	target: Node2D
) -> bool:
	if bool(
		target.get_meta(
			"is_carried",
			false
		)
	):
		return true

	if _has_property(
		target,
		"is_carried"
	):
		var carried_value: Variant = target.get(
			"is_carried"
		)

		if (
			typeof(carried_value) == TYPE_BOOL
			and bool(
				carried_value
			)
		):
			return true

	var player_carried: Variant = player.get_meta(
		"carried_object",
		null
	)

	if (
		typeof(player_carried) == TYPE_OBJECT
		and is_instance_valid(
			player_carried
		)
		and player_carried == target
	):
		return true

	return false


func _is_inside_hammer_special(
	target: Node2D,
	direction: Vector2,
	attack_range: float,
	attack_arc: float
) -> bool:
	var offset: Vector2 = (
		target.global_position
		- player.global_position
	)

	var distance: float = (
		offset.length()
	)

	var target_radius: float = 14.0

	if _has_property(
		target,
		"hit_radius"
	):
		var radius_value: Variant = target.get(
			"hit_radius"
		)

		if (
			typeof(radius_value) == TYPE_FLOAT
			or typeof(radius_value) == TYPE_INT
		):
			target_radius = maxf(
				0.0,
				float(
					radius_value
				)
			)

	if (
		distance <= 0.001
		or distance
			> attack_range
			+ target_radius
	):
		return false

	var target_direction: Vector2 = (
		offset / distance
	)

	var dot_value: float = clampf(
		direction.dot(
			target_direction
		),
		-1.0,
		1.0
	)

	return acos(
		dot_value
	) <= attack_arc


func _hammer_launch_target_v2(
	target: Node2D,
	damage_value: int,
	final_knockback: float,
	power: float,
	is_object: bool
) -> void:
	if not is_instance_valid(
		target
	):
		return

	if target.is_queued_for_deletion():
		return

	if bool(
		target.get_meta(
			"hammer_airborne",
			false
		)
	):
		return

	var launch_direction: Vector2 = (
		target.global_position
		- player.global_position
	)

	if launch_direction.length_squared() <= 0.001:
		launch_direction = (
			_get_aim_direction()
		)

	launch_direction = (
		launch_direction.normalized()
	)

	var launch_distance: float = clampf(
		final_knockback * 0.22,
		34.0,
		310.0
	)

	var normalized_force: float = clampf(
		final_knockback / 1100.0,
		0.0,
		1.25
	)

	var launch_duration: float = lerpf(
		0.18,
		0.44,
		clampf(
			normalized_force,
			0.0,
			1.0
		)
	)

	_start_hammer_airborne(
		target,
		launch_direction,
		launch_distance,
		launch_duration,
		damage_value,
		final_knockback,
		power,
		is_object,
		0
	)


func _start_hammer_airborne(
	target: Node2D,
	launch_direction: Vector2,
	launch_distance: float,
	launch_duration: float,
	damage_value: int,
	knockback_value: float,
	power: float,
	is_object: bool,
	chain_depth: int
) -> void:
	if not is_instance_valid(
		target
	):
		return

	if target.is_queued_for_deletion():
		return

	if bool(
		target.get_meta(
			"hammer_airborne",
			false
		)
	):
		return

	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var airborne_actor: Node2D = (
		HammerAirborneActorScript.new()
		as Node2D
	)

	if not is_instance_valid(
		airborne_actor
	):
		return

	airborne_actor.z_index = 60

	scene.add_child(
		airborne_actor
	)

	airborne_actor.call(
		"setup",
		target,
		self,
		launch_direction,
		launch_distance,
		launch_duration,
		damage_value,
		knockback_value,
		power,
		is_object,
		chain_depth
	)


func _hammer_chain_launch_target(
	target: Node2D,
	impact_position: Vector2,
	launch_direction: Vector2,
	chain_force: float,
	damage_value: int,
	power: float,
	chain_depth: int
) -> void:
	if not is_instance_valid(
		target
	):
		return

	if target.is_queued_for_deletion():
		return

	if bool(
		target.get_meta(
			"hammer_airborne",
			false
		)
	):
		return

	var knockback_multiplier: float = (
		_get_enemy_knockback_multiplier(
			target
		)
	)

	var final_force: float = (
		chain_force
		* knockback_multiplier
	)

	var chain_distance: float = clampf(
		final_force * 0.18,
		24.0,
		190.0
	)

	var normalized_force: float = clampf(
		final_force / 900.0,
		0.0,
		1.0
	)

	var duration: float = lerpf(
		0.14,
		0.32,
		normalized_force
	)

	var direction: Vector2 = (
		launch_direction
	)

	if direction.length_squared() <= 0.001:
		direction = (
			target.global_position
			- impact_position
		)

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = (
		direction.normalized()
	)

	_spawn_fx(
		"wall_slam",
		impact_position,
		direction,
		24.0
	)

	_start_hammer_airborne(
		target,
		direction,
		chain_distance,
		duration,
		damage_value,
		final_force,
		power * 0.82,
		false,
		chain_depth
	)


func _hammer_airborne_world_impact(
	position_value: Vector2,
	power: float
) -> void:
	_spawn_fx(
		"wall_slam",
		position_value,
		Vector2.RIGHT,
		lerpf(
			22.0,
			38.0,
			power
		)
	)

	_request_gamefeel(
		lerpf(
			2.0,
			6.0,
			power
		),
		lerpf(
			0.025,
			0.060,
			power
		),
		0.09
	)


func _hammer_launch_target(
	target: Node2D,
	damage_value: int,
	final_knockback: float,
	power: float,
	is_object: bool
) -> void:
	if not is_instance_valid(
		target
	):
		return

	if target.is_queued_for_deletion():
		return

	if bool(
		target.get_meta(
			"hammer_airborne",
			false
		)
	):
		return

	var launch_direction: Vector2 = (
		target.global_position
		- player.global_position
	)

	if launch_direction.length_squared() <= 0.001:
		launch_direction = (
			_get_aim_direction()
		)

	launch_direction = (
		launch_direction.normalized()
	)

	var normalized_force: float = clampf(
		final_knockback / 1100.0,
		0.0,
		1.35
	)

	var launch_distance: float = clampf(
		final_knockback * 0.19,
		24.0,
		270.0
	)

	var launch_duration: float = lerpf(
		0.16,
		0.38,
		clampf(
			normalized_force,
			0.0,
			1.0
		)
	)

	var start_position: Vector2 = (
		target.global_position
	)

	var desired_position: Vector2 = (
		start_position
		+ launch_direction
		* launch_distance
	)

	var destination: Vector2 = (
		_find_hammer_launch_destination(
			start_position,
			desired_position,
			14.0
		)
	)

	var original_rotation: float = (
		target.rotation
	)

	var original_scale: Vector2 = (
		target.scale
	)

	var original_z_index: int = (
		target.z_index
	)

	var was_processing: bool = (
		target.is_processing()
	)

	var was_physics_processing: bool = (
		target.is_physics_processing()
	)

	target.set_meta(
		"hammer_airborne",
		true
	)

	target.set_meta(
		"last_hammer_knockback",
		final_knockback
	)

	# Trong thời gian bay, tạm ngừng AI / movement của target.
	# Tween của Hammer sẽ điều khiển quỹ đạo.
	target.set_process(
		false
	)

	target.set_physics_process(
		false
	)

	target.z_index = (
		original_z_index + 15
	)

	var spin_multiplier: float = clampf(
		normalized_force,
		0.15,
		1.0
	)

	# Object nhẹ xoay mạnh hơn khi bay.
	if is_object:
		spin_multiplier *= 1.25

	var spin_direction: float = 1.0

	if randf() < 0.5:
		spin_direction = -1.0

	var spin_amount: float = (
		lerpf(
			0.35,
			3.8,
			spin_multiplier
		)
		* spin_direction
	)

	var tween: Tween = create_tween()

	tween.set_parallel(
		true
	)

	tween.tween_property(
		target,
		"global_position",
		destination,
		launch_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		target,
		"rotation",
		original_rotation
			+ spin_amount,
		launch_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# Squash nhẹ tạo cảm giác bị hất khỏi mặt đất.
	tween.tween_property(
		target,
		"scale",
		original_scale
			* Vector2(
				1.10,
				0.88
			),
		launch_duration * 0.42
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.set_parallel(
		false
	)

	tween.tween_property(
		target,
		"scale",
		original_scale,
		launch_duration * 0.22
	)

	tween.tween_callback(
		_finish_hammer_launch.bind(
			target,
			damage_value,
			was_processing,
			was_physics_processing,
			original_rotation,
			original_scale,
			original_z_index,
			start_position,
			destination,
			power
		)
	)


func _finish_hammer_launch(
	target: Node2D,
	damage_value: int,
	was_processing: bool,
	was_physics_processing: bool,
	original_rotation: float,
	original_scale: Vector2,
	original_z_index: int,
	start_position: Vector2,
	destination: Vector2,
	power: float
) -> void:
	if not is_instance_valid(
		target
	):
		return

	if target.is_queued_for_deletion():
		return

	var expected_distance: float = (
		start_position.distance_to(
			destination
		)
	)

	# Heavy hit damage được commit ở cuối quãng bay.
	# Nhờ vậy lethal hit vẫn có animation "bay xác"
	# trước khi target chết / vỡ / nổ.
	if target.has_method(
		"take_damage"
	):
		target.call(
			"take_damage",
			damage_value
		)

	if not is_instance_valid(
		target
	):
		return

	if target.is_queued_for_deletion():
		return

	# Target vẫn sống: khôi phục state bình thường.
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

	target.set_process(
		was_processing
	)

	target.set_physics_process(
		was_physics_processing
	)

	# Landing feedback cho cú charge mạnh.
	if (
		power >= 0.55
		and expected_distance >= 40.0
	):
		_spawn_fx(
			"wall_slam",
			target.global_position,
			Vector2.RIGHT,
			lerpf(
				18.0,
				32.0,
				power
			)
		)


func _find_hammer_launch_destination(
	start_position: Vector2,
	desired_position: Vector2,
	target_radius: float
) -> Vector2:
	var offset: Vector2 = (
		desired_position
		- start_position
	)

	var total_distance: float = (
		offset.length()
	)

	if total_distance <= 0.001:
		return start_position

	var direction: Vector2 = (
		offset / total_distance
	)

	var step_count: int = clampi(
		int(
			ceil(
				total_distance / 18.0
			)
		),
		2,
		18
	)

	var last_safe_position: Vector2 = (
		start_position
	)

	for index: int in range(
		1,
		step_count + 1
	):
		var ratio: float = (
			float(index)
			/ float(step_count)
		)

		var sample_position: Vector2 = (
			start_position
			+ direction
			* total_distance
			* ratio
		)

		var blocked: bool = false

		for blocker: Node in get_tree().get_nodes_in_group(
			"bullet_blockers"
		):
			if not is_instance_valid(
				blocker
			):
				continue

			if blocker.has_method(
				"contains_projectile_point"
			):
				if bool(
					blocker.call(
						"contains_projectile_point",
						sample_position,
						target_radius
					)
				):
					blocked = true
					break

		if blocked:
			break

		last_safe_position = (
			sample_position
		)

	return last_safe_position


func _get_object_knockback_multiplier(
	target: Node
) -> float:
	if _has_property(
		target,
		"hammer_knockback_multiplier"
	):
		var hammer_value: Variant = target.get(
			"hammer_knockback_multiplier"
		)

		if (
			typeof(hammer_value) == TYPE_FLOAT
			or typeof(hammer_value) == TYPE_INT
		):
			return maxf(
				0.0,
				float(
					hammer_value
				)
			)

	if _has_property(
		target,
		"knockback_multiplier"
	):
		var multiplier_value: Variant = target.get(
			"knockback_multiplier"
		)

		if (
			typeof(multiplier_value) == TYPE_FLOAT
			or typeof(multiplier_value) == TYPE_INT
		):
			return maxf(
				0.0,
				float(
					multiplier_value
				)
			)

	var type_text: String = (
		target.name.to_lower()
	)

	var property_names: Array[String] = [
		"prop_type",
		"object_type",
		"barrel_type"
	]

	for property_name: String in property_names:
		if not _has_property(
			target,
			property_name
		):
			continue

		type_text += (
			" "
			+ str(
				target.get(
					property_name
				)
			).to_lower()
		)

	var script_value: Variant = (
		target.get_script()
	)

	if (
		typeof(script_value) == TYPE_OBJECT
		and is_instance_valid(
			script_value
		)
	):
		var script: Script = (
			script_value as Script
		)

		type_text += (
			" "
			+ script.resource_path.to_lower()
		)

	# Vật cực nhẹ.
	if "pot" in type_text:
		return 1.55

	# Crate khá nhẹ.
	if "crate" in type_text:
		return 1.20

	# Barrel nặng hơn crate một chút.
	if (
		"barrel" in type_text
		or "explosive" in type_text
	):
		return 0.95

	# Table khá nặng.
	if "table" in type_text:
		return 0.72

	# Pillar không được Hammer hất.
	if "pillar" in type_text:
		return 0.0

	return 1.0


func _get_enemy_knockback_multiplier(
	enemy: Node
) -> float:
	if _has_property(
		enemy,
		"knockback_multiplier"
	):
		var multiplier_value: Variant = enemy.get(
			"knockback_multiplier"
		)

		if (
			typeof(multiplier_value) == TYPE_FLOAT
			or typeof(multiplier_value) == TYPE_INT
		):
			return maxf(
				0.05,
				float(
					multiplier_value
				)
			)

	if _has_property(
		enemy,
		"knockback_resistance"
	):
		var resistance_value: Variant = enemy.get(
			"knockback_resistance"
		)

		if (
			typeof(resistance_value) == TYPE_FLOAT
			or typeof(resistance_value) == TYPE_INT
		):
			var resistance: float = clampf(
				float(
					resistance_value
				),
				0.0,
				0.95
			)

			return (
				1.0 - resistance
			)

	if enemy.is_in_group(
		"boss"
	) or enemy.is_in_group(
		"bosses"
	):
		return 0.18

	if enemy.is_in_group(
		"elite"
	):
		return 0.55

	var type_text: String = (
		enemy.name.to_lower()
	)

	if _has_property(
		enemy,
		"enemy_type"
	):
		type_text += (
			" "
			+ str(
				enemy.get(
					"enemy_type"
				)
			).to_lower()
		)

	if "boss" in type_text:
		return 0.18

	if "elite" in type_text:
		return 0.55

	if (
		"tank" in type_text
		or "brute" in type_text
		or "golem" in type_text
	):
		return 0.40

	if (
		"small" in type_text
		or "bat" in type_text
		or "slime" in type_text
	):
		return 1.35

	if (
		"ranged" in type_text
		or "gunner" in type_text
		or "archer" in type_text
	):
		return 1.10

	return 1.0


func _cancel_special() -> void:
	parry_active = false

	spear_charging = false
	spear_charge_time = 0.0

	hammer_charging = false
	hammer_charge_time = 0.0

	active_weapon_id = ""

	_hide_progress()

	if is_instance_valid(
		hammer_spin_fx
	):
		hammer_spin_fx.call(
			"set_active",
			false
		)


func _show_progress(
	value: float
) -> void:
	if not is_instance_valid(
		progress_bar
	):
		return

	progress_bar.call(
		"show_progress",
		value
	)


func _hide_progress() -> void:
	if not is_instance_valid(
		progress_bar
	):
		return

	progress_bar.call(
		"hide_progress"
	)


func _block_normal_attack(
	duration: float
) -> void:
	if not _has_property(
		player,
		"fire_timer"
	):
		return

	var current_value: float = float(
		player.get(
			"fire_timer"
		)
	)

	player.set(
		"fire_timer",
		maxf(
			current_value,
			duration
		)
	)


func _get_aim_direction() -> Vector2:
	if _has_property(
		player,
		"aim_direction"
	):
		var aim_value: Variant = player.get(
			"aim_direction"
		)

		if typeof(
			aim_value
		) == TYPE_VECTOR2:
			var result: Vector2 = (
				aim_value
			)

			if result.length_squared() > 0.001:
				return result.normalized()

	var mouse_direction: Vector2 = (
		player.get_global_mouse_position()
		- player.global_position
	)

	if mouse_direction.length_squared() > 0.001:
		return mouse_direction.normalized()

	return Vector2.RIGHT


func _get_weapon_system() -> Object:
	if not _has_property(
		player,
		"weapon_system"
	):
		return null

	var weapon_system_value: Variant = (
		player.get(
			"weapon_system"
		)
	)

	if typeof(
		weapon_system_value
	) != TYPE_OBJECT:
		return null

	if not is_instance_valid(
		weapon_system_value
	):
		return null

	return weapon_system_value as Object


func _spawn_fx(
	effect_type: String,
	position_value: Vector2,
	direction: Vector2,
	radius: float
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var fx: Node2D = (
		Milestone14FxScript.new()
		as Node2D
	)

	scene.add_child(
		fx
	)

	fx.global_position = (
		position_value
	)

	fx.call(
		"configure",
		effect_type,
		direction,
		radius
	)


func _request_gamefeel(
	shake: float,
	hit_stop: float,
	slow_scale: float
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if player.has_method(
		"add_camera_shake"
	):
		player.call(
			"add_camera_shake",
			shake
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
			shake
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
			hit_stop,
			slow_scale
		)


func _has_property(
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