extends Node2D

const PlayerScript = preload(
	"res://gungeon_proto/player.gd"
)

const EnemyScript = preload(
	"res://gungeon_proto/enemy.gd"
)

const WeaponPickupScript = preload(
	"res://gungeon_proto/weapon_pickup.gd"
)

const DungeonMiniMapScript = preload(
	"res://gungeon_proto/dungeon_minimap.gd"
)

const ROOM_RECT := Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)

const ROOM_COUNT := 7

const DIR_UP := Vector2i(0, -1)
const DIR_DOWN := Vector2i(0, 1)
const DIR_LEFT := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)

const DIRECTIONS := [
	DIR_UP,
	DIR_DOWN,
	DIR_LEFT,
	DIR_RIGHT
]

var rooms: Dictionary = {}

var current_room: Vector2i = Vector2i.ZERO

var room_cleared: bool = true

var transition_cooldown: float = 0.0

var player: CharacterBody2D

var minimap: Control
var room_label: Label


func _ready() -> void:
	randomize()

	_generate_dungeon()

	player = PlayerScript.new() as CharacterBody2D
	player.name = "Player"

	player.set(
		"room_rect",
		ROOM_RECT.grow(-18.0)
	)

	add_child(player)

	player.position = Vector2.ZERO

	var camera := Camera2D.new()

	camera.name = "Camera2D"
	camera.enabled = true

	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0

	player.add_child(camera)

	_create_ui()

	_enter_room(
		Vector2i.ZERO,
		Vector2i.ZERO
	)

	queue_redraw()


func _process(delta: float) -> void:
	transition_cooldown = maxf(
		0.0,
		transition_cooldown - delta
	)

	if not room_cleared:
		if _get_alive_enemy_count() <= 0:
			_complete_current_room()

	if room_cleared:
		_check_room_transition()


func _generate_dungeon() -> void:
	rooms.clear()

	var start_data := {
		"type": "start",
		"visited": true,
		"cleared": true,
		"enemy_count": 0,
		"reward_claimed": false
	}

	rooms[Vector2i.ZERO] = start_data

	var positions: Array[Vector2i] = [
		Vector2i.ZERO
	]

	var attempts := 0

	while (
		positions.size() < ROOM_COUNT
		and attempts < 300
	):
		attempts += 1

		var base_index: int = randi_range(
			0,
			positions.size() - 1
		)

		var direction_index: int = randi_range(
			0,
			DIRECTIONS.size() - 1
		)

		var base_room: Vector2i = (
			positions[base_index]
		)

		var direction: Vector2i = (
			DIRECTIONS[direction_index]
		)

		var candidate: Vector2i = (
			base_room + direction
		)

		if rooms.has(candidate):
			continue

		var distance: int = (
			abs(candidate.x)
			+ abs(candidate.y)
		)

		var enemy_count: int = clampi(
			2
			+ distance
			+ randi_range(0, 1),
			2,
			5
		)

		var room_data := {
			"type": "combat",
			"visited": false,
			"cleared": false,
			"enemy_count": enemy_count,
			"reward_claimed": false
		}

		rooms[candidate] = room_data
		positions.append(candidate)

	# Farthest room becomes treasure room.
	var treasure_room := positions[
		positions.size() - 1
	]

	var best_distance := -1

	for room_pos in positions:
		if room_pos == Vector2i.ZERO:
			continue

		var distance: int = (
			abs(room_pos.x)
			+ abs(room_pos.y)
		)

		if distance > best_distance:
			best_distance = distance
			treasure_room = room_pos

	var treasure_data: Dictionary = (
		rooms[treasure_room]
	)

	treasure_data["type"] = "treasure"

	rooms[treasure_room] = treasure_data


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DungeonUI"

	add_child(canvas)

	minimap = DungeonMiniMapScript.new() as Control
	minimap.position = Vector2(10, 10)

	canvas.add_child(minimap)

	room_label = Label.new()

	room_label.position = Vector2(10, 118)
	room_label.size = Vector2(240, 45)

	room_label.add_theme_font_size_override(
		"font_size",
		11
	)

	canvas.add_child(room_label)


func _enter_room(
	room_position: Vector2i,
	entry_from: Vector2i
) -> void:
	if not rooms.has(room_position):
		return

	_clear_room_entities()

	current_room = room_position

	var data: Dictionary = rooms[
		current_room
	]

	data["visited"] = true

	rooms[current_room] = data

	room_cleared = bool(
		data["cleared"]
	)

	if entry_from != Vector2i.ZERO:
		_place_player_at_entry(
			entry_from
		)

	if not room_cleared:
		_spawn_wave(
			int(data["enemy_count"])
		)
	else:
		_spawn_room_rewards()

	transition_cooldown = 0.28

	_update_ui()

	queue_redraw()


