extends Node

const GameHudIconScript = preload(
	"res://gungeon_proto/game_hud_icon.gd"
)

var relic_catalog: Dictionary = {
	"iron_seed": {
		"name": "IRON SEED",
		"rarity": "COMMON",
		"description": "+1 Max HP. Heal 1 HP."
	},

	"fleet_feather": {
		"name": "FLEET FEATHER",
		"rarity": "COMMON",
		"description": "+12% movement speed."
	},

	"broken_hourglass": {
		"name": "BROKEN HOURGLASS",
		"rarity": "RARE",
		"description": "Dodge cooldown -20%."
	},

	"brass_trigger": {
		"name": "BRASS TRIGGER",
		"rarity": "COMMON",
		"description": "+15% fire rate."
	},

	"lead_eye": {
		"name": "LEAD EYE",
		"rarity": "RARE",
		"description": "+1 projectile damage. -8% bullet speed."
	},

	"long_fang": {
		"name": "LONG FANG",
		"rarity": "COMMON",
		"description": "Sword range +18. Arc +14 degrees."
	},

	"titan_knuckle": {
		"name": "TITAN KNUCKLE",
		"rarity": "RARE",
		"description": "Thrown props +35% speed and +1 impact damage."
	},

	"powder_idol": {
		"name": "POWDER IDOL",
		"rarity": "EPIC",
		"description": "Explosive barrels gain +30% blast radius and +2 damage."
	},

	"deep_pockets": {
		"name": "DEEP POCKETS",
		"rarity": "RARE",
		"description": "Weapon magazine size +25%."
	}
}


var acquired_relics: Dictionary = {}

var hud_layer: CanvasLayer
var relic_row: HBoxContainer


func _ready() -> void:
	add_to_group(
		"relic_system"
	)

	_reset_run_modifiers()

	_create_hud()


func _reset_run_modifiers() -> void:
	Engine.set_meta(
		"relic_throw_speed_mult",
		1.0
	)

	Engine.set_meta(
		"relic_throw_damage_bonus",
		0
	)

	Engine.set_meta(
		"relic_barrel_radius_mult",
		1.0
	)

	Engine.set_meta(
		"relic_barrel_damage_bonus",
		0
	)


func get_catalog() -> Dictionary:
	return relic_catalog.duplicate(
		true
	)


func get_random_relic_ids(
	count: int
) -> Array[String]:
	var all_ids: Array[String] = []

	for relic_key: Variant in relic_catalog.keys():
		all_ids.append(
			str(relic_key)
		)

	all_ids.shuffle()

	var result: Array[String] = []

	var result_count: int = mini(
		count,
		all_ids.size()
	)

	for index: int in range(
		result_count
	):
		result.append(
			all_ids[index]
		)

	return result


func has_relic(
	relic_id: String
) -> bool:
	return acquired_relics.has(
		relic_id
	)


func acquire_relic(
	relic_id: String
) -> bool:
	if not relic_catalog.has(
		relic_id
	):
		return false

	if acquired_relics.has(
		relic_id
	):
		return false

	acquired_relics[
		relic_id
	] = true

	_apply_relic_effect(
		relic_id
	)

	_update_hud()

	return true


func _apply_relic_effect(
	relic_id: String
) -> void:
	var player: Node2D = _get_player()

	match relic_id:
		"iron_seed":
			if is_instance_valid(
				player
			):
				_apply_health_relic(
					player
				)

		"fleet_feather":
			if is_instance_valid(
				player
			):
				_multiply_first_numeric_property(
					player,
					[
						"move_speed",
						"movement_speed",
						"speed"
					],
					1.12
				)

		"broken_hourglass":
			if is_instance_valid(
				player
			):
				_multiply_first_numeric_property(
					player,
					[
						"dodge_cooldown",
						"roll_cooldown",
						"dodge_recharge"
					],
					0.80
				)

		"brass_trigger":
			_modify_weapon_data(
				"fire_rate"
			)

		"lead_eye":
			_modify_weapon_data(
				"lead_eye"
			)

		"long_fang":
			_modify_weapon_data(
				"long_fang"
			)

		"deep_pockets":
			_modify_weapon_data(
				"deep_pockets"
			)

		"titan_knuckle":
			_apply_titan_knuckle()

		"powder_idol":
			_apply_powder_idol()


