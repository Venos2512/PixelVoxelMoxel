extends Node2D

const DPS_WINDOW: float = 2.0

var enemy_type: String = "training_dummy"

var health: int = 999999999
var max_health: int = 999999999

var hit_radius: float = 21.0

var total_damage: int = 0
var last_damage: int = 0
var hit_count: int = 0

var current_dps: float = 0.0
var peak_dps: float = 0.0

var damage_samples: Array[Dictionary] = []

var hit_flash_timer: float = 0.0

var anchor_position: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

var title_label: Label
var stats_label: Label


func _ready() -> void:
	z_index = 20

	add_to_group(
		"enemies"
	)

	add_to_group(
		"training_dummy"
	)

	anchor_position = global_position

	_create_labels()

	queue_redraw()


func _create_labels() -> void:
	title_label = Label.new()

	title_label.position = Vector2(
		-90.0,
		-82.0
	)

	title_label.size = Vector2(
		180.0,
		22.0
	)

	title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title_label.add_theme_font_size_override(
		"font_size",
		12
	)

	title_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.82,
			0.30,
			1.0
		)
	)

	title_label.text = "TRAINING DUMMY"

	add_child(
		title_label
	)

	stats_label = Label.new()

	stats_label.position = Vector2(
		-145.0,
		-61.0
	)

	stats_label.size = Vector2(
		290.0,
		48.0
	)

	stats_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	stats_label.add_theme_font_size_override(
		"font_size",
		10
	)

	stats_label.add_theme_color_override(
		"font_color",
		Color(
			0.92,
			0.92,
			0.94,
			1.0
		)
	)

	add_child(
		stats_label
	)

	_update_stats_label()


func _process(
	delta: float
) -> void:
	hit_flash_timer = maxf(
		0.0,
		hit_flash_timer - delta
	)

	_update_dps()

	if knockback_velocity.length_squared() > 1.0:
		global_position += (
			knockback_velocity
			* delta
		)

		knockback_velocity = (
			knockback_velocity.move_toward(
				Vector2.ZERO,
				650.0 * delta
			)
		)

	else:
		# Dummy giữ nguyên vị trí sau khi bị hất văng.
		# Chỉ RESET DUMMY mới đưa nó về anchor.
		knockback_velocity = Vector2.ZERO

	if hit_flash_timer > 0.0:
		queue_redraw()


func _get_time_seconds() -> float:
	return (
		float(
			Time.get_ticks_msec()
		)
		/ 1000.0
	)


func _update_dps() -> void:
	var now: float = _get_time_seconds()

	while not damage_samples.is_empty():
		var first_sample: Dictionary = (
			damage_samples[0]
		)

		var sample_time: float = float(
			first_sample.get(
				"time",
				0.0
			)
		)

		if (
			now - sample_time
			<= DPS_WINDOW
		):
			break

		damage_samples.pop_front()

	var damage_sum: int = 0

	for sample: Dictionary in damage_samples:
		damage_sum += int(
			sample.get(
				"damage",
				0
			)
		)

	if damage_samples.is_empty():
		current_dps = 0.0

	else:
		var oldest_time: float = float(
			damage_samples[0].get(
				"time",
				now
			)
		)

		var measured_time: float = clampf(
			now - oldest_time,
			0.25,
			DPS_WINDOW
		)

		current_dps = (
			float(damage_sum)
			/ measured_time
		)

	peak_dps = maxf(
		peak_dps,
		current_dps
	)

	_update_stats_label()


func take_damage(
	amount: int
) -> void:
	# Dev F1 không giết dummy.
	if amount >= 999999:
		return

	if amount <= 0:
		return

	last_damage = amount
	total_damage += amount
	hit_count += 1

	damage_samples.append(
		{
			"time": _get_time_seconds(),
			"damage": amount
		}
	)

	hit_flash_timer = 0.10

	_spawn_damage_number(
		amount
	)

	_update_dps()

	queue_redraw()


func apply_hit_knockback(
	source_position: Vector2,
	force: float
) -> void:
	var direction: Vector2 = (
		global_position
		- source_position
	)

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	var visual_force: float = clampf(
		force * 0.55,
		40.0,
		700.0
	)

	knockback_velocity += (
		direction
		* visual_force
	)


