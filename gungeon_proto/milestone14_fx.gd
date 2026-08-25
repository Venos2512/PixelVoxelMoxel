extends Node2D

var effect_type: String = "parry"
var direction: Vector2 = Vector2.RIGHT
var effect_radius: float = 60.0

var life_time: float = 0.16
var life_timer: float = 0.0


func configure(
	type_value: String,
	direction_value: Vector2,
	radius_value: float
) -> void:
	effect_type = type_value
	direction = direction_value

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	effect_radius = radius_value

	if effect_type == "shockwave":
		life_time = 0.24

	elif effect_type == "wall_slam":
		life_time = 0.20

	else:
		life_time = 0.14

	queue_redraw()


func _process(
	delta: float
) -> void:
	life_timer += delta

	if life_timer >= life_time:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(
		life_timer / life_time,
		0.0,
		1.0
	)

	var alpha: float = 1.0 - progress

	match effect_type:
		"parry":
			_draw_parry(
				progress,
				alpha
			)

		"shockwave":
			_draw_shockwave(
				progress,
				alpha
			)

		"wall_slam":
			_draw_wall_slam(
				progress,
				alpha
			)


func _draw_parry(
	progress: float,
	alpha: float
) -> void:
	var angle: float = direction.angle()

	var start_angle: float = (
		angle
		- deg_to_rad(
			70.0
		)
	)

	var end_angle: float = (
		angle
		+ deg_to_rad(
			70.0
		)
	)

	var radius: float = lerpf(
		effect_radius * 0.58,
		effect_radius,
		progress
	)

	draw_arc(
		Vector2.ZERO,
		radius,
		start_angle,
		end_angle,
		24,
		Color(
			0.76,
			0.92,
			1.0,
			alpha
		),
		5.0
	)

	draw_arc(
		Vector2.ZERO,
		radius + 6.0,
		start_angle,
		end_angle,
		24,
		Color(
			1.0,
			1.0,
			1.0,
			alpha * 0.65
		),
		2.0
	)


func _draw_shockwave(
	progress: float,
	alpha: float
) -> void:
	var radius: float = lerpf(
		10.0,
		effect_radius,
		progress
	)

	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		36,
		Color(
			1.0,
			0.58,
			0.18,
			alpha * 0.75
		),
		6.0
	)

	draw_arc(
		Vector2.ZERO,
		radius + 7.0,
		0.0,
		TAU,
		36,
		Color(
			1.0,
			0.84,
			0.36,
			alpha * 0.40
		),
		2.0
	)


func _draw_wall_slam(
	progress: float,
	alpha: float
) -> void:
	var radius: float = lerpf(
		5.0,
		effect_radius,
		progress
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		Color(
			1.0,
			0.42,
			0.16,
			alpha * 0.24
		)
	)

	for index: int in range(6):
		var angle: float = (
			float(index)
			/ 6.0
			* TAU
		)

		var line_direction: Vector2 = Vector2.from_angle(
			angle
		)

		draw_line(
			line_direction * 5.0,
			line_direction * radius,
			Color(
				1.0,
				0.72,
				0.28,
				alpha
			),
			3.0
		)