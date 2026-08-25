extends Node

var player: Node

var stacks: Dictionary = {}

var upgrades: Dictionary = {
	"lightweight_boots": {
		"name": "LIGHTWEIGHT BOOTS",
		"description": "+18 move speed",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"iron_heart": {
		"name": "IRON HEART",
		"description": "+1 max HP and heal 1",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"rapid_fire": {
		"name": "RAPID FIRE",
		"description": "All guns fire 10% faster",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"high_velocity": {
		"name": "HIGH VELOCITY",
		"description": "+15% bullet speed",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"ammo_bag": {
		"name": "AMMO BAG",
		"description": "+30% reserve ammo",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"tactical_roll": {
		"name": "TACTICAL ROLL",
		"description": "Dodge cooldown -15%",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"long_blade": {
		"name": "LONG BLADE",
		"description": "+10 sword range",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"fast_reload": {
		"name": "FAST RELOAD",
		"description": "Reload 18% faster",
		"rarity": "COMMON",
		"max_stacks": 3
	},

	"heavy_rounds": {
		"name": "HEAVY ROUNDS",
		"description": "+1 damage to all guns",
		"rarity": "RARE",
		"max_stacks": 2
	},

	"extended_mag": {
		"name": "EXTENDED MAG",
		"description": "+25% magazine capacity",
		"rarity": "RARE",
		"max_stacks": 2
	},

	"shotgun_master": {
		"name": "SHOTGUN MASTER",
		"description": "+2 pellets, tighter spread",
		"rarity": "RARE",
		"max_stacks": 2
	},

	"pistol_master": {
		"name": "PISTOL MASTER",
		"description": "+1 damage, 25% faster pistol",
		"rarity": "RARE",
		"max_stacks": 2
	},

	"machine_master": {
		"name": "BULLET STORM",
		"description": "+12 MG mag, 15% faster",
		"rarity": "RARE",
		"max_stacks": 2
	},

	"vital_core": {
		"name": "VITAL CORE",
		"description": "+2 max HP and heal 2",
		"rarity": "EPIC",
		"max_stacks": 1
	},

	"blade_master": {
		"name": "BLADE MASTER",
		"description": "+2 sword damage, +20 arc, faster slash",
		"rarity": "EPIC",
		"max_stacks": 1
	}
}


func _ready() -> void:
	player = get_parent()


func get_upgrade_info(
	upgrade_id: String
) -> Dictionary:
	if not upgrades.has(upgrade_id):
		return {}

	return upgrades[upgrade_id]


func get_stack_count(
	upgrade_id: String
) -> int:
	return int(
		stacks.get(
			upgrade_id,
			0
		)
	)


func get_random_choices(
	count: int = 3,
	source_type: String = "normal"
) -> Array[String]:
	var candidates: Array[String] = []

	for upgrade_id_value in upgrades.keys():
		var upgrade_id: String = str(
			upgrade_id_value
		)

		var data: Dictionary = upgrades[
			upgrade_id
		]

		var current_stacks: int = get_stack_count(
			upgrade_id
		)

		var max_stacks: int = int(
			data["max_stacks"]
		)

		if current_stacks >= max_stacks:
			continue

		candidates.append(
			upgrade_id
		)

	var choices: Array[String] = []

	while (
		choices.size() < count
		and not candidates.is_empty()
	):
		var selected: String = _pick_weighted(
			candidates,
			source_type
		)

		if selected == "":
			break

		choices.append(selected)
		candidates.erase(selected)

	return choices


func _pick_weighted(
	candidates: Array[String],
	source_type: String
) -> String:
	var total_weight: int = 0

	for upgrade_id in candidates:
		var data: Dictionary = upgrades[
			upgrade_id
		]

		total_weight += _get_rarity_weight(
			str(data["rarity"]),
			source_type
		)

	if total_weight <= 0:
		return ""

	var roll: int = randi_range(
		1,
		total_weight
	)

	var accumulated: int = 0

	for upgrade_id in candidates:
		var data: Dictionary = upgrades[
			upgrade_id
		]

		accumulated += _get_rarity_weight(
			str(data["rarity"]),
			source_type
		)

		if roll <= accumulated:
			return upgrade_id

	return candidates[0]


func _get_rarity_weight(
	rarity: String,
	source_type: String
) -> int:
	if source_type == "boss":
		match rarity:
			"EPIC":
				return 45

			"RARE":
				return 40

			_:
				return 15

	if source_type == "treasure":
		match rarity:
			"EPIC":
				return 25

			"RARE":
				return 45

			_:
				return 30

	if source_type == "elite":
		match rarity:
			"EPIC":
				return 15

			"RARE":
				return 40

			_:
				return 45

	if source_type == "shop":
		match rarity:
			"EPIC":
				return 10

			"RARE":
				return 35

			_:
				return 55

	match rarity:
		"EPIC":
			return 7

		"RARE":
			return 25

		_:
			return 68


func apply_upgrade(
	upgrade_id: String
) -> void:
	if not upgrades.has(upgrade_id):
		return

	var data: Dictionary = upgrades[
		upgrade_id
	]

	var current_stacks: int = get_stack_count(
		upgrade_id
	)

	if current_stacks >= int(
		data["max_stacks"]
	):
		return

	stacks[upgrade_id] = (
		current_stacks + 1
	)

	match upgrade_id:
		"lightweight_boots":
			_upgrade_move_speed()

		"iron_heart":
			_upgrade_health(1)

		"rapid_fire":
			_modify_ranged_float(
				"fire_interval",
				0.90
			)

		"high_velocity":
			_modify_ranged_float(
				"bullet_speed",
				1.15
			)

		"ammo_bag":
			_upgrade_reserve_ammo()

		"tactical_roll":
			_upgrade_roll()

		"long_blade":
			_upgrade_sword_range()

		"fast_reload":
			_modify_ranged_float(
				"reload_time",
				0.82
			)

		"heavy_rounds":
			_modify_ranged_int(
				"damage",
				1
			)

		"extended_mag":
			_upgrade_magazines()

		"shotgun_master":
			_upgrade_shotgun()

		"pistol_master":
			_upgrade_pistol()

		"machine_master":
			_upgrade_machine_gun()

		"vital_core":
			_upgrade_health(2)

		"blade_master":
			_upgrade_blade_master()

	print(
		"UPGRADE: ",
		str(data["name"]),
		"  STACK ",
		get_stack_count(upgrade_id)
	)


func _get_weapon_system() -> Node:
	if not is_instance_valid(player):
		return null

	var value = player.get(
		"weapon_system"
	)

	if value == null:
		return null

	return value as Node


func _upgrade_move_speed() -> void:
	var speed: float = float(
		player.get("move_speed")
	)

	player.set(
		"move_speed",
		speed + 18.0
	)


func _upgrade_health(
	amount: int
) -> void:
	var max_health: int = int(
		player.get("max_health")
	)

	var health: int = int(
		player.get("health")
	)

	max_health += amount

	health = mini(
		max_health,
		health + amount
	)

	player.set(
		"max_health",
		max_health
	)

	player.set(
		"health",
		health
	)


func _upgrade_roll() -> void:
	var cooldown: float = float(
		player.get("roll_cooldown")
	)

	player.set(
		"roll_cooldown",
		cooldown * 0.85
	)


func _modify_ranged_float(
	field_name: String,
	multiplier: float
) -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons_value = system.get(
		"weapons"
	)

	if typeof(weapons_value) != TYPE_DICTIONARY:
		return

	var weapons: Dictionary = weapons_value

	for weapon_id_value in weapons.keys():
		var weapon_id: String = str(
			weapon_id_value
		)

		var weapon: Dictionary = weapons[
			weapon_id
		]

		if str(
			weapon.get(
				"type",
				"ranged"
			)
		) == "melee":
			continue

		if not weapon.has(field_name):
			continue

		weapon[field_name] = (
			float(weapon[field_name])
			* multiplier
		)

		weapons[weapon_id] = weapon

	system.set(
		"weapons",
		weapons
	)


func _modify_ranged_int(
	field_name: String,
	add_amount: int
) -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons_value = system.get(
		"weapons"
	)

	if typeof(weapons_value) != TYPE_DICTIONARY:
		return

	var weapons: Dictionary = weapons_value

	for weapon_id_value in weapons.keys():
		var weapon_id: String = str(
			weapon_id_value
		)

		var weapon: Dictionary = weapons[
			weapon_id
		]

		if str(
			weapon.get(
				"type",
				"ranged"
			)
		) == "melee":
			continue

		if not weapon.has(field_name):
			continue

		weapon[field_name] = (
			int(weapon[field_name])
			+ add_amount
		)

		weapons[weapon_id] = weapon

	system.set(
		"weapons",
		weapons
	)


func _upgrade_reserve_ammo() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var reserve_value = system.get(
		"reserve_ammo"
	)

	if typeof(reserve_value) != TYPE_DICTIONARY:
		return

	var reserve: Dictionary = reserve_value

	for weapon_id_value in reserve.keys():
		var weapon_id: String = str(
			weapon_id_value
		)

		if weapon_id == "sword":
			continue

		var current: int = int(
			reserve[weapon_id]
		)

		var bonus: int = maxi(
			1,
			int(
				ceil(
					float(current)
					* 0.30
				)
			)
		)

		reserve[weapon_id] = (
			current + bonus
		)

	system.set(
		"reserve_ammo",
		reserve
	)


func _upgrade_sword_range() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons: Dictionary = system.get(
		"weapons"
	)

	var sword: Dictionary = weapons[
		"sword"
	]

	sword["range"] = (
		float(sword["range"])
		+ 10.0
	)

	weapons["sword"] = sword

	system.set(
		"weapons",
		weapons
	)


func _upgrade_magazines() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons: Dictionary = system.get(
		"weapons"
	)

	var ammo: Dictionary = system.get(
		"ammo"
	)

	for weapon_id_value in weapons.keys():
		var weapon_id: String = str(
			weapon_id_value
		)

		var weapon: Dictionary = weapons[
			weapon_id
		]

		if str(
			weapon.get(
				"type",
				"ranged"
			)
		) == "melee":
			continue

		var old_size: int = int(
			weapon["mag_size"]
		)

		var new_size: int = int(
			ceil(
				float(old_size)
				* 1.25
			)
		)

		var difference: int = (
			new_size - old_size
		)

		weapon["mag_size"] = new_size

		weapons[weapon_id] = weapon

		if ammo.has(weapon_id):
			ammo[weapon_id] = (
				int(ammo[weapon_id])
				+ difference
			)

	system.set(
		"weapons",
		weapons
	)

	system.set(
		"ammo",
		ammo
	)


func _upgrade_shotgun() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons: Dictionary = system.get(
		"weapons"
	)

	var shotgun: Dictionary = weapons[
		"shotgun"
	]

	shotgun["pellets"] = (
		int(shotgun["pellets"])
		+ 2
	)

	shotgun["spread_deg"] = (
		float(shotgun["spread_deg"])
		* 0.85
	)

	weapons["shotgun"] = shotgun

	system.set(
		"weapons",
		weapons
	)


func _upgrade_pistol() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons: Dictionary = system.get(
		"weapons"
	)

	var pistol: Dictionary = weapons[
		"pistol"
	]

	pistol["damage"] = (
		int(pistol["damage"])
		+ 1
	)

	pistol["fire_interval"] = (
		float(pistol["fire_interval"])
		* 0.75
	)

	weapons["pistol"] = pistol

	system.set(
		"weapons",
		weapons
	)


func _upgrade_machine_gun() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons: Dictionary = system.get(
		"weapons"
	)

	var ammo: Dictionary = system.get(
		"ammo"
	)

	var machine: Dictionary = weapons[
		"machine_gun"
	]

	machine["mag_size"] = (
		int(machine["mag_size"])
		+ 12
	)

	machine["fire_interval"] = (
		float(machine["fire_interval"])
		* 0.85
	)

	weapons["machine_gun"] = machine

	ammo["machine_gun"] = (
		int(ammo["machine_gun"])
		+ 12
	)

	system.set(
		"weapons",
		weapons
	)

	system.set(
		"ammo",
		ammo
	)


func _upgrade_blade_master() -> void:
	var system: Node = _get_weapon_system()

	if not is_instance_valid(system):
		return

	var weapons: Dictionary = system.get(
		"weapons"
	)

	var sword: Dictionary = weapons[
		"sword"
	]

	sword["damage"] = (
		int(sword["damage"])
		+ 2
	)

	sword["arc_deg"] = (
		float(sword["arc_deg"])
		+ 20.0
	)

	sword["fire_interval"] = (
		float(sword["fire_interval"])
		* 0.85
	)

	weapons["sword"] = sword

	system.set(
		"weapons",
		weapons
	)