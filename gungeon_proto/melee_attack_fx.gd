extends Node2D

var attack_style: String = "thrust"

var attack_range: float = 80.0
var attack_arc_deg: float = 30.0

var life_time: float = 0.14
var life_timer: float = 0.0


func configure(
	style_value: String,
	range_value: float,
	arc_value: float,
	direction: Vector2
) -> void:
	attack_style = style_value
	attack_range = range_value
	attack_arc_deg = arc_value

	rotation = direction.angle()

	if attack_style == "smash":
		life_time = 0.18

	else:
		life_time = 0.12

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

	var alpha: float = (
		1.0 - progress
	)

	if attack_style == "thrust":
		_draw_spear_fx(
			progress,
			alpha
		)

	elif attack_style == "smash":
		_draw_hammer_fx(
			progress,
			alpha
		)


func _draw_spear_fx(
	progress: float,
	alpha: float
) -> void:
	var start_x: float = lerpf(
		8.0,
		18.0,
		progress
	)

	var end_x: float = lerpf(
		attack_range * 0.62,
		attack_range,
		progress
	)

	draw_line(
		Vector2(
			start_x,
			0.0
		),
		Vector2(
			end_x,
			0.0
		),
		Color(
			0.90,
			0.92,
			1.0,
			alpha
		),
		4.0
	)

	draw_line(
		Vector2(
			start_x,
			-3.0
		),
		Vector2(
			end_x - 6.0,
			-3.0
		),
		Color(
			0.42,
			0.72,
			1.0,
			alpha * 0.70
		),
		2.0
	)

	var tip_size: float = 8.0

	var tip: PackedVector2Array = PackedVector2Array(
		[
			Vector2(
				end_x + tip_size,
				0.0
			),

			Vector2(
				end_x - 2.0,
				-tip_size * 0.55
			),

			Vector2(
				end_x - 2.0,
				tip_size * 0.55
			)
		]
	)

	draw_colored_polygon(
		tip,
		Color(
			0.95,
			0.96,
			1.0,
			alpha
		)
	)


func _draw_hammer_fx(
	progress: float,
	alpha: float
) -> void:
	var half_arc: float = deg_to_rad(
		attack_arc_deg * 0.5
	)

	var radius: float = lerpf(
		attack_range * 0.60,
		attack_range,
		progress
	)

	draw_arc(
		Vector2.ZERO,
		radius,
		-half_arc,
		half_arc,
		24,
		Color(
			1.0,
			0.72,
			0.25,
			alpha
		),
		6.0
	)

	draw_arc(
		Vector2.ZERO,
		radius + 6.0,
		-half_arc,
		half_arc,
		24,
		Color(
			1.0,
			0.36,
			0.12,
			alpha * 0.65
		),
		2.0
	)

	var impact_position: Vector2 = Vector2(
		radius,
		0.0
	)

	draw_circle(
		impact_position,
		lerpf(
			5.0,
			16.0,
			progress
		),
		Color(
			1.0,
			0.55,
			0.18,
			alpha * 0.45
		)
	)