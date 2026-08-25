extends Control

var icon_category: String = "relic"
var icon_id: String = ""
var rarity: String = "COMMON"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(
	category_value: String,
	id_value: String,
	rarity_value: String = "COMMON"
) -> void:
	icon_category = category_value
	icon_id = id_value
	rarity = rarity_value

	queue_redraw()


func _get_border_color() -> Color:
	if icon_category == "weapon":
		return Color(
			0.78,
			0.82,
			0.88,
			1.0
		)

	match rarity:
		"EPIC":
			return Color(
				0.78,
				0.35,
				0.95,
				1.0
			)

		"RARE":
			return Color(
				0.25,
				0.62,
				0.95,
				1.0
			)

		_:
			return Color(
				0.82,
				0.75,
				0.53,
				1.0
			)


func _draw() -> void:
	var rect: Rect2 = Rect2(
		Vector2.ZERO,
		size
	)

	var center: Vector2 = (
		size * 0.5
	)

	var border_color: Color = (
		_get_border_color()
	)

	draw_rect(
		rect,
		Color(
			0.055,
			0.05,
			0.065,
			0.92
		),
		true
	)

	draw_rect(
		rect.grow(
			-1.0
		),
		border_color,
		false,
		2.0
	)

	if icon_category == "weapon":
		_draw_weapon_icon(
			center,
			border_color
		)

	else:
		_draw_relic_icon(
			center,
			border_color
		)


func _draw_relic_icon(
	center: Vector2,
	color: Color
) -> void:
	var scale_value: float = minf(
		size.x,
		size.y
	) / 40.0

	match icon_id:
		"iron_seed":
			draw_circle(
				center,
				8.0 * scale_value,
				color
			)

			draw_line(
				center
					+ Vector2(
						0.0,
						-7.0
					) * scale_value,
				center
					+ Vector2(
						5.0,
						-13.0
					) * scale_value,
				color,
				2.0 * scale_value
			)

		"fleet_feather":
			draw_line(
				center
					+ Vector2(
						-8.0,
						10.0
					) * scale_value,
				center
					+ Vector2(
						8.0,
						-11.0
					) * scale_value,
				color,
				3.0 * scale_value
			)

			for index: int in range(4):
				var offset: float = (
					float(index) * 4.0
				)

				draw_line(
					center
						+ Vector2(
							-5.0 + offset,
							4.0 - offset
						) * scale_value,
					center
						+ Vector2(
							-11.0 + offset,
							-1.0 - offset
						) * scale_value,
					color,
					1.5 * scale_value
				)

		"broken_hourglass":
			var top_points: PackedVector2Array = PackedVector2Array(
				[
					center
						+ Vector2(
							-9.0,
							-11.0
						) * scale_value,

					center
						+ Vector2(
							9.0,
							-11.0
						) * scale_value,

					center
						+ Vector2(
							0.0,
							-1.0
						) * scale_value
				]
			)

			var bottom_points: PackedVector2Array = PackedVector2Array(
				[
					center
						+ Vector2(
							0.0,
							1.0
						) * scale_value,

					center
						+ Vector2(
							-9.0,
							11.0
						) * scale_value,

					center
						+ Vector2(
							9.0,
							11.0
						) * scale_value
				]
			)

			draw_colored_polygon(
				top_points,
				color
			)

			draw_colored_polygon(
				bottom_points,
				color
			)

		"brass_trigger":
			draw_arc(
				center,
				9.0 * scale_value,
				0.2,
				2.8,
				18,
				color,
				3.0 * scale_value
			)

			draw_line(
				center
					+ Vector2(
						4.0,
						-7.0
					) * scale_value,
				center
					+ Vector2(
						10.0,
						-10.0
					) * scale_value,
				color,
				3.0 * scale_value
			)

		"lead_eye":
			draw_arc(
				center,
				11.0 * scale_value,
				0.0,
				TAU,
				24,
				color,
				2.0 * scale_value
			)

			draw_circle(
				center,
				5.0 * scale_value,
				color
			)

			draw_circle(
				center,
				2.0 * scale_value,
				Color(
					0.06,
					0.05,
					0.07,
					1.0
				)
			)

		"long_fang":
			var fang_points: PackedVector2Array = PackedVector2Array(
				[
					center
						+ Vector2(
							-7.0,
							-10.0
						) * scale_value,

					center
						+ Vector2(
							8.0,
							-8.0
						) * scale_value,

					center
						+ Vector2(
							0.0,
							12.0
						) * scale_value
				]
			)

			draw_colored_polygon(
				fang_points,
				color
			)

		"titan_knuckle":
			draw_rect(
				Rect2(
					center
						+ Vector2(
							-10.0,
							-3.0
						) * scale_value,

					Vector2(
						20.0,
						13.0
					) * scale_value
				),
				color,
				true
			)

			for index: int in range(4):
				draw_circle(
					center
						+ Vector2(
							-7.5
								+ float(index)
								* 5.0,
							-7.0
						) * scale_value,
					3.5 * scale_value,
					color
				)

		"powder_idol":
			draw_circle(
				center
					+ Vector2(
						0.0,
						2.0
					) * scale_value,
				9.0 * scale_value,
				color
			)

			draw_line(
				center
					+ Vector2(
						4.0,
						-7.0
					) * scale_value,
				center
					+ Vector2(
						9.0,
						-13.0
					) * scale_value,
				color,
				2.0 * scale_value
			)

			draw_circle(
				center
					+ Vector2(
						10.0,
						-14.0
					) * scale_value,
				2.5 * scale_value,
				Color(
					1.0,
					0.45,
					0.12,
					1.0
				)
			)

		"deep_pockets":
			draw_rect(
				Rect2(
					center
						+ Vector2(
							-10.0,
							-6.0
						) * scale_value,

					Vector2(
						20.0,
						17.0
					) * scale_value
				),
				color,
				true
			)

			draw_arc(
				center
					+ Vector2(
						0.0,
						-7.0
					) * scale_value,
				7.0 * scale_value,
				PI,
				TAU,
				12,
				color,
				2.0 * scale_value
			)

		_:
			draw_circle(
				center,
				9.0 * scale_value,
				color
			)


