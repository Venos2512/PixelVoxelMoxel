extends Node2D

var target: Node2D = null
var progress_value: float = 0.0
var active: bool = false


func _ready() -> void:
	z_index = 130
	visible = false


func set_target(
	target_value: Node2D
) -> void:
	target = target_value


func show_progress(
	value: float
) -> void:
	progress_value = clampf(
		value,
		0.0,
		1.0
	)

	active = true
	visible = true

	queue_redraw()


func hide_progress() -> void:
	active = false
	visible = false


func _process(
	_delta: float
) -> void:
	if not active:
		return

	if not is_instance_valid(
		target
	):
		hide_progress()
		return

	global_position = (
		target.global_position
		+ Vector2(
			0.0,
			-56.0
		)
	)


func _draw() -> void:
	var width: float = 52.0
	var height: float = 6.0

	draw_rect(
		Rect2(
			-width * 0.5 - 2.0,
			-2.0,
			width + 4.0,
			height + 4.0
		),
		Color(
			0.03,
			0.03,
			0.035,
			0.88
		),
		true
	)

	draw_rect(
		Rect2(
			-width * 0.5,
			0.0,
			width,
			height
		),
		Color(
			0.18,
			0.18,
			0.20,
			1.0
		),
		true
	)

	draw_rect(
		Rect2(
			-width * 0.5,
			0.0,
			width * progress_value,
			height
		),
		Color(
			1.0,
			0.67,
			0.18,
			1.0
		),
		true
	)