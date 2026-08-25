extends Node2D

var arena_rect: Rect2 = Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)


func configure(
	rect_value: Rect2
) -> void:
	arena_rect = rect_value

	queue_redraw()


func _ready() -> void:
	# Training floor phải nằm dưới projectile / actor.
	# z = 1 trước đây làm player bullets bị nền che,
	# dù collision và damage vẫn hoạt động.
	z_index = 0

	add_to_group(
		"bullet_blockers"
	)

	queue_redraw()


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	var local_point: Vector2 = to_local(
		global_point
	)

	var safe_rect: Rect2 = arena_rect.grow(
		-projectile_radius
	)

	if (
		safe_rect.size.x <= 0.0
		or safe_rect.size.y <= 0.0
	):
		return true

	return not safe_rect.has_point(
		local_point
	)


func _draw() -> void:
	# Nền training room.
	draw_rect(
		arena_rect,
		Color(
			0.075,
			0.075,
			0.085,
			1.0
		),
		true
	)

	# Grid nhẹ để dễ nhìn range / khoảng cách.
	var grid_size: float = 48.0

	var start_x: float = (
		floor(
			arena_rect.position.x
			/ grid_size
		)
		* grid_size
	)

	var end_x: float = arena_rect.end.x

	var x_value: float = start_x

	while x_value <= end_x:
		draw_line(
			Vector2(
				x_value,
				arena_rect.position.y
			),
			Vector2(
				x_value,
				arena_rect.end.y
			),
			Color(
				0.13,
				0.13,
				0.145,
				0.55
			),
			1.0
		)

		x_value += grid_size

	var start_y: float = (
		floor(
			arena_rect.position.y
			/ grid_size
		)
		* grid_size
	)

	var end_y: float = arena_rect.end.y

	var y_value: float = start_y

	while y_value <= end_y:
		draw_line(
			Vector2(
				arena_rect.position.x,
				y_value
			),
			Vector2(
				arena_rect.end.x,
				y_value
			),
			Color(
				0.13,
				0.13,
				0.145,
				0.55
			),
			1.0
		)

		y_value += grid_size

	# Border ngoài.
	draw_rect(
		arena_rect,
		Color(
			0.46,
			0.42,
			0.32,
			1.0
		),
		false,
		7.0
	)

	# Border trong.
	draw_rect(
		arena_rect.grow(
			-9.0
		),
		Color(
			0.19,
			0.18,
			0.17,
			1.0
		),
		false,
		3.0
	)