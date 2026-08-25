extends Node2D

var fx_type: String = "reward"

var duration: float = 0.55
var age: float = 0.0


func _ready() -> void:
	add_to_group("room_fx")

	queue_redraw()


func _process(delta: float) -> void:
	age += delta

	if age >= duration:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(
		age / duration,
		0.0,
		1.0
	)

	var radius: float = lerpf(
		6.0,
		42.0,
		progress
	)

	var alpha: float = (
		1.0 - progress
	)

	var base_color := Color(
		1.0,
		0.78,
		0.25,
		alpha
	)

	if fx_type == "break":
		base_color = Color(
			0.75,
			0.45,
			0.25,
			alpha
		)

	elif fx_type == "clear":
		base_color = Color(
			0.35,
			0.85,
			0.95,
			alpha
		)

	elif fx_type == "portal":
		base_color = Color(
			0.55,
			0.45,
			1.0,
			alpha
		)

	elif fx_type == "explosion":
		base_color = Color(
			1.0,
			0.25,
			0.08,
			alpha
		)

		radius = lerpf(
			12.0,
			100.0,
			progress
		)

	elif fx_type == "impact":
		base_color = Color(
			1.0,
			0.88,
			0.45,
			alpha
		)

		radius = lerpf(
			3.0,
			18.0,
			progress
		)

	elif fx_type == "death":
		base_color = Color(
			1.0,
			0.30,
			0.25,
			alpha
		)

		radius = lerpf(
			8.0,
			55.0,
			progress
		)

	elif fx_type == "reinforcement":
		base_color = Color(
			0.75,
			0.28,
			1.0,
			alpha
		)

		radius = lerpf(
			25.0,
			115.0,
			progress
		)

	for i in range(10):
		var angle: float = (
			TAU
			* float(i)
			/ 10.0
		)

		var direction := Vector2(
			cos(angle),
			sin(angle)
		)

		var point: Vector2 = (
			direction
			* radius
		)

		var size_value: float = lerpf(
			5.0,
			2.0,
			progress
		)

		draw_rect(
			Rect2(
				point
				- Vector2.ONE
				* size_value
				* 0.5,
				Vector2.ONE
				* size_value
			),
			base_color,
			true
		)

	var center_alpha: float = (
		alpha * 0.65
	)

	draw_rect(
		Rect2(
			-4,
			-4,
			8,
			8
		),
		Color(
			base_color.r,
			base_color.g,
			base_color.b,
			center_alpha
		),
		false,
		2.0
	)