func _draw_weapon_icon(
	center: Vector2,
	color: Color
) -> void:
	var scale_value: float = minf(
		size.x,
		size.y
	) / 64.0

	match icon_id:
		"sword":
			draw_line(
				center
					+ Vector2(
						-14.0,
						14.0
					) * scale_value,
				center
					+ Vector2(
						15.0,
						-15.0
					) * scale_value,
				color,
				5.0 * scale_value
			)

			draw_line(
				center
					+ Vector2(
						-13.0,
						7.0
					) * scale_value,
				center
					+ Vector2(
						-5.0,
						15.0
					) * scale_value,
				color,
				4.0 * scale_value
			)

		"spear":
			draw_line(
				center
					+ Vector2(
						-20.0,
						18.0
					) * scale_value,
				center
					+ Vector2(
						17.0,
						-19.0
					) * scale_value,
				color,
				4.0 * scale_value
			)

			var spear_tip: PackedVector2Array = PackedVector2Array(
				[
					center
						+ Vector2(
							17.0,
							-19.0
						) * scale_value,

					center
						+ Vector2(
							8.0,
							-17.0
						) * scale_value,

					center
						+ Vector2(
							15.0,
							-10.0
						) * scale_value
				]
			)

			draw_colored_polygon(
				spear_tip,
				color
			)

		"hammer":
			draw_line(
				center
					+ Vector2(
						-10.0,
						18.0
					) * scale_value,
				center
					+ Vector2(
						7.0,
						-7.0
					) * scale_value,
				color,
				6.0 * scale_value
			)

			draw_rect(
				Rect2(
					center
						+ Vector2(
							-5.0,
							-18.0
						) * scale_value,
					Vector2(
						25.0,
						13.0
					) * scale_value
				),
				color,
				true
			)

		"shotgun":
			draw_rect(
				Rect2(
					center
						+ Vector2(
							-22.0,
							-5.0
						) * scale_value,

					Vector2(
						38.0,
						7.0
					) * scale_value
				),
				color,
				true
			)

			draw_line(
				center
					+ Vector2(
						3.0,
						2.0
					) * scale_value,
				center
					+ Vector2(
						-9.0,
						15.0
					) * scale_value,
				color,
				6.0 * scale_value
			)

		"machine_gun":
			draw_rect(
				Rect2(
					center
						+ Vector2(
							-20.0,
							-7.0
						) * scale_value,

					Vector2(
						35.0,
						13.0
					) * scale_value
				),
				color,
				true
			)

			draw_rect(
				Rect2(
					center
						+ Vector2(
							-2.0,
							6.0
						) * scale_value,

					Vector2(
						9.0,
						15.0
					) * scale_value
				),
				color,
				true
			)

			draw_line(
				center
					+ Vector2(
						15.0,
						-2.0
					) * scale_value,
				center
					+ Vector2(
						25.0,
						-2.0
					) * scale_value,
				color,
				4.0 * scale_value
			)

		_:
			# Pistol
			draw_rect(
				Rect2(
					center
						+ Vector2(
							-17.0,
							-8.0
						) * scale_value,

					Vector2(
						32.0,
						11.0
					) * scale_value
				),
				color,
				true
			)

			draw_line(
				center
					+ Vector2(
						1.0,
						2.0
					) * scale_value,
				center
					+ Vector2(
						-3.0,
						17.0
					) * scale_value,
				color,
				7.0 * scale_value
			)