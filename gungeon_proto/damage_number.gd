extends Node2D

var amount: int = 1

var is_player_damage: bool = false

var duration: float = 0.62
var age: float = 0.0

var drift := Vector2(
	0,
	-28
)


func _ready() -> void:
	add_to_group("room_fx")

	z_index = 100

	position += Vector2(
		randf_range(-5.0, 5.0),
		randf_range(-3.0, 2.0)
	)

	queue_redraw()


func _process(delta: float) -> void:
	age += delta

	position += drift * delta

	drift.y += 18.0 * delta

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

	var alpha: float = (
		1.0 - progress
	)

	var text_color := Color(
		1.0,
		0.86,
		0.30,
		alpha
	)

	if is_player_damage:
		text_color = Color(
			1.0,
			0.28,
			0.28,
			alpha
		)

	var text := str(amount)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-10, 0),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		20,
		13,
		Color(
			0.05,
			0.04,
			0.04,
			alpha
		)
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-10, -1),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		20,
		12,
		text_color
	)