func reset_target() -> void:
	total_damage = 0
	last_damage = 0
	hit_count = 0

	current_dps = 0.0
	peak_dps = 0.0

	damage_samples.clear()

	hit_flash_timer = 0.0

	knockback_velocity = Vector2.ZERO

	global_position = anchor_position

	_update_stats_label()

	queue_redraw()


func set_training_position(
	position_value: Vector2
) -> void:
	global_position = position_value
	anchor_position = position_value


func _update_stats_label() -> void:
	if not is_instance_valid(
		stats_label
	):
		return

	stats_label.text = (
		"LAST "
		+ str(last_damage)
		+ "   TOTAL "
		+ str(total_damage)
		+ "   HITS "
		+ str(hit_count)
		+ "\nDPS "
		+ str(
			snappedf(
				current_dps,
				0.1
			)
		)
		+ "   PEAK "
		+ str(
			snappedf(
				peak_dps,
				0.1
			)
		)
	)


func _spawn_damage_number(
	amount: int
) -> void:
	var damage_label: Label = Label.new()

	damage_label.position = Vector2(
		randf_range(
			-18.0,
			8.0
		),
		-54.0
	)

	damage_label.size = Vector2(
		60.0,
		24.0
	)

	damage_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	damage_label.text = str(
		amount
	)

	damage_label.add_theme_font_size_override(
		"font_size",
		14
	)

	damage_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.80,
			0.25,
			1.0
		)
	)

	damage_label.z_index = 100

	add_child(
		damage_label
	)

	var tween: Tween = create_tween()

	tween.set_parallel(
		true
	)

	tween.tween_property(
		damage_label,
		"position",
		damage_label.position
			+ Vector2(
				0.0,
				-30.0
			),
		0.42
	)

	tween.tween_property(
		damage_label,
		"modulate:a",
		0.0,
		0.42
	)

	tween.set_parallel(
		false
	)

	tween.tween_callback(
		damage_label.queue_free
	)


func _draw_dummy_shadow() -> void:
	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2(
			1.75,
			0.50
		)
	)

	draw_circle(
		Vector2(
			0.0,
			78.0
		),
		14.0,
		Color(
			0.02,
			0.02,
			0.025,
			0.42
		)
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)


func _draw() -> void:
	var wood_color: Color = Color8(
		132,
		87,
		48
	)

	var cloth_color: Color = Color8(
		129,
		82,
		54
	)

	var head_color: Color = Color8(
		195,
		159,
		92
	)

	if hit_flash_timer > 0.0:
		wood_color = Color(
			1.0,
			0.92,
			0.65,
			1.0
		)

		cloth_color = Color(
			1.0,
			0.82,
			0.42,
			1.0
		)

		head_color = Color(
			1.0,
			0.95,
			0.70,
			1.0
		)

	_draw_dummy_shadow()

	draw_rect(
		Rect2(
			-3.0,
			-7.0,
			6.0,
			50.0
		),
		wood_color,
		true
	)

	draw_line(
		Vector2(
			-32.0,
			-10.0
		),
		Vector2(
			32.0,
			-10.0
		),
		wood_color,
		7.0
	)

	var body_points: PackedVector2Array = (
		PackedVector2Array(
			[
				Vector2(
					-18.0,
					-14.0
				),
				Vector2(
					18.0,
					-14.0
				),
				Vector2(
					13.0,
					20.0
				),
				Vector2(
					-13.0,
					20.0
				)
			]
		)
	)

	draw_colored_polygon(
		body_points,
		cloth_color
	)

	draw_circle(
		Vector2(
			0.0,
			-29.0
		),
		13.0,
		head_color
	)

	draw_circle(
		Vector2(
			-4.5,
			-30.0
		),
		1.5,
		Color8(
			45,
			35,
			28
		)
	)

	draw_circle(
		Vector2(
			4.5,
			-30.0
		),
		1.5,
		Color8(
			45,
			35,
			28
		)
	)

	draw_line(
		Vector2(
			-5.0,
			-23.0
		),
		Vector2(
			5.0,
			-23.0
		),
		Color8(
			70,
			47,
			35
		),
		1.5
	)

	draw_line(
		Vector2(
			-16.0,
			43.0
		),
		Vector2(
			16.0,
			43.0
		),
		wood_color,
		6.0
	)