func _spawn_wave(enemy_count: int) -> void:
	var spawn_points: Array[Vector2] = [
		Vector2(-230, -115),
		Vector2(0, -130),
		Vector2(230, -110),
		Vector2(-245, 80),
		Vector2(220, 95),
		Vector2(0, 120),
		Vector2(-140, 20),
		Vector2(150, 10)
	]

	spawn_points.shuffle()

	var amount: int = mini(
		enemy_count,
		spawn_points.size()
	)

	for i in range(amount):
		_spawn_enemy(
			spawn_points[i]
		)


func _spawn_enemy(pos: Vector2) -> void:
	var enemy = EnemyScript.new()

	enemy.name = "Enemy"

	add_child(enemy)

	enemy.position = pos


func _spawn_weapon_pickup(
	weapon_id: String,
	pos: Vector2
) -> void:
	var pickup = WeaponPickupScript.new()

	pickup.weapon_id = weapon_id

	add_child(pickup)

	pickup.position = pos


func _spawn_room_rewards() -> void:
	if not is_instance_valid(player):
		return

	# Starting room preserves Milestone 3 weapon testing.
	if current_room == Vector2i.ZERO:
		if not _player_has_weapon("shotgun"):
			_spawn_weapon_pickup(
				"shotgun",
				Vector2(-110, 75)
			)

		if not _player_has_weapon(
			"machine_gun"
		):
			_spawn_weapon_pickup(
				"machine_gun",
				Vector2(110, 75)
			)

		return

	var data: Dictionary = rooms[
		current_room
	]

	if str(data["type"]) != "treasure":
		return

	if bool(data["reward_claimed"]):
		return

	if not _player_has_weapon("shotgun"):
		_spawn_weapon_pickup(
			"shotgun",
			Vector2.ZERO
		)

		return

	if not _player_has_weapon(
		"machine_gun"
	):
		_spawn_weapon_pickup(
			"machine_gun",
			Vector2.ZERO
		)

		return

	# If player already owns everything,
	# mark treasure as collected.
	data["reward_claimed"] = true
	rooms[current_room] = data


func _player_has_weapon(
	weapon_id: String
) -> bool:
	if not is_instance_valid(player):
		return false

	var system_value = player.get(
		"weapon_system"
	)

	if system_value == null:
		return false

	var system: Node = system_value as Node

	if not is_instance_valid(system):
		return false

	var unlocked_value = system.get(
		"unlocked"
	)

	if typeof(unlocked_value) != TYPE_DICTIONARY:
		return false

	var unlocked: Dictionary = unlocked_value

	return bool(
		unlocked.get(
			weapon_id,
			false
		)
	)


func notify_weapon_picked(
	_weapon_id: String
) -> void:
	if not rooms.has(current_room):
		return

	var data: Dictionary = rooms[
		current_room
	]

	if str(data["type"]) == "treasure":
		data["reward_claimed"] = true
		rooms[current_room] = data


func _complete_current_room() -> void:
	if room_cleared:
		return

	room_cleared = true

	var data: Dictionary = rooms[
		current_room
	]

	data["cleared"] = true

	rooms[current_room] = data

	print(
		"ROOM CLEAR: ",
		current_room
	)

	_spawn_room_rewards()

	_update_ui()

	queue_redraw()


func _get_alive_enemy_count() -> int:
	var count := 0

	for enemy in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(enemy):
			continue

		if enemy.is_queued_for_deletion():
			continue

		count += 1

	return count


func _check_room_transition() -> void:
	if transition_cooldown > 0.0:
		return

	if not is_instance_valid(player):
		return

	var pos: Vector2 = player.position

	if (
		pos.x > 350.0
		and (
			Input.is_key_pressed(KEY_D)
			or Input.is_key_pressed(KEY_RIGHT)
		)
	):
		if _try_move_room(DIR_RIGHT):
			return

	if (
		pos.x < -350.0
		and (
			Input.is_key_pressed(KEY_A)
			or Input.is_key_pressed(KEY_LEFT)
		)
	):
		if _try_move_room(DIR_LEFT):
			return

	if (
		pos.y > 182.0
		and (
			Input.is_key_pressed(KEY_S)
			or Input.is_key_pressed(KEY_DOWN)
		)
	):
		if _try_move_room(DIR_DOWN):
			return

	if (
		pos.y < -182.0
		and (
			Input.is_key_pressed(KEY_W)
			or Input.is_key_pressed(KEY_UP)
		)
	):
		_try_move_room(DIR_UP)


func _try_move_room(
	direction: Vector2i
) -> bool:
	var target_room: Vector2i = (
		current_room
		+ direction
	)

	if not rooms.has(target_room):
		return false

	var entry_from := -direction

	_enter_room(
		target_room,
		entry_from
	)

	return true


func _place_player_at_entry(
	entry_from: Vector2i
) -> void:
	if entry_from == DIR_LEFT:
		player.position = Vector2(
			-330,
			0
		)

	elif entry_from == DIR_RIGHT:
		player.position = Vector2(
			330,
			0
		)

	elif entry_from == DIR_UP:
		player.position = Vector2(
			0,
			-165
		)

	elif entry_from == DIR_DOWN:
		player.position = Vector2(
			0,
			165
		)