func _apply_health_relic(
	player: Node2D
) -> void:
	if _has_property(
		player,
		"max_health"
	):
		var max_health_value: int = int(
			player.get(
				"max_health"
			)
		)

		player.set(
			"max_health",
			max_health_value + 1
		)

	if _has_property(
		player,
		"health"
	):
		var health_value: int = int(
			player.get(
				"health"
			)
		)

		var maximum_value: int = (
			health_value + 1
		)

		if _has_property(
			player,
			"max_health"
		):
			maximum_value = int(
				player.get(
					"max_health"
				)
			)

		player.set(
			"health",
			mini(
				health_value + 1,
				maximum_value
			)
		)


func _apply_titan_knuckle() -> void:
	var old_speed_mult: float = float(
		Engine.get_meta(
			"relic_throw_speed_mult",
			1.0
		)
	)

	Engine.set_meta(
		"relic_throw_speed_mult",
		old_speed_mult * 1.35
	)

	var old_damage_bonus: int = int(
		Engine.get_meta(
			"relic_throw_damage_bonus",
			0
		)
	)

	Engine.set_meta(
		"relic_throw_damage_bonus",
		old_damage_bonus + 1
	)

	for object_value: Node in get_tree().get_nodes_in_group(
		"carryable_objects"
	):
		if not is_instance_valid(
			object_value
		):
			continue

		if _has_property(
			object_value,
			"throw_speed"
		):
			var speed_value: float = float(
				object_value.get(
					"throw_speed"
				)
			)

			object_value.set(
				"throw_speed",
				speed_value * 1.35
			)

		if _has_property(
			object_value,
			"throw_impact_damage"
		):
			var damage_value: int = int(
				object_value.get(
					"throw_impact_damage"
				)
			)

			object_value.set(
				"throw_impact_damage",
				damage_value + 1
			)


func _apply_powder_idol() -> void:
	var old_radius_mult: float = float(
		Engine.get_meta(
			"relic_barrel_radius_mult",
			1.0
		)
	)

	Engine.set_meta(
		"relic_barrel_radius_mult",
		old_radius_mult * 1.30
	)

	var old_damage_bonus: int = int(
		Engine.get_meta(
			"relic_barrel_damage_bonus",
			0
		)
	)

	Engine.set_meta(
		"relic_barrel_damage_bonus",
		old_damage_bonus + 2
	)

	for barrel_value: Node in get_tree().get_nodes_in_group(
		"explosive_barrels"
	):
		if not is_instance_valid(
			barrel_value
		):
			continue

		if _has_property(
			barrel_value,
			"explosion_radius"
		):
			var radius_value: float = float(
				barrel_value.get(
					"explosion_radius"
				)
			)

			barrel_value.set(
				"explosion_radius",
				radius_value * 1.30
			)

		if _has_property(
			barrel_value,
			"explosion_damage"
		):
			var damage_value: int = int(
				barrel_value.get(
					"explosion_damage"
				)
			)

			barrel_value.set(
				"explosion_damage",
				damage_value + 2
			)


func _modify_weapon_data(
	modifier_type: String
) -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	var weapon_system: Object = (
		_get_weapon_system(
			player
		)
	)

	if not is_instance_valid(
		weapon_system
	):
		return

	var dictionary_property: String = (
		_find_weapon_dictionary_property(
			weapon_system
		)
	)

	if dictionary_property.is_empty():
		return

	var weapons_value: Variant = weapon_system.get(
		dictionary_property
	)

	if typeof(
		weapons_value
	) != TYPE_DICTIONARY:
		return

	var weapons: Dictionary = weapons_value

	for weapon_key: Variant in weapons.keys():
		var weapon_value: Variant = weapons[
			weapon_key
		]

		if typeof(
			weapon_value
		) != TYPE_DICTIONARY:
			continue

		var weapon: Dictionary = weapon_value

		match modifier_type:
			"fire_rate":
				if weapon.has(
					"fire_interval"
				):
					weapon[
						"fire_interval"
					] = maxf(
						0.03,
						float(
							weapon[
								"fire_interval"
							]
						) * 0.85
					)

			"lead_eye":
				if weapon.has(
					"damage"
				):
					weapon[
						"damage"
					] = int(
						weapon[
							"damage"
						]
					) + 1

				if weapon.has(
					"bullet_speed"
				):
					var bullet_speed: float = float(
						weapon[
							"bullet_speed"
						]
					)

					if bullet_speed > 0.0:
						weapon[
							"bullet_speed"
						] = (
							bullet_speed
							* 0.92
						)

			"long_fang":
				if str(
					weapon_key
				) != "sword":
					continue

				if weapon.has(
					"range"
				):
					weapon[
						"range"
					] = float(
						weapon[
							"range"
						]
					) + 18.0

				if weapon.has(
					"arc_deg"
				):
					weapon[
						"arc_deg"
					] = float(
						weapon[
							"arc_deg"
						]
					) + 14.0

			"deep_pockets":
				if weapon.has(
					"mag_size"
				):
					var old_mag_size: int = int(
						weapon[
							"mag_size"
						]
					)

					if old_mag_size > 0:
						weapon[
							"mag_size"
						] = maxi(
							old_mag_size + 1,
							int(
								ceil(
									float(
										old_mag_size
									) * 1.25
								)
							)
						)

		weapons[
			weapon_key
		] = weapon

	weapon_system.set(
		dictionary_property,
		weapons
	)


