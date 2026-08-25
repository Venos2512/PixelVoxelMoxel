extends Node2D

const PlayerScript = preload(
	"res://gungeon_proto/player.gd"
)

const EnemyScript = preload(
	"res://gungeon_proto/enemy_m5.gd"
)

const BossScript = preload(
	"res://gungeon_proto/boss_m5.gd"
)

const WeaponPickupScript = preload(
	"res://gungeon_proto/weapon_pickup.gd"
)

const FloorExitScript = preload(
	"res://gungeon_proto/floor_exit.gd"
)

const UpgradeChestScript = preload(
	"res://gungeon_proto/upgrade_chest.gd"
)

const UpgradeChoiceUIScript = preload(
	"res://gungeon_proto/upgrade_choice_ui.gd"
)

const CoinPickupScript = preload(
	"res://gungeon_proto/coin_pickup.gd"
)

const ShopItemScript = preload(
	"res://gungeon_proto/shop_item.gd"
)

const RoomPropScript = preload(
	"res://gungeon_proto/carryable_prop_v3.gd"
)

const RoomFXScript = preload(
	"res://gungeon_proto/room_fx.gd"
)

const DamageNumberScript = preload(
	"res://gungeon_proto/damage_number.gd"
)

const RoomWallScript = preload(
	"res://gungeon_proto/room_wall.gd"
)

const ExplosiveBarrelScript = preload(
	"res://gungeon_proto/carryable_explosive_barrel_v3.gd"
)

const SpikeTrapScript = preload(
	"res://gungeon_proto/spike_trap.gd"
)

const SawTrapScript = preload(
	"res://gungeon_proto/saw_trap.gd"
)

const RoomNavigationScript = preload(
	"res://gungeon_proto/room_navigation.gd"
)

const WeaponIconHudScript = preload(
	"res://gungeon_proto/weapon_stack_hud_v2.gd"
)

const ReloadProgressWorldScript = preload(
	"res://gungeon_proto/reload_progress_world.gd"
)

const MinimapTopRightAnchorScript = preload(
	"res://gungeon_proto/minimap_top_right_anchor.gd"
)

const DevToolsScript = preload(
	"res://gungeon_proto/dev_tools.gd"
)

const WeaponSpecialControllerScript = preload(
	"res://gungeon_proto/weapon_special_controller.gd"
)

const RelicSystemScript = preload(
	"res://gungeon_proto/relic_system.gd"
)

const MainMenuOverlayScript = preload(
	"res://gungeon_proto/main_menu_overlay.gd"
)

const RoomBoundaryBlockerScript = preload(
	"res://gungeon_proto/room_boundary_blocker.gd"
)

const EncounterDirectorScript = preload(
	"res://gungeon_proto/encounter_director.gd"
)

const DungeonMiniMapScript = preload(
	"res://gungeon_proto/dungeon_minimap_m5.gd"
)

const ROOM_RECT := Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)

const BASE_ROOM_COUNT := 8

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

var floor_number: int = 1

var rooms: Dictionary = {}

var current_room := Vector2i.ZERO
var room_cleared: bool = true

var transition_cooldown: float = 0.0

var player: CharacterBody2D

var minimap: Control
var room_label: Label

var boss_bar: ProgressBar
var boss_label: Label

var upgrade_choice_ui: Control

var gold_label: Label

var room_navigation: Node
var encounter_director: Node

var hit_stop_serial: int = 0


func _ready() -> void:
	randomize()

	var weapon_icon_hud: CanvasLayer = (
		WeaponIconHudScript.new()
		as CanvasLayer
	)

	add_child(
		weapon_icon_hud
	)

	var reload_progress_world: Node2D = (
		ReloadProgressWorldScript.new()
		as Node2D
	)

	add_child(
		reload_progress_world
	)

	var minimap_top_right_anchor: Node = (
		MinimapTopRightAnchorScript.new()
	)

	add_child(
		minimap_top_right_anchor
	)

	var dev_tools: CanvasLayer = (
		DevToolsScript.new()
		as CanvasLayer
	)

	add_child(
		dev_tools
	)

	var weapon_special_controller: Node = (
		WeaponSpecialControllerScript.new()
	)

	add_child(
		weapon_special_controller
	)

	room_navigation = RoomNavigationScript.new()

	add_child(
		room_navigation
	)

	room_navigation.call(
		"configure",
		ROOM_RECT
	)

	var relic_system_instance: Node = (
		RelicSystemScript.new()
	)

	add_child(
		relic_system_instance
	)

	var main_menu_instance: Node = (
		MainMenuOverlayScript.new()
	)

	add_child(
		main_menu_instance
	)

	var room_boundary_blocker: Node2D = (
		RoomBoundaryBlockerScript.new()
		as Node2D
	)

	add_child(
		room_boundary_blocker
	)

	room_boundary_blocker.call(
		"configure",
		ROOM_RECT
	)

	encounter_director = (
		EncounterDirectorScript.new()
	)

	add_child(
		encounter_director
	)

	encounter_director.call(
		"setup",
		self
	)

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

	_start_floor()


