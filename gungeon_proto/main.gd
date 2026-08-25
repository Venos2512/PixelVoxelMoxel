extends Node2D

const PlayerScript = preload("res://gungeon_proto/player.gd")
const EnemyScript = preload("res://gungeon_proto/enemy.gd")
const WeaponPickupScript = preload(
	"res://gungeon_proto/weapon_pickup.gd"
)

const ROOM_RECT := Rect2(-384.0, -216.0, 768.0, 432.0)

var room_cleared := false


func _ready() -> void:
	var player = PlayerScript.new()
	player.name = "Player"
	player.room_rect = ROOM_RECT.grow(-18.0)
	add_child(player)
	player.position = Vector2.ZERO

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

	_spawn_enemy(Vector2(180, -80))
	_spawn_enemy(Vector2(230, 70))
	_spawn_enemy(Vector2(-220, -100))

	_spawn_weapon_pickup(
		"shotgun",
		Vector2(-120, 95)
	)

	_spawn_weapon_pickup(
		"machine_gun",
		Vector2(120, 100)
	)

	queue_redraw()


func _process(_delta: float) -> void:
	if room_cleared:
		return

	if get_tree().get_nodes_in_group("enemies").is_empty():
		room_cleared = true
		queue_redraw()
		print("ROOM CLEAR!")


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


func _draw() -> void:
	# Outside darkness.
	draw_rect(
		Rect2(-2000, -2000, 4000, 4000),
		Color8(12, 12, 18),
		true
	)

	# Room floor.
	draw_rect(
		ROOM_RECT,
		Color8(39, 42, 52),
		true
	)

	# Pixel floor grid.
	var grid_size := 32

	for x in range(
		int(ROOM_RECT.position.x),
		int(ROOM_RECT.end.x) + 1,
		grid_size
	):
		draw_line(
			Vector2(x, ROOM_RECT.position.y),
			Vector2(x, ROOM_RECT.end.y),
			Color8(48, 51, 63),
			1.0
		)

	for y in range(
		int(ROOM_RECT.position.y),
		int(ROOM_RECT.end.y) + 1,
		grid_size
	):
		draw_line(
			Vector2(ROOM_RECT.position.x, y),
			Vector2(ROOM_RECT.end.x, y),
			Color8(48, 51, 63),
			1.0
		)

	# Thick dungeon walls.
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

	# Top / bottom dungeon doors.
	if room_cleared:
		# Erase part of the wall to visually open the doors.
		draw_rect(
			Rect2(-30, ROOM_RECT.position.y - 8, 60, 20),
			Color8(39, 42, 52),
			true
		)

		draw_rect(
			Rect2(-30, ROOM_RECT.end.y - 12, 60, 20),
			Color8(39, 42, 52),
			true
		)

		draw_rect(
			Rect2(-22, ROOM_RECT.position.y + 4, 44, 4),
			Color8(225, 184, 78),
			true
		)

		draw_rect(
			Rect2(-22, ROOM_RECT.end.y - 8, 44, 4),
			Color8(225, 184, 78),
			true
		)
	else:
		draw_rect(
			Rect2(-28, ROOM_RECT.position.y - 5, 56, 14),
			Color8(80, 58, 49),
			true
		)

		draw_rect(
			Rect2(-28, ROOM_RECT.end.y - 9, 56, 14),
			Color8(80, 58, 49),
			true
		)