func _get_weapon_system(
	player: Node2D
) -> Object:
	if _has_property(
		player,
		"weapon_system"
	):
		var system_value: Variant = player.get(
			"weapon_system"
		)

		if (
			typeof(system_value)
			== TYPE_OBJECT
			and is_instance_valid(
				system_value
			)
		):
			return system_value as Object

	return null


func _find_weapon_dictionary_property(
	weapon_system: Object
) -> String:
	for property_value: Dictionary in weapon_system.get_property_list():
		var property_name: String = str(
			property_value.get(
				"name",
				""
			)
		)

		if property_name.is_empty():
			continue

		var value: Variant = weapon_system.get(
			property_name
		)

		if typeof(
			value
		) != TYPE_DICTIONARY:
			continue

		var dictionary: Dictionary = value

		if (
			dictionary.has(
				"pistol"
			)
			or dictionary.has(
				"shotgun"
			)
			or dictionary.has(
				"sword"
			)
		):
			return property_name

	return ""


func _multiply_first_numeric_property(
	target: Object,
	property_names: Array,
	multiplier: float
) -> void:
	for property_name_value: Variant in property_names:
		var property_name: String = str(
			property_name_value
		)

		if not _has_property(
			target,
			property_name
		):
			continue

		var current_value: Variant = target.get(
			property_name
		)

		if (
			typeof(current_value)
			!= TYPE_FLOAT
			and typeof(current_value)
			!= TYPE_INT
		):
			continue

		target.set(
			property_name,
			float(
				current_value
			) * multiplier
		)

		return


func _has_property(
	target: Object,
	property_name: String
) -> bool:
	for property_value: Dictionary in target.get_property_list():
		if str(
			property_value.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false


func _get_player() -> Node2D:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return null

	return player_value as Node2D


func _create_hud() -> void:
	hud_layer = CanvasLayer.new()

	hud_layer.layer = 80

	add_child(
		hud_layer
	)

	relic_row = HBoxContainer.new()

	relic_row.position = Vector2(
		16.0,
		14.0
	)

	relic_row.add_theme_constant_override(
		"separation",
		6
	)

	hud_layer.add_child(
		relic_row
	)

	_update_hud()


func _update_hud() -> void:
	if not is_instance_valid(
		relic_row
	):
		return

	for child: Node in relic_row.get_children():
		child.queue_free()

	for relic_key: Variant in acquired_relics.keys():
		var relic_id: String = str(
			relic_key
		)

		if not relic_catalog.has(
			relic_id
		):
			continue

		var data: Dictionary = relic_catalog[
			relic_id
		]

		var rarity_value: String = str(
			data.get(
				"rarity",
				"COMMON"
			)
		)

		var relic_name: String = str(
			data.get(
				"name",
				relic_id
			)
		)

		var description: String = str(
			data.get(
				"description",
				""
			)
		)

		var icon: Control = (
			GameHudIconScript.new()
		)

		icon.custom_minimum_size = Vector2(
			38.0,
			38.0
		)

		icon.size = Vector2(
			38.0,
			38.0
		)

		icon.tooltip_text = (
			relic_name
			+ "\n"
			+ description
		)

		icon.call(
			"configure",
			"relic",
			relic_id,
			rarity_value
		)

		relic_row.add_child(
			icon
		)