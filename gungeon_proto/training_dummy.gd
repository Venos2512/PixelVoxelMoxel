extends Node2D

var enemy_type: String = "training_dummy"

var health: int = 999999
var max_health: int = 999999

var hit_radius: float = 20.0

var total_damage: int = 0
var last_damage: int = 0
var hit_count: int = 0

var recent_damage: int = 0
var current_dps: float = 0.0
var dps_timer: float = 0.0

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
		-75.0,
		-74.0
	)

	title_label.size = Vector2(
		150.0,
		20.0
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
			0.32,
			1.0
		)
	)

	title_label.text = "TRAINING DUMMY"

	add_child(
		title_label
	)

	stats_label = Label.new()

	stats_label.position = Vector2(
		-100.0,
		-56.0
	)

	stats_label.size = Vector2(
		200.0,
		40.0
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
			0.88,
			0.88,
			0.90,
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

	dps_timer += delta

	if dps_timer >= 1.0:
		current_dps = (
			float(recent_damage)
			/ dps_timer
		)

		recent_damage = 0
		dps_timer = 0.0

		_update_stats_label()

	if knockback_velocity.length_squared() > 1.0:
		global_position += (
			knockback_velocity
			* delta
		)

		knockback_velocity = (
			knockback_velocity.move_toward(
				Vector2.ZERO,
				620.0 * delta
			)
		)

	else:
		knockback_velocity = Vector2.ZERO

		global_position = global_position.lerp(
			anchor_position,
			clampf(
				delta * 7.0,
				0.0,
				1.0
			)
		)

	if hit_flash_timer > 0.0:
		queue_redraw()


func take_damage(
	amount: int
) -> void:
	# F1 của Dev Tools dùng damage cực lớn.
	# Dummy cố tình bỏ qua để không bị xóa.
	if amount >= 999999:
		return

	if amount <= 0:
		return

	last_damage = amount
	total_damage += amount
	recent_damage += amount
	hit_count += 1

	hit_flash_timer = 0.10

	_spawn_damage_number(
		amount
	)

	_update_stats_label()

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
		force * 0.42,
		45.0,
		260.0
	)

	knockback_velocity += (
		direction
		* visual_force
	)


func reset_target() -> void:
	total_damage = 0
	last_damage = 0
	hit_count = 0

	recent_damage = 0
	current_dps = 0.0
	dps_timer = 0.0

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
	)


func _spawn_damage_number(
	amount: int
) -> void:
	var damage_label: Label = Label.new()

	damage_label.position = Vector2(
		randf_range(
			-18.0,
			6.0
		),
		-52.0
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
				-28.0
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

	# Shadow.
	draw_ellipse_shadow()

	# Main wooden pole.
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

	# Cross arms.
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

	# Body cloth.
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

	# Head.
	draw_circle(
		Vector2(
			0.0,
			-29.0
		),
		13.0,
		head_color
	)

	# Eyes.
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

	# Mouth stitch.
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

	# Base.
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


func draw_ellipse_shadow() -> void:
	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2(
			1.8,
			0.55
		)
	)

	draw_circle(
		Vector2(
			0.0,
			72.0
		),
		13.0,
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