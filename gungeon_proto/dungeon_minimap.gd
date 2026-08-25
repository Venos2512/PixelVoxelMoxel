extends Control

var rooms: Dictionary = {}
var current_room: Vector2i = Vector2i.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(170, 105)
	queue_redraw()


func set_dungeon_state(
	new_rooms: Dictionary,
	new_current_room: Vector2i
) -> void:
	rooms = new_rooms.duplicate(true)
	current_room = new_current_room
	queue_redraw()


func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color8(8, 9, 14, 205),
		true
	)

	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color8(110, 105, 115),
		false,
		2.0
	)

	var origin := Vector2(82, 51)
	var step := Vector2(20, 17)
	var room_size := Vector2(13, 9)

	# Connections first.
	for room_key in rooms.keys():
		var room_pos: Vector2i
		room_pos = room_key

		var data: Dictionary = rooms[room_pos]

		if not bool(data["visited"]):
			continue

		var center := (
			origin
			+ Vector2(
				room_pos.x * step.x,
				room_pos.y * step.y
			)
		)

		var right_pos := room_pos + Vector2i.RIGHT
		var down_pos := room_pos + Vector2i.DOWN

		if rooms.has(right_pos):
			var right_data: Dictionary = rooms[right_pos]

			if bool(right_data["visited"]):
				draw_line(
					center,
					center + Vector2(step.x, 0),
					Color8(110, 105, 115),
					3.0
				)

		if rooms.has(down_pos):
			var down_data: Dictionary = rooms[down_pos]

			if bool(down_data["visited"]):
				draw_line(
					center,
					center + Vector2(0, step.y),
					Color8(110, 105, 115),
					3.0
				)

	# Rooms.
	for room_key in rooms.keys():
		var room_pos: Vector2i
		room_pos = room_key

		var data: Dictionary = rooms[room_pos]

		if not bool(data["visited"]):
			continue

		var center := (
			origin
			+ Vector2(
				room_pos.x * step.x,
				room_pos.y * step.y
			)
		)

		var room_color := Color8(92, 92, 105)

		if bool(data["cleared"]):
			room_color = Color8(100, 155, 105)

		if str(data["type"]) == "treasure":
			room_color = Color8(205, 165, 60)

		if room_pos == current_room:
			room_color = Color8(95, 190, 230)

		draw_rect(
			Rect2(
				center - room_size * 0.5,
				room_size
			),
			Color8(18, 18, 24),
			true
		)

		draw_rect(
			Rect2(
				center - room_size * 0.5 + Vector2.ONE,
				room_size - Vector2(2, 2)
			),
			room_color,
			true
		)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(7, 14),
		"MAP",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color8(220, 220, 225)
	)