func _clear_room_entities() -> void:
	_clear_group("enemies")
	_clear_group("enemy_bullets")
	_clear_group("player_bullets")
	_clear_group("room_pickups")


func _clear_group(group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(
		group_name
	):
		if is_instance_valid(node):
			node.queue_free()


func _update_ui() -> void:
	if is_instance_valid(minimap):
		minimap.call(
			"set_dungeon_state",
			rooms,
			current_room
		)

	if not is_instance_valid(room_label):
		return

	var data: Dictionary = rooms[
		current_room
	]

	var room_type: String = str(
		data["type"]
	).to_upper()

	var state_text := "OPEN"

	if not room_cleared:
		state_text = "LOCKED"

	room_label.text = (
		room_type
		+ " ROOM  "
		+ str(current_room)
		+ "\n"
		+ state_text
	)


func _has_neighbor(
	direction: Vector2i
) -> bool:
	return rooms.has(
		current_room
		+ direction
	)


func _draw() -> void:
	# Darkness outside room.
	draw_rect(
		Rect2(
			-2000,
			-2000,
			4000,
			4000
		),
		Color8(12, 12, 18),
		true
	)

	var floor_color := Color8(
		39,
		42,
		52
	)

	if rooms.has(current_room):
		var data: Dictionary = rooms[
			current_room
		]

		if str(data["type"]) == "treasure":
			floor_color = Color8(
				49,
				45,
				39
			)

	# Floor.
	draw_rect(
		ROOM_RECT,
		floor_color,
		true
	)

	# Tile grid.
	var grid_size := 32

	for x in range(
		int(ROOM_RECT.position.x),
		int(ROOM_RECT.end.x) + 1,
		grid_size
	):
		draw_line(
			Vector2(
				x,
				ROOM_RECT.position.y
			),
			Vector2(
				x,
				ROOM_RECT.end.y
			),
			Color8(48, 51, 63),
			1.0
		)

	for y in range(
		int(ROOM_RECT.position.y),
		int(ROOM_RECT.end.y) + 1,
		grid_size
	):
		draw_line(
			Vector2(
				ROOM_RECT.position.x,
				y
			),
			Vector2(
				ROOM_RECT.end.x,
				y
			),
			Color8(48, 51, 63),
			1.0
		)

	# Outer wall.
	draw_rect(
		ROOM_RECT,
		Color8(102, 91, 84),
		false,
		12.0
	)

	draw_rect(
		ROOM_RECT.grow(-12.0),
		Color8(58, 54, 58),
		false,
		4.0
	)

	if _has_neighbor(DIR_UP):
		_draw_door(
			DIR_UP,
			room_cleared
		)

	if _has_neighbor(DIR_DOWN):
		_draw_door(
			DIR_DOWN,
			room_cleared
		)

	if _has_neighbor(DIR_LEFT):
		_draw_door(
			DIR_LEFT,
			room_cleared
		)

	if _has_neighbor(DIR_RIGHT):
		_draw_door(
			DIR_RIGHT,
			room_cleared
		)


func _draw_door(
	direction: Vector2i,
	is_open: bool
) -> void:
	var locked_color := Color8(
		112,
		54,
		45
	)

	var open_color := Color8(
		225,
		184,
		78
	)

	var floor_color := Color8(
		39,
		42,
		52
	)

	if rooms.has(current_room):
		var data: Dictionary = rooms[
			current_room
		]

		if str(data["type"]) == "treasure":
			floor_color = Color8(
				49,
				45,
				39
			)

	if direction == DIR_UP:
		if is_open:
			draw_rect(
				Rect2(
					-31,
					ROOM_RECT.position.y - 9,
					62,
					22
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					-24,
					ROOM_RECT.position.y + 3,
					48,
					4
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					-30,
					ROOM_RECT.position.y - 7,
					60,
					17
				),
				locked_color,
				true
			)

	elif direction == DIR_DOWN:
		if is_open:
			draw_rect(
				Rect2(
					-31,
					ROOM_RECT.end.y - 13,
					62,
					22
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					-24,
					ROOM_RECT.end.y - 7,
					48,
					4
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					-30,
					ROOM_RECT.end.y - 10,
					60,
					17
				),
				locked_color,
				true
			)

	elif direction == DIR_LEFT:
		if is_open:
			draw_rect(
				Rect2(
					ROOM_RECT.position.x - 9,
					-31,
					22,
					62
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					ROOM_RECT.position.x + 3,
					-24,
					4,
					48
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					ROOM_RECT.position.x - 7,
					-30,
					17,
					60
				),
				locked_color,
				true
			)

	elif direction == DIR_RIGHT:
		if is_open:
			draw_rect(
				Rect2(
					ROOM_RECT.end.x - 13,
					-31,
					22,
					62
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					ROOM_RECT.end.x - 7,
					-24,
					4,
					48
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					ROOM_RECT.end.x - 10,
					-30,
					17,
					60
				),
				locked_color,
				true
			)