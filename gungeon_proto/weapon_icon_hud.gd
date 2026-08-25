extends CanvasLayer

const GameHudIconScript = preload(
	"res://gungeon_proto/game_hud_icon.gd"
)

var icon: Control

var current_weapon_id: String = ""


func _ready() -> void:
	layer = 90

	_create_hud()


func _create_hud() -> void:
	icon = GameHudIconScript.new()

	icon.set_anchors_preset(
		Control.PRESET_BOTTOM_RIGHT
	)

	icon.position = Vector2(
		-92.0,
		-92.0
	)

	icon.size = Vector2(
		72.0,
		72.0
	)

	icon.custom_minimum_size = Vector2(
		72.0,
		72.0
	)

	add_child(
		icon
	)

	icon.call(
		"configure",
		"weapon",
		"pistol",
		"COMMON"
	)


func _process(
	_delta: float
) -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	var weapon_system_value: Variant = player.get(
		"weapon_system"
	)

	if (
		typeof(weapon_system_value)
		!= TYPE_OBJECT
	):
		return

	var weapon_system: Object = (
		weapon_system_value as Object
	)

	if not is_instance_valid(
		weapon_system
	):
		return

	if not weapon_system.has_method(
		"get_current_weapon"
	):
		return

	var weapon_value: Variant = weapon_system.call(
		"get_current_weapon"
	)

	if typeof(
		weapon_value
	) != TYPE_DICTIONARY:
		return

	var weapon: Dictionary = weapon_value

	var weapon_name: String = str(
		weapon.get(
			"name",
			"PISTOL"
		)
	)

	var weapon_id: String = (
		_weapon_name_to_id(
			weapon_name
		)
	)

	if weapon_id == current_weapon_id:
		return

	current_weapon_id = weapon_id

	icon.call(
		"configure",
		"weapon",
		current_weapon_id,
		"COMMON"
	)


func _weapon_name_to_id(
	weapon_name: String
) -> String:
	var normalized: String = (
		weapon_name
		.to_lower()
		.replace(
			" ",
			"_"
		)
	)

	if "sword" in normalized:
		return "sword"

	if "shotgun" in normalized:
		return "shotgun"

	if (
		"machine" in normalized
		or "smg" in normalized
	):
		return "machine_gun"

	return "pistol"


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