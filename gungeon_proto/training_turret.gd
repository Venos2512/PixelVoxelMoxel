extends Node2D

const TrainingBulletScript = preload(
	"res://gungeon_proto/training_test_bullet.gd"
)

var enabled: bool = true

var fire_interval: float = 0.72
var fire_timer: float = 0.25

var bullet_speed: float = 285.0

var aim_direction: Vector2 = Vector2.LEFT


func _ready() -> void:
	z_index = 18

	add_to_group(
		"training_turrets"
	)

	queue_redraw()


func _process(
	delta: float
) -> void:
	if not enabled:
		return

	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	var direction_to_player: Vector2 = (
		player.global_position
		- global_position
	)

	if direction_to_player.length_squared() > 0.001:
		aim_direction = (
			direction_to_player.normalized()
		)

	rotation = aim_direction.angle()

	fire_timer -= delta

	if fire_timer <= 0.0:
		fire_timer = fire_interval

		_fire()

	queue_redraw()


func set_enabled(
	value: bool
) -> void:
	enabled = value

	fire_timer = 0.15

	queue_redraw()


func is_enabled() -> bool:
	return enabled


func _fire() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var bullet: Node2D = (
		TrainingBulletScript.new()
		as Node2D
	)

	if not is_instance_valid(
		bullet
	):
		return

	scene.add_child(
		bullet
	)

	bullet.global_position = (
		global_position
		+ aim_direction * 28.0
	)

	bullet.call(
		"configure",
		aim_direction,
		bullet_speed
	)


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


func _draw() -> void:
	# Base.
	draw_circle(
		Vector2.ZERO,
		23.0,
		Color(
			0.16,
			0.17,
			0.20,
			1.0
		)
	)

	draw_circle(
		Vector2.ZERO,
		18.0,
		Color(
			0.32,
			0.34,
			0.38,
			1.0
		)
	)

	# Barrel hướng theo local +X.
	draw_rect(
		Rect2(
			5.0,
			-6.0,
			29.0,
			12.0
		),
		Color(
			0.24,
			0.25,
			0.29,
			1.0
		),
		true
	)

	draw_rect(
		Rect2(
			30.0,
			-8.0,
			9.0,
			16.0
		),
		Color(
			0.10,
			0.10,
			0.12,
			1.0
		),
		true
	)

	var indicator_color: Color = Color(
		0.20,
		1.0,
		0.32,
		1.0
	)

	if not enabled:
		indicator_color = Color(
			0.48,
			0.48,
			0.50,
			1.0
		)

	draw_circle(
		Vector2.ZERO,
		5.0,
		indicator_color
	)