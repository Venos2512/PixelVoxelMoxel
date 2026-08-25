extends StaticBody2D

var prop_type: String = "crate"
var prop_id: String = ""

var health: int = 3
var destructible: bool = true

var hit_radius: float = 16.0

var collision_size: Vector2 = Vector2(
	26,
	22
)

var hit_flash: float = 0.0


func _ready() -> void:
	z_index = 5

	add_to_group("room_props")
	add_to_group("bullet_blockers")

	_configure_prop()

	if destructible:
		add_to_group("destructibles")

	var collision := CollisionShape2D.new()

	var shape := RectangleShape2D.new()

	shape.size = collision_size

	collision.shape = shape

	add_child(collision)

	queue_redraw()


func _configure_prop() -> void:
	match prop_type:
		"pillar":
			destructible = false

			health = 999

			collision_size = Vector2(
				28,
				40
			)

			hit_radius = 23.0

		"pot":
			destructible = true

			health = 1

			collision_size = Vector2(
				16,
				16
			)

			hit_radius = 11.0

		"table":
			destructible = false

			health = 999

			collision_size = Vector2(
				44,
				20
			)

			hit_radius = 25.0

		_:
			prop_type = "crate"

			destructible = true

			health = 3

			collision_size = Vector2(
				26,
				22
			)

			hit_radius = 16.0


func _process(delta: float) -> void:
	hit_flash = maxf(
		0.0,
		hit_flash - delta
	)

	if hit_flash > 0.0:
		queue_redraw()


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	var local_point: Vector2 = to_local(
		global_point
	)

	var rect := Rect2(
		-collision_size * 0.5,
		collision_size
	)

	rect = rect.grow(
		projectile_radius
	)

	return rect.has_point(
		local_point
	)


func take_damage(amount: int) -> void:
	if not destructible:
		return

	health -= amount

	hit_flash = 0.08

	if health <= 0:
		_break_prop()
	else:
		queue_redraw()


func _break_prop() -> void:
	var scene: Node = get_tree().current_scene

	if scene.has_method(
		"notify_prop_destroyed"
	):
		scene.call(
			"notify_prop_destroyed",
			prop_id
		)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"break"
		)

	queue_free()


func _draw() -> void:
	var flash_color := Color8(
		255,
		245,
		220
	)

	if prop_type == "pillar":
		draw_rect(
			Rect2(
				-14,
				-20,
				28,
				40
			),
			Color8(
				78,
				74,
				82
			),
			true
		)

		draw_rect(
			Rect2(
				-17,
				-20,
				34,
				7
			),
			Color8(
				105,
				99,
				105
			),
			true
		)

		draw_rect(
			Rect2(
				-17,
				13,
				34,
				7
			),
			Color8(
				55,
				53,
				60
			),
			true
		)

		draw_rect(
			Rect2(
				-9,
				-13,
				5,
				26
			),
			Color8(
				92,
				88,
				98
			),
			true
		)

		return

	if prop_type == "table":
		draw_rect(
			Rect2(
				-22,
				-9,
				44,
				18
			),
			Color8(
				103,
				66,
				45
			),
			true
		)

		draw_rect(
			Rect2(
				-20,
				-7,
				40,
				5
			),
			Color8(
				145,
				92,
				55
			),
			true
		)

		draw_rect(
			Rect2(
				-18,
				8,
				5,
				6
			),
			Color8(
				65,
				43,
				35
			),
			true
		)

		draw_rect(
			Rect2(
				13,
				8,
				5,
				6
			),
			Color8(
				65,
				43,
				35
			),
			true
		)

		return

	if prop_type == "pot":
		var pot_color := Color8(
			145,
			82,
			55
		)

		if hit_flash > 0.0:
			pot_color = flash_color

		draw_rect(
			Rect2(
				-6,
				-7,
				12,
				14
			),
			pot_color,
			true
		)

		draw_rect(
			Rect2(
				-8,
				-8,
				16,
				4
			),
			Color8(
				185,
				110,
				70
			),
			true
		)

		draw_rect(
			Rect2(
				-4,
				7,
				8,
				2
			),
			Color8(
				75,
				49,
				42
			),
			true
		)

		return

	var crate_color := Color8(
		129,
		83,
		49
	)

	if hit_flash > 0.0:
		crate_color = flash_color

	draw_rect(
		Rect2(
			-13,
			-11,
			26,
			22
		),
		crate_color,
		true
	)

	draw_rect(
		Rect2(
			-11,
			-9,
			22,
			18
		),
		Color8(
			158,
			103,
			58
		),
		false,
		2.0
	)

	draw_line(
		Vector2(-10, -8),
		Vector2(10, 8),
		Color8(
			91,
			57,
			42
		),
		3.0
	)

	draw_line(
		Vector2(10, -8),
		Vector2(-10, 8),
		Color8(
			91,
			57,
			42
		),
		3.0
	)