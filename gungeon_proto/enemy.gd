extends Node2D

const EnemyBulletScript = preload(
	"res://gungeon_proto/enemy_bullet.gd"
)

var health := 4

var move_speed := 42.0
var preferred_distance := 105.0

var fire_interval := 1.15
var fire_timer := 0.8

var hit_flash := 0.0


func _ready() -> void:
	add_to_group("enemies")

	# Gives enemies slightly different initial shot timing.
	fire_timer += absf(position.x + position.y) / 900.0

	queue_redraw()


func _process(delta: float) -> void:
	hit_flash = maxf(0.0, hit_flash - delta)
	fire_timer = maxf(0.0, fire_timer - delta)

	var target = get_tree().get_first_node_in_group("player")

	if not is_instance_valid(target):
		queue_redraw()
		return

	var to_player: Vector2 = (
		target.global_position
		- global_position
	)

	var distance := to_player.length()

	if distance > preferred_distance:
		global_position += (
			to_player.normalized()
			* move_speed
			* delta
		)

	elif distance < preferred_distance * 0.65:
		global_position -= (
			to_player.normalized()
			* move_speed
			* 0.55
			* delta
		)

	global_position.x = clampf(
		global_position.x,
		-350.0,
		350.0
	)

	global_position.y = clampf(
		global_position.y,
		-180.0,
		180.0
	)

	if fire_timer <= 0.0 and distance < 330.0:
		_shoot(target)
		fire_timer = fire_interval

	queue_redraw()


func _shoot(target: Node2D) -> void:
	var direction: Vector2 = (
		target.global_position
		- global_position
	).normalized()

	var bullet = EnemyBulletScript.new()

	bullet.direction = direction

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = (
		global_position
		+ direction * 14.0
	)


func take_damage(amount: int) -> void:
	health -= amount
	hit_flash = 0.08

	if health <= 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	# Shadow.
	draw_rect(
		Rect2(-9, 8, 18, 5),
		Color8(10, 10, 14, 150),
		true
	)

	var body_color := Color8(190, 55, 62)

	if hit_flash > 0.0:
		body_color = Color8(255, 235, 220)

	# Body.
	draw_rect(
		Rect2(-8, -8, 16, 17),
		body_color,
		true
	)

	# Forehead.
	draw_rect(
		Rect2(-6, -7, 12, 5),
		Color8(225, 80, 72),
		true
	)

	# Angry eyes.
	draw_rect(
		Rect2(-5, -1, 3, 2),
		Color8(30, 15, 20),
		true
	)

	draw_rect(
		Rect2(2, -1, 3, 2),
		Color8(30, 15, 20),
		true
	)

	# Weapon.
	draw_rect(
		Rect2(7, -1, 8, 4),
		Color8(90, 78, 74),
		true
	)

	# Health pixels.
	for i in range(health):
		draw_rect(
			Rect2(
				-8 + i * 4,
				-14,
				3,
				2
			),
			Color8(108, 220, 112),
			true
		)