func get_enemy_navigation_direction(
	from_position: Vector2,
	target_position: Vector2,
	agent_radius: float = 10.0
) -> Vector2:
	if not is_instance_valid(
		room_navigation
	):
		var direct: Vector2 = (
			target_position
			- from_position
		)

		if direct.length_squared() <= 1.0:
			return Vector2.ZERO

		return direct.normalized()

	var result = room_navigation.call(
		"get_move_direction",
		from_position,
		target_position,
		agent_radius
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return Vector2.ZERO


func enemy_has_line_of_sight(
	from_position: Vector2,
	target_position: Vector2,
	radius: float = 6.0
) -> bool:
	if not is_instance_valid(
		room_navigation
	):
		return true

	return bool(
		room_navigation.call(
			"has_line_of_sight",
			from_position,
			target_position,
			radius
		)
	)


func is_enemy_position_walkable(
	position_value: Vector2,
	radius: float = 10.0
) -> bool:
	if not is_instance_valid(
		room_navigation
	):
		return true

	return bool(
		room_navigation.call(
			"is_position_walkable",
			position_value,
			radius
		)
	)


func get_enemy_tactical_position(
	from_position: Vector2,
	target_position: Vector2,
	desired_distance: float,
	radius: float = 10.0
) -> Vector2:
	if not is_instance_valid(
		room_navigation
	):
		return target_position

	var result = room_navigation.call(
		"find_tactical_position",
		from_position,
		target_position,
		desired_distance,
		radius
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return target_position


func find_nearest_walkable_enemy_position(
	position_value: Vector2,
	radius: float = 10.0
) -> Vector2:
	if not is_instance_valid(
		room_navigation
	):
		return position_value

	var result = room_navigation.call(
		"find_nearest_walkable_position",
		position_value,
		radius
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return position_value


func find_safe_enemy_spawn_position(
	desired_position: Vector2,
	radius: float = 12.0,
	minimum_player_distance: float = 65.0
) -> Vector2:
	var candidates: Array[Vector2] = [
		desired_position
	]

	var ring_distances := [
		30.0,
		55.0,
		85.0,
		115.0
	]

	for ring_value in ring_distances:
		var ring: float = float(
			ring_value
		)

		for i in range(12):
			var angle: float = (
				TAU
				* float(i)
				/ 12.0
			)

			candidates.append(
				desired_position
				+ Vector2(
					cos(angle),
					sin(angle)
				) * ring
			)

	for candidate in candidates:
		if not is_enemy_position_walkable(
			candidate,
			radius
		):
			continue

		if (
			is_instance_valid(player)
			and minimum_player_distance > 0.0
		):
			if candidate.distance_to(
				player.global_position
			) < minimum_player_distance:
				continue

		var occupied: bool = false

		for enemy_value in get_tree().get_nodes_in_group(
			"enemies"
		):
			if not is_instance_valid(enemy_value):
				continue

			if enemy_value.is_queued_for_deletion():
				continue

			var enemy: Node2D = (
				enemy_value as Node2D
			)

			if not is_instance_valid(enemy):
				continue

			if candidate.distance_to(
				enemy.global_position
			) < radius * 2.6:
				occupied = true
				break

		if not occupied:
			return candidate

	return find_nearest_walkable_enemy_position(
		desired_position,
		radius
	)


func spawn_damage_number(
	pos: Vector2,
	amount: int,
	is_player_damage: bool = false
) -> void:
	var number = DamageNumberScript.new()

	number.amount = amount
	number.is_player_damage = is_player_damage

	add_child(number)

	number.global_position = pos


func request_camera_shake(
	amount: float
) -> void:
	if not is_instance_valid(player):
		return

	if player.has_method(
		"add_camera_shake"
	):
		player.call(
			"add_camera_shake",
			amount
		)


func request_hit_stop(
	duration: float,
	slow_scale: float = 0.16
) -> void:
	hit_stop_serial += 1

	var serial: int = hit_stop_serial

	Engine.time_scale = minf(
		Engine.time_scale,
		slow_scale
	)

	await get_tree().create_timer(
		duration,
		true,
		false,
		true
	).timeout

	if serial == hit_stop_serial:
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	transition_cooldown = maxf(
		0.0,
		transition_cooldown - delta
	)

	_update_boss_bar()
	_update_gold_ui()

	if not room_cleared:
		if _get_alive_enemy_count() <= 0:
			_complete_current_room()

	if room_cleared:
		_check_room_transition()


func _start_floor() -> void:
	_clear_room_entities()

	_generate_dungeon()

	current_room = Vector2i.ZERO

	player.position = Vector2.ZERO

	_enter_room(
		Vector2i.ZERO,
		Vector2i.ZERO
	)

	print(
		"ENTER FLOOR ",
		floor_number
	)


func advance_floor() -> void:
	floor_number += 1

	_heal_player_between_floors()

	_start_floor()


func _heal_player_between_floors() -> void:
	var max_health_value: int = int(
		player.get("max_health")
	)

	var health_value: int = int(
		player.get("health")
	)

	health_value = mini(
		max_health_value,
		health_value + 1
	)

	player.set(
		"health",
		health_value
	)


func _generate_dungeon() -> void:
	rooms.clear()

	rooms[Vector2i.ZERO] = {
		"type": "start",
		"visited": true,
		"cleared": true,
		"enemy_count": 0,
		"reward_claimed": false,
		"layout_id": 0,
		"broken_props": []
	}

	var positions: Array[Vector2i] = [
		Vector2i.ZERO
	]

	var target_room_count: int = (
		BASE_ROOM_COUNT
		+ mini(
			floor_number - 1,
			3
		)
	)

	var attempts: int = 0

	while (
		positions.size() < target_room_count
		and attempts < 500
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

		var difficulty_bonus: int = int(
			floor_number / 2.0
		)

		var enemy_count: int = clampi(
			2
			+ distance
			+ difficulty_bonus
			+ randi_range(0, 1),
			2,
			7
		)

		rooms[candidate] = {
			"type": "combat",
			"visited": false,
			"cleared": false,
			"enemy_count": enemy_count,
			"reward_claimed": false,
			"layout_id": randi_range(0, 5),
			"broken_props": []
		}

		positions.append(candidate)

	var boss_room := _find_farthest_room(
		positions,
		[]
	)

	var treasure_room := _find_farthest_room(
		positions,
		[boss_room]
	)

	var elite_room := _find_farthest_room(
		positions,
		[
			boss_room,
			treasure_room
		]
	)

	_set_room_type(
		boss_room,
		"boss"
	)

	_set_room_type(
		treasure_room,
		"treasure"
	)

	_set_room_type(
		elite_room,
		"elite"
	)

	var shop_room := _find_farthest_room(
		positions,
		[
			boss_room,
			treasure_room,
			elite_room
		]
	)

	_set_room_type(
		shop_room,
		"shop"
	)

	if rooms.has(shop_room):
		var shop_data: Dictionary = rooms[
			shop_room
		]

		shop_data["cleared"] = true
		shop_data["enemy_count"] = 0
		shop_data["shop_offers"] = []

		rooms[shop_room] = shop_data


func _find_farthest_room(
	positions: Array[Vector2i],
	excluded: Array
) -> Vector2i:
	var best_room := Vector2i.ZERO
	var best_distance := -1

	for room_pos in positions:
		if room_pos == Vector2i.ZERO:
			continue

		if excluded.has(room_pos):
			continue

		var distance: int = (
			abs(room_pos.x)
			+ abs(room_pos.y)
		)

		if distance > best_distance:
			best_distance = distance
			best_room = room_pos

	return best_room


func _set_room_type(
	room_position: Vector2i,
	room_type: String
) -> void:
	if not rooms.has(room_position):
		return

	var data: Dictionary = rooms[
		room_position
	]

	data["type"] = room_type

	rooms[room_position] = data


func _create_ui() -> void:
	var canvas := CanvasLayer.new()

	canvas.name = "DungeonUI"

	add_child(canvas)

	minimap = DungeonMiniMapScript.new() as Control
	minimap.position = Vector2(10, 10)

	canvas.add_child(minimap)

	room_label = Label.new()

	room_label.position = Vector2(10, 118)
	room_label.size = Vector2(260, 50)

	room_label.add_theme_font_size_override(
		"font_size",
		11
	)

	canvas.add_child(room_label)

	boss_label = Label.new()

	boss_label.position = Vector2(220, 6)
	boss_label.size = Vector2(330, 20)

	boss_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	boss_label.add_theme_font_size_override(
		"font_size",
		12
	)

	canvas.add_child(boss_label)

	boss_bar = ProgressBar.new()

	boss_bar.position = Vector2(220, 28)
	boss_bar.size = Vector2(330, 18)

	boss_bar.min_value = 0.0
	boss_bar.max_value = 100.0
	boss_bar.value = 100.0

	boss_bar.show_percentage = false

	canvas.add_child(boss_bar)

	boss_bar.visible = false
	boss_label.visible = false

	upgrade_choice_ui = (
		UpgradeChoiceUIScript.new()
		as Control
	)

	canvas.add_child(
		upgrade_choice_ui
	)

	gold_label = Label.new()

	gold_label.anchor_left = 1.0
	gold_label.anchor_right = 1.0

	gold_label.offset_left = -190.0
	gold_label.offset_right = -15.0
	gold_label.offset_top = 170.0
	gold_label.offset_bottom = 200.0

	gold_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	gold_label.add_theme_font_size_override(
		"font_size",
		13
	)

	canvas.add_child(
		gold_label
	)


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

	_spawn_room_layout(data)

	if not room_cleared:
		_spawn_room_encounter(data)
	else:
		_spawn_room_rewards()

	transition_cooldown = 0.28

	_update_ui()

	queue_redraw()


func _spawn_room_encounter(
	data: Dictionary
) -> void:
	var room_type: String = str(
		data["type"]
	)

	match room_type:
		"boss":
			_spawn_boss()

		"elite":
			_spawn_elite_wave()

		_:
			_spawn_wave(
				int(data["enemy_count"])
			)


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

	var types := [
		"gunner",
		"chaser",
		"spread"
	]

	for i in range(amount):
		var enemy_type: String = types[
			randi_range(
				0,
				types.size() - 1
			)
		]

		_spawn_enemy(
			spawn_points[i],
			enemy_type
		)


func _spawn_elite_wave() -> void:
	_spawn_enemy(
		Vector2(0, -60),
		"elite"
	)

	_spawn_enemy(
		Vector2(-180, 85),
		"chaser"
	)

	_spawn_enemy(
		Vector2(180, 85),
		"spread"
	)


func spawn_director_enemy(
	pos: Vector2,
	enemy_type: String
) -> void:
	_spawn_enemy(
		pos,
		enemy_type
	)


func _spawn_enemy(
	pos: Vector2,
	enemy_type: String
) -> void:
	var safe_position: Vector2 = (
		find_safe_enemy_spawn_position(
			pos,
			13.0,
			72.0
		)
	)

	var enemy = EnemyScript.new()

	enemy.enemy_type = enemy_type

	add_child(enemy)

	enemy.global_position = safe_position


func _spawn_boss() -> void:
	var safe_position: Vector2 = (
		find_safe_enemy_spawn_position(
			Vector2(0, -70),
			32.0,
			125.0
		)
	)

	var boss = BossScript.new()

	boss.boss_floor = floor_number

	add_child(boss)

	boss.global_position = safe_position


func _spawn_weapon_pickup(
	weapon_id: String,
	pos: Vector2
) -> void:
	var pickup = WeaponPickupScript.new()

	pickup.weapon_id = weapon_id

	add_child(pickup)

	pickup.position = pos


func _spawn_floor_exit() -> void:
	var exit = FloorExitScript.new()

	add_child(exit)

	exit.position = Vector2.ZERO

	spawn_room_fx(
		Vector2.ZERO,
		"portal"
	)


func _spawn_upgrade_chest(
	pos: Vector2,
	source_type: String
) -> void:
	var chest = UpgradeChestScript.new()

	chest.source_type = source_type

	add_child(chest)

	chest.position = pos

	spawn_room_fx(
		pos,
		"reward"
	)


func spawn_room_fx(
	pos: Vector2,
	fx_type: String
) -> void:
	var fx = RoomFXScript.new()

	fx.fx_type = fx_type

	add_child(fx)

	fx.global_position = pos


func _spawn_room_layout(
	data: Dictionary
) -> void:
	var room_type: String = str(
		data["type"]
	)

	var layout_id: int = int(
		data.get(
			"layout_id",
			0
		)
	)

	match room_type:
		"start":
			_spawn_prop(
				Vector2(-265, -130),
				"pot",
				"start_pot_a"
			)

			_spawn_prop(
				Vector2(265, -130),
				"pot",
				"start_pot_b"
			)

			_spawn_prop(
				Vector2(-265, 135),
				"crate",
				"start_crate_a"
			)

		"shop":
			_spawn_prop(
				Vector2(-245, -105),
				"table",
				"shop_table_a"
			)

			_spawn_prop(
				Vector2(245, -105),
				"table",
				"shop_table_b"
			)

			_spawn_prop(
				Vector2(-280, 130),
				"pot",
				"shop_pot_a"
			)

			_spawn_prop(
				Vector2(280, 130),
				"pot",
				"shop_pot_b"
			)

		"treasure":
			_spawn_prop(
				Vector2(-170, -95),
				"crate",
				"treasure_crate_a"
			)

			_spawn_prop(
				Vector2(170, -95),
				"crate",
				"treasure_crate_b"
			)

			_spawn_prop(
				Vector2(-215, 105),
				"pot",
				"treasure_pot_a"
			)

			_spawn_prop(
				Vector2(215, 105),
				"pot",
				"treasure_pot_b"
			)

		"elite":
			_spawn_prop(
				Vector2(-135, 0),
				"pillar",
				"elite_pillar_a"
			)

			_spawn_prop(
				Vector2(135, 0),
				"pillar",
				"elite_pillar_b"
			)

			_spawn_prop(
				Vector2(0, 120),
				"crate",
				"elite_crate_a"
			)

			_spawn_explosive_barrel(
				Vector2(-215, 100),
				"elite_barrel_a"
			)

			_spawn_explosive_barrel(
				Vector2(215, 100),
				"elite_barrel_b"
			)

		"boss":
			_spawn_prop(
				Vector2(-270, -125),
				"pillar",
				"boss_pillar_a"
			)

			_spawn_prop(
				Vector2(270, -125),
				"pillar",
				"boss_pillar_b"
			)

			_spawn_prop(
				Vector2(-270, 125),
				"pillar",
				"boss_pillar_c"
			)

			_spawn_prop(
				Vector2(270, 125),
				"pillar",
				"boss_pillar_d"
			)

			_spawn_explosive_barrel(
				Vector2(-205, 65),
				"boss_barrel_a"
			)

			_spawn_explosive_barrel(
				Vector2(205, 65),
				"boss_barrel_b"
			)

		_:
			if layout_id == 0:
				# Two-lane room.
				_spawn_wall(
					Vector2(-115, 0),
					Vector2(30, 190)
				)

				_spawn_wall(
					Vector2(115, 0),
					Vector2(30, 190)
				)

				_spawn_explosive_barrel(
					Vector2(0, -105),
					"layout0_barrel_a"
				)

				_spawn_explosive_barrel(
					Vector2(0, 105),
					"layout0_barrel_b"
				)

				_spawn_prop(
					Vector2(-230, 115),
					"crate",
					"layout0_crate_a"
				)

				_spawn_prop(
					Vector2(230, -115),
					"crate",
					"layout0_crate_b"
				)

			elif layout_id == 1:
				# Broken cross / four pockets.
				_spawn_wall(
					Vector2(-125, 0),
					Vector2(125, 24)
				)

				_spawn_wall(
					Vector2(125, 0),
					Vector2(125, 24)
				)

				_spawn_wall(
					Vector2(0, -92),
					Vector2(24, 95)
				)

				_spawn_wall(
					Vector2(0, 92),
					Vector2(24, 95)
				)

				_spawn_explosive_barrel(
					Vector2(-205, -105),
					"layout1_barrel_a"
				)

				_spawn_explosive_barrel(
					Vector2(205, 105),
					"layout1_barrel_b"
				)

				_spawn_prop(
					Vector2(205, -105),
					"crate",
					"layout1_crate_a"
				)

				_spawn_prop(
					Vector2(-205, 105),
					"crate",
					"layout1_crate_b"
				)

			elif layout_id == 2:
				# S-shaped route.
				_spawn_wall(
					Vector2(-105, -85),
					Vector2(220, 24)
				)

				_spawn_wall(
					Vector2(105, 85),
					Vector2(220, 24)
				)

				_spawn_wall(
					Vector2(0, 0),
					Vector2(24, 105)
				)

				_spawn_explosive_barrel(
					Vector2(-245, 85),
					"layout2_barrel_a"
				)

				_spawn_explosive_barrel(
					Vector2(245, -85),
					"layout2_barrel_b"
				)

				_spawn_prop(
					Vector2(-145, 125),
					"pot",
					"layout2_pot_a"
				)

				_spawn_prop(
					Vector2(145, -125),
					"pot",
					"layout2_pot_b"
				)

			elif layout_id == 3:
				# Central bunker + timed spikes.
				_spawn_wall(
					Vector2(0, -70),
					Vector2(170, 24)
				)

				_spawn_wall(
					Vector2(0, 70),
					Vector2(170, 24)
				)

				_spawn_wall(
					Vector2(-72, 0),
					Vector2(24, 115)
				)

				_spawn_wall(
					Vector2(72, 0),
					Vector2(24, 115)
				)

				_spawn_explosive_barrel(
					Vector2(0, 0),
					"layout3_barrel_center"
				)

				_spawn_spike_trap(
					Vector2(-145, 105)
				)

				_spawn_spike_trap(
					Vector2(145, -105)
				)

				_spawn_prop(
					Vector2(-235, -115),
					"crate",
					"layout3_crate_a"
				)

				_spawn_prop(
					Vector2(235, 115),
					"crate",
					"layout3_crate_b"
				)

			elif layout_id == 4:
				# Zig-zag lanes + moving saw.
				_spawn_wall(
					Vector2(-190, -75),
					Vector2(190, 24)
				)

				_spawn_wall(
					Vector2(190, 20),
					Vector2(190, 24)
				)

				_spawn_wall(
					Vector2(-190, 110),
					Vector2(190, 24)
				)

				_spawn_explosive_barrel(
					Vector2(120, -110),
					"layout4_barrel_a"
				)

				_spawn_explosive_barrel(
					Vector2(-105, 60),
					"layout4_barrel_b"
				)

				_spawn_saw_trap(
					Vector2(-250, 0),
					Vector2(250, 0)
				)

				_spawn_prop(
					Vector2(250, 120),
					"pot",
					"layout4_pot_a"
				)

			else:
				# Dense cover field + mixed hazards.
				_spawn_wall(
					Vector2(-165, -70),
					Vector2(90, 24)
				)

				_spawn_wall(
					Vector2(0, 70),
					Vector2(90, 24)
				)

				_spawn_wall(
					Vector2(165, -70),
					Vector2(90, 24)
				)

				_spawn_prop(
					Vector2(-220, 80),
					"pillar",
					"layout5_pillar_a"
				)

				_spawn_prop(
					Vector2(220, 80),
					"pillar",
					"layout5_pillar_b"
				)

				_spawn_explosive_barrel(
					Vector2(-70, -115),
					"layout5_barrel_a"
				)

				_spawn_explosive_barrel(
					Vector2(70, 115),
					"layout5_barrel_b"
				)

				_spawn_explosive_barrel(
					Vector2(0, 0),
					"layout5_barrel_c"
				)

				_spawn_spike_trap(
					Vector2(-135, 70)
				)

				_spawn_spike_trap(
					Vector2(135, -70)
				)

				_spawn_saw_trap(
					Vector2(-250, 145),
					Vector2(250, 145)
				)


func _spawn_wall(
	pos: Vector2,
	size: Vector2
) -> void:
	var wall = RoomWallScript.new()

	wall.wall_size = size

	add_child(wall)

	wall.position = pos


func _spawn_spike_trap(
	pos: Vector2
) -> void:
	var trap = SpikeTrapScript.new()

	add_child(trap)

	trap.position = pos


func _spawn_saw_trap(
	from_pos: Vector2,
	to_pos: Vector2
) -> void:
	var trap = SawTrapScript.new()

	trap.start_position = from_pos
	trap.end_position = to_pos

	add_child(trap)


func _spawn_explosive_barrel(
	pos: Vector2,
	prop_id: String
) -> void:
	if not rooms.has(current_room):
		return

	var data: Dictionary = rooms[
		current_room
	]

	var broken_value = data.get(
		"broken_props",
		[]
	)

	if typeof(broken_value) == TYPE_ARRAY:
		for broken_id_value in broken_value:
			if str(broken_id_value) == prop_id:
				return

	var barrel = ExplosiveBarrelScript.new()

	barrel.prop_id = prop_id

	add_child(barrel)

	barrel.position = pos


func _spawn_prop(
	pos: Vector2,
	prop_type: String,
	prop_id: String
) -> void:
	if not rooms.has(current_room):
		return

	var data: Dictionary = rooms[
		current_room
	]

	var broken_value = data.get(
		"broken_props",
		[]
	)

	if typeof(broken_value) == TYPE_ARRAY:
		for broken_id_value in broken_value:
			if str(broken_id_value) == prop_id:
				return

	var prop = RoomPropScript.new()

	prop.prop_type = prop_type
	prop.prop_id = prop_id

	add_child(prop)

	prop.position = pos


func notify_prop_destroyed(
	prop_id: String
) -> void:
	if prop_id == "":
		return

	if not rooms.has(current_room):
		return

	var data: Dictionary = rooms[
		current_room
	]

	var broken: Array = []

	var broken_value = data.get(
		"broken_props",
		[]
	)

	if typeof(broken_value) == TYPE_ARRAY:
		broken = broken_value

	if not broken.has(prop_id):
		broken.append(prop_id)

	data["broken_props"] = broken

	rooms[current_room] = data


func spawn_currency_drop(
	pos: Vector2,
	amount: int
) -> void:
	var coin = CoinPickupScript.new()

	coin.amount = amount

	add_child(coin)

	coin.global_position = (
		pos
		+ Vector2(
			randf_range(-8.0, 8.0),
			randf_range(-8.0, 8.0)
		)
	)


func _get_upgrade_system() -> Node:
	if not is_instance_valid(player):
		return null

	var value = player.get(
		"upgrade_system"
	)

	if value == null:
		return null

	return value as Node


func _spawn_shop() -> void:
	var system: Node = _get_upgrade_system()

	if not is_instance_valid(system):
		return

	var data: Dictionary = rooms[
		current_room
	]

	var offers: Array[String] = []

	var stored_value = data.get(
		"shop_offers",
		[]
	)

	if typeof(stored_value) == TYPE_ARRAY:
		for offer_value in stored_value:
			offers.append(
				str(offer_value)
			)

	if offers.is_empty():
		var result = system.call(
			"get_random_choices",
			3,
			"shop"
		)

		if typeof(result) == TYPE_ARRAY:
			for offer_value in result:
				offers.append(
					str(offer_value)
				)

		data["shop_offers"] = offers

		rooms[current_room] = data

	var positions: Array[Vector2] = [
		Vector2(-145, 20),
		Vector2(0, 20),
		Vector2(145, 20)
	]

	for i in range(offers.size()):
		if i >= positions.size():
			break

		var upgrade_id: String = offers[i]

		if upgrade_id == "":
			continue

		var info_value = system.call(
			"get_upgrade_info",
			upgrade_id
		)

		if typeof(info_value) != TYPE_DICTIONARY:
			continue

		var info: Dictionary = info_value

		var rarity: String = str(
			info["rarity"]
		)

		var cost: int = _get_shop_price(
			rarity
		)

		var item = ShopItemScript.new()

		item.upgrade_id = upgrade_id
		item.display_name = str(
			info["name"]
		)

		item.rarity = rarity
		item.cost = cost

		add_child(item)

		item.position = positions[i]


func _get_shop_price(
	rarity: String
) -> int:
	var base_price: int = 15

	if rarity == "RARE":
		base_price = 28

	elif rarity == "EPIC":
		base_price = 45

	return (
		base_price
		+ maxi(
			0,
			floor_number - 1
		) * 3
	)


func try_purchase_upgrade(
	upgrade_id: String,
	cost: int
) -> bool:
	if not is_instance_valid(player):
		return false

	if not player.has_method(
		"spend_gold"
	):
		return false

	var paid: bool = bool(
		player.call(
			"spend_gold",
			cost
		)
	)

	if not paid:
		print(
			"NOT ENOUGH GOLD"
		)

		return false

	var system: Node = _get_upgrade_system()

	if not is_instance_valid(system):
		player.call(
			"add_gold",
			cost
		)

		return false

	system.call(
		"apply_upgrade",
		upgrade_id
	)

	if rooms.has(current_room):
		var data: Dictionary = rooms[
			current_room
		]

		var offers_value = data.get(
			"shop_offers",
			[]
		)

		if typeof(offers_value) == TYPE_ARRAY:
			var offers: Array = offers_value

			for i in range(offers.size()):
				if str(offers[i]) == upgrade_id:
					offers[i] = ""
					break

			data["shop_offers"] = offers

			rooms[current_room] = data

	return true


func open_upgrade_choice(
	source_type: String = "normal"
) -> void:
	if not is_instance_valid(
		upgrade_choice_ui
	):
		return

	var system_value = player.get(
		"upgrade_system"
	)

	if system_value == null:
		return

	var system: Node = system_value as Node

	if not is_instance_valid(system):
		return

	upgrade_choice_ui.call(
		"open_for_system",
		system,
		source_type
	)


func notify_upgrade_chest_opened() -> void:
	if not rooms.has(current_room):
		return

	var data: Dictionary = rooms[
		current_room
	]

	data["reward_claimed"] = true

	rooms[current_room] = data


func _spawn_room_rewards() -> void:
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

		if not _player_has_weapon("sword"):
			_spawn_weapon_pickup(
				"sword",
				Vector2(0, 115)
			)

		return

	var data: Dictionary = rooms[
		current_room
	]

	var room_type: String = str(
		data["type"]
	)

	if room_type == "shop":
		_spawn_shop()
		return

	if room_type == "boss":
		if not bool(data["reward_claimed"]):
			_spawn_upgrade_chest(
				Vector2(-75, 0),
				"boss"
			)

		_spawn_floor_exit()
		return

	if room_type == "elite":
		if not bool(data["reward_claimed"]):
			_spawn_upgrade_chest(
				Vector2.ZERO,
				"elite"
			)

		return

	if room_type != "treasure":
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

	if not _player_has_weapon("sword"):
		_spawn_weapon_pickup(
			"sword",
			Vector2.ZERO
		)
		return

	_spawn_upgrade_chest(
		Vector2.ZERO,
		"treasure"
	)


func _grant_elite_reward() -> void:
	var max_health_value: int = int(
		player.get("max_health")
	)

	var health_value: int = int(
		player.get("health")
	)

	health_value = mini(
		max_health_value,
		health_value + 1
	)

	player.set(
		"health",
		health_value
	)


func _player_has_weapon(
	weapon_id: String
) -> bool:
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

	spawn_room_fx(
		Vector2.ZERO,
		"clear"
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


func _update_gold_ui() -> void:
	if not is_instance_valid(gold_label):
		return

	if not is_instance_valid(player):
		return

	var gold: int = 0

	if player.has_method("get_gold"):
		gold = int(
			player.call("get_gold")
		)

	gold_label.text = (
		"GOLD  "
		+ str(gold)
	)


func _update_boss_bar() -> void:
	var boss_value = get_tree().get_first_node_in_group(
		"boss"
	)

	if not is_instance_valid(boss_value):
		boss_bar.visible = false
		boss_label.visible = false
		return

	var boss: Node = boss_value as Node

	var max_hp: int = int(
		boss.get("max_health")
	)

	var hp: int = int(
		boss.get("health")
	)

	boss_bar.visible = true
	boss_label.visible = true

	boss_bar.max_value = float(max_hp)
	boss_bar.value = float(hp)

	boss_label.text = (
		"FLOOR "
		+ str(floor_number)
		+ " BOSS"
	)


func _check_room_transition() -> void:
	if transition_cooldown > 0.0:
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
	var target_room := (
		current_room
		+ direction
	)

	if not rooms.has(target_room):
		return false

	_enter_room(
		target_room,
		-direction
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
	_clear_group("room_props")
	_clear_group("room_hazards")
	_clear_group("room_fx")


func _clear_group(
	group_name: String
) -> void:
	for node in get_tree().get_nodes_in_group(
		group_name
	):
		if is_instance_valid(node):
			node.queue_free()


func _update_ui() -> void:
	minimap.call(
		"set_dungeon_state",
		rooms,
		current_room
	)

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
		"FLOOR "
		+ str(floor_number)
		+ "  |  "
		+ room_type
		+ " ROOM "
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

		match str(data["type"]):
			"treasure":
				floor_color = Color8(
					49,
					45,
					39
				)

			"elite":
				floor_color = Color8(
					50,
					38,
					35
				)

			"boss":
				floor_color = Color8(
					45,
					30,
					37
				)

			"shop":
				floor_color = Color8(
					31,
					48,
					46
				)

	draw_rect(
		ROOM_RECT,
		floor_color,
		true
	)

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