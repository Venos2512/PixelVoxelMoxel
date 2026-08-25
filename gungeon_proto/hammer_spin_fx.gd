extends Node2D

var target: Node2D = null

var active: bool = false
var charge_progress: float = 0.0

var spin_angle: float = 0.0


func _ready() -> void:
	z_index = 45
	visible = false


func set_target(
	target_value: Node2D
) -> void:
	target = target_value


func set_active(
	value: bool
) -> void:
	active = value
	visible = value

	if not value:
		charge_progress = 0.0

	queue_redraw()


func set_charge(
	value: float
) -> void:
	charge_progress = clampf(
		value,
		0.0,
		1.0
	)


func _process(
	delta: float
) -> void:
	if not active:
		return

	if not is_instance_valid(
		target
	):
		set_active(
			false
		)
		return

	global_position = target.global_position

	spin_angle += (
		delta
		* lerpf(
			7.0,
			15.0,
			charge_progress
		)
	)

	queue_redraw()


func _draw() -> void:
	if not active:
		return

	var orbit_radius: float = lerpf(
		27.0,
		35.0,
		charge_progress
	)

	var hammer_position: Vector2 = (
		Vector2.from_angle(
			spin_angle
		)
		* orbit_radius
	)

	draw_arc(
		Vector2.ZERO,
		orbit_radius,
		0.0,
		TAU,
		30,
		Color(
			1.0,
			0.62,
			0.20,
			0.22
				+ charge_progress
				* 0.25
		),
		3.0
	)

	draw_line(
		Vector2.ZERO,
		hammer_position,
		Color(
			0.48,
			0.30,
			0.15,
			1.0
		),
		5.0
	)

	draw_set_transform(
		hammer_position,
		spin_angle,
		Vector2.ONE
	)

	draw_rect(
		Rect2(
			-12.0,
			-7.0,
			24.0,
			14.0
		),
		Color(
			0.64,
			0.66,
			0.70,
			1.0
		),
		true
	)

	draw_rect(
		Rect2(
			-9.0,
			-4.0,
			18.0,
			8.0
		),
		Color(
			0.34,
			0.35,
			0.38,
			1.0
		),
		true
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)