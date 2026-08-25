extends Node

var weapons: Dictionary = {
	"pistol": {
		"name": "PISTOL",
		"mag_size": 8,
		"fire_interval": 0.24,
		"reload_time": 0.85,
		"pellets": 1,
		"spread_deg": 0.0,
		"bullet_speed": 520.0,
		"damage": 1,
		"recoil": 1.3,
		"automatic": false
	},
	"shotgun": {
		"name": "SHOTGUN",
		"mag_size": 5,
		"fire_interval": 0.68,
		"reload_time": 1.15,
		"pellets": 6,
		"spread_deg": 20.0,
		"bullet_speed": 430.0,
		"damage": 1,
		"recoil": 5.0,
		"automatic": false
	},
	"machine_gun": {
		"name": "MACHINE GUN",
		"mag_size": 24,
		"fire_interval": 0.075,
		"reload_time": 1.35,
		"pellets": 1,
		"spread_deg": 5.0,
		"bullet_speed": 560.0,
		"damage": 1,
		"recoil": 0.55,
		"automatic": true
	},
	"sword": {
		"name": "SWORD",
		"type": "melee",
		"melee_style": "slash",
		"synergy_tags": [
			"melee",
			"blade",
			"slash",
			"parry"
		],
		"mag_size": 0,
		"fire_interval": 0.32,
		"reload_time": 0.0,
		"pellets": 0,
		"spread_deg": 0.0,
		"bullet_speed": 0.0,
		"damage": 3,
		"recoil": 0.0,
		"automatic": false,
		"range": 55.0,
		"arc_deg": 100.0,
		"knockback": 165.0,
		"lunge": 6.0
	},

	"spear": {
		"name": "SPEAR",
		"type": "melee",
		"melee_style": "thrust",
		"synergy_tags": [
			"melee",
			"pierce",
			"thrust",
			"lunge"
		],
		"mag_size": 0,
		"fire_interval": 0.40,
		"reload_time": 0.0,
		"pellets": 0,
		"spread_deg": 0.0,
		"bullet_speed": 0.0,
		"damage": 4,
		"recoil": 0.0,
		"automatic": false,
		"range": 92.0,
		"arc_deg": 30.0,
		"knockback": 135.0,
		"lunge": 9.0
	},

	"hammer": {
		"name": "HAMMER",
		"type": "melee",
		"melee_style": "smash",
		"synergy_tags": [
			"melee",
			"heavy",
			"impact",
			"smash",
			"shockwave"
		],
		"mag_size": 0,
		"fire_interval": 0.62,
		"reload_time": 0.0,
		"pellets": 0,
		"spread_deg": 0.0,
		"bullet_speed": 0.0,
		"damage": 7,
		"recoil": 0.0,
		"automatic": false,
		"range": 48.0,
		"arc_deg": 125.0,
		"knockback": 310.0,
		"lunge": 4.0
	}
}

var ammo: Dictionary = {
	"pistol": 8,
	"shotgun": 5,
	"machine_gun": 24,
	"sword": 0
}

var reserve_ammo: Dictionary = {
	"pistol": 64,
	"shotgun": 30,
	"machine_gun": 120,
	"sword": 0
}

var unlocked: Dictionary = {
	"pistol": true,
	"shotgun": false,
	"machine_gun": false,
	"sword": false
}

# Weapon slots follow pickup order.
# Pistol is always the starting slot.
var weapon_order: Array[String] = [
	"pistol"
]

var current_weapon: String = "pistol"

var reloading: bool = false
var reload_timer: float = 0.0
var reload_weapon_id: String = ""


func _process(delta: float) -> void:
	if not reloading:
		return

	reload_timer -= delta

	if reload_timer <= 0.0:
		_finish_reload()


func get_current_weapon() -> Dictionary:
	return weapons[current_weapon]


func get_weapon_name() -> String:
	return str(weapons[current_weapon]["name"])


func get_ammo_in_mag() -> int:
	return int(ammo[current_weapon])


func get_reserve_ammo() -> int:
	return int(reserve_ammo[current_weapon])


func can_fire() -> bool:
	var weapon: Dictionary = weapons[current_weapon]

	if str(weapon.get("type", "ranged")) == "melee":
		return not reloading

	return (
		not reloading
		and int(ammo[current_weapon]) > 0
	)


func consume_round() -> void:
	var weapon: Dictionary = weapons[current_weapon]

	if str(weapon.get("type", "ranged")) == "melee":
		return

	if int(ammo[current_weapon]) <= 0:
		return

	ammo[current_weapon] = int(ammo[current_weapon]) - 1


func start_reload() -> void:
	if reloading:
		return

	var weapon: Dictionary = weapons[current_weapon]

	if str(weapon.get("type", "ranged")) == "melee":
		return

	var mag_size: int = int(
		weapon["mag_size"]
	)

	var current_ammo: int = int(
		ammo[current_weapon]
	)

	var reserve: int = int(
		reserve_ammo[current_weapon]
	)

	if current_ammo >= mag_size:
		return

	if reserve <= 0:
		return

	reloading = true
	reload_weapon_id = current_weapon
	reload_timer = float(
		weapon["reload_time"]
	)


func _finish_reload() -> void:
	if reload_weapon_id == "":
		reloading = false
		return

	var weapon: Dictionary = weapons[
		reload_weapon_id
	]

	var mag_size: int = int(
		weapon["mag_size"]
	)

	var current_ammo: int = int(
		ammo[reload_weapon_id]
	)

	var reserve: int = int(
		reserve_ammo[reload_weapon_id]
	)

	var needed: int = mag_size - current_ammo
	var amount: int = mini(
		needed,
		reserve
	)

	ammo[reload_weapon_id] = (
		current_ammo
		+ amount
	)

	reserve_ammo[reload_weapon_id] = (
		reserve
		- amount
	)

	reloading = false
	reload_timer = 0.0
	reload_weapon_id = ""


func unlock_and_equip(
	weapon_id: String
) -> void:
	if not weapons.has(weapon_id):
		return

	unlocked[weapon_id] = true

	# First pickup decides inventory slot order.
	if not weapon_order.has(weapon_id):
		weapon_order.append(weapon_id)

	equip_if_unlocked(
		weapon_id
	)


func equip_if_unlocked(
	weapon_id: String
) -> void:
	if not weapons.has(weapon_id):
		return

	if not bool(unlocked[weapon_id]):
		return

	if current_weapon == weapon_id:
		return

	reloading = false
	reload_timer = 0.0
	reload_weapon_id = ""

	current_weapon = weapon_id


func equip_by_index(index: int) -> void:
	if index < 0:
		return

	if index >= weapon_order.size():
		return

	var weapon_id: String = weapon_order[index]

	equip_if_unlocked(
		weapon_id
	)


func cycle_weapon(direction: int) -> void:
	if weapon_order.size() <= 1:
		return

	var current_index: int = weapon_order.find(
		current_weapon
	)

	if current_index < 0:
		current_index = 0

	var next_index: int = current_index + direction

	if next_index < 0:
		next_index = weapon_order.size() - 1

	if next_index >= weapon_order.size():
		next_index = 0

	equip_by_index(
		next_index
	)


func get_weapon_order() -> Array[String]:
	return weapon_order