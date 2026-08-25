extends StaticBody2D

var wall_size: Vector2 = Vector2(
	100,
	24
)

var hit_radius: float = 50.0


func _ready() -> void:
	z_index = 4

	add_to_group("room_props")
	add_to_group("bullet_blockers")
	add_to_group("terrain_walls")

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	shape.size = wall_size
	collision.shape = shape

	add_child(collision)

	hit_radius = maxf(
		wall_size.x,
		wall_size.y
	) * 0.5

	queue_redraw()


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	var local_point: Vector2 = to_local(
		global_point
	)

	var rect := Rect2(
		-wall_size * 0.5,
		wall_size
	)

	rect = rect.grow(
		projectile_radius
	)

	return rect.has_point(
		local_point
	)


func _draw() -> void:
	draw_rect(
		Rect2(
			-wall_size * 0.5,
			wall_size
		),
		Color8(
			65,
			61,
			68
		),
		true
	)

	draw_rect(
		Rect2(
			-wall_size * 0.5,
			wall_size
		),
		Color8(
			105,
			96,
			98
		),
		false,
		3.0
	)

	var inner_rect := Rect2(
		-wall_size * 0.5
			+ Vector2(5, 5),
		wall_size
			- Vector2(10, 10)
	)

	draw_rect(
		inner_rect,
		Color8(
			78,
			72,
			77
		),
		false,
		2.0
	)

	# Stone seams.
	if wall_size.x > wall_size.y:
		var x: float = (
			-wall_size.x * 0.5
			+ 28.0
		)

		while x < wall_size.x * 0.5:
			draw_line(
				Vector2(
					x,
					-wall_size.y * 0.5 + 3
				),
				Vector2(
					x,
					wall_size.y * 0.5 - 3
				),
				Color8(
					52,
					49,
					55
				),
				2.0
			)

			x += 42.0

	else:
		var y: float = (
			-wall_size.y * 0.5
			+ 28.0
		)

		while y < wall_size.y * 0.5:
			draw_line(
				Vector2(
					-wall_size.x * 0.5 + 3,
					y
				),
				Vector2(
					wall_size.x * 0.5 - 3,
					y
				),
				Color8(
					52,
					49,
					55
				),
				2.0
			)

			y += 42.0