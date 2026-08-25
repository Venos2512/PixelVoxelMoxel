extends CharacterBody2D

const MeleeAttackSystemScript = preload(
	"res://gungeon_proto/melee_attack_system.gd"
)

const Milestone14CombatScript = preload(
	"res://gungeon_proto/milestone14_combat.gd"
)

const BulletScript = preload("res://gungeon_proto/bullet.gd")
const WeaponSystemScript = preload(
	"res://gungeon_proto/weapon_system.gd"
)

const UpgradeSystemScript = preload(
	"res://gungeon_proto/upgrade_system.gd"
)

const CurrencySystemScript = preload(
	"res://gungeon_proto/currency_system.gd"
)

var move_speed := 155.0
var fire_interval := 0.11

var roll_speed := 360.0
var roll_duration := 0.20
var roll_cooldown := 0.42

var max_health := 5
var health := 5

var room_rect := Rect2(-350, -190, 700, 380)

var aim_direction := Vector2.RIGHT
var fire_timer := 0.0

var is_rolling := false
var roll_direction := Vector2.RIGHT
var roll_time_left := 0.0
var roll_cooldown_timer := 0.0

var invulnerable_timer := 0.0
var hit_flash := 0.0

var roll_key_was_down := false
var reload_key_was_down := false
var fire_button_was_down := false
var god_mode_key_was_down := false

var god_mode: bool = true

var dead := false

var muzzle_flash_timer := 0.0

var sword_swing_timer: float = 0.0
var sword_swing_duration: float = 0.14

var camera_shake_strength: float = 0.0

var weapon_system: Node
var upgrade_system: Node
var currency_system: Node

var weapon_label: Label

var weapon_list_label: Label
var weapon_list_panel: ColorRect


func _ready() -> void:
	z_index = 20

	add_to_group("player")

	weapon_system = WeaponSystemScript.new()
	add_child(weapon_system)

	upgrade_system = UpgradeSystemScript.new()
	add_child(upgrade_system)

	currency_system = CurrencySystemScript.new()
	add_child(currency_system)

	weapon_label = Label.new()
	weapon_label.position = Vector2(-48, 21)
	weapon_label.size = Vector2(96, 24)

	weapon_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	weapon_label.add_theme_font_size_override(
		"font_size",
		9
	)

	add_child(weapon_label)

	_create_weapon_list_ui()
	_update_weapon_label()

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	shape.size = Vector2(12, 14)
	collision.shape = shape

	add_child(collision)

	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(weapon_system):
		return

	if (
		event is InputEventMouseButton
		and event.pressed
	):
		var mouse_event := event as InputEventMouseButton

		if (
			mouse_event.button_index
			== MOUSE_BUTTON_WHEEL_UP
		):
			weapon_system.cycle_weapon(-1)
			_update_weapon_label()

		elif (
			mouse_event.button_index
			== MOUSE_BUTTON_WHEEL_DOWN
		):
			weapon_system.cycle_weapon(1)
			_update_weapon_label()

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		var key_event := event as InputEventKey

		var slot_index: int = _get_slot_from_key(
			key_event.keycode
		)

		if slot_index >= 0:
			weapon_system.equip_by_index(
				slot_index
			)

			_update_weapon_label()


func _get_slot_from_key(
	keycode: Key
) -> int:
	match keycode:
		KEY_1:
			return 0

		KEY_2:
			return 1

		KEY_3:
			return 2

		KEY_4:
			return 3

		KEY_5:
			return 4

		KEY_6:
			return 5

		KEY_7:
			return 6

		KEY_8:
			return 7

		KEY_9:
			return 8

	return -1


func add_camera_shake(
	amount: float
) -> void:
	camera_shake_strength = maxf(
		camera_shake_strength,
		amount
	)


func _update_camera_shake(
	delta: float
) -> void:
	camera_shake_strength = maxf(
		0.0,
		camera_shake_strength
		- 22.0 * delta
	)

	var camera := get_node_or_null(
		"Camera2D"
	) as Camera2D

	if not is_instance_valid(camera):
		return

	if camera_shake_strength <= 0.05:
		camera.offset = Vector2.ZERO
		return

	camera.offset = Vector2(
		randf_range(
			-camera_shake_strength,
			camera_shake_strength
		),
		randf_range(
			-camera_shake_strength,
			camera_shake_strength
		)
	)


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	var god_mode_key_down: bool = Input.is_key_pressed(
		KEY_G
	)

	var god_mode_pressed: bool = (
		god_mode_key_down
		and not god_mode_key_was_down
	)

	god_mode_key_was_down = god_mode_key_down

	if god_mode_pressed:
		god_mode = not god_mode

		print(
			"GOD MODE: ",
			"ON" if god_mode else "OFF"
		)

	fire_timer = maxf(0.0, fire_timer - delta)
	roll_cooldown_timer = maxf(0.0, roll_cooldown_timer - delta)
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	muzzle_flash_timer = maxf(
		0.0,
		muzzle_flash_timer - delta
	)

	sword_swing_timer = maxf(
		0.0,
		sword_swing_timer - delta
	)

	_update_camera_shake(
		delta
	)

	var reload_key_down: bool = Input.is_key_pressed(
		KEY_R
	)

	var reload_pressed: bool = (
		reload_key_down
		and not reload_key_was_down
	)

	reload_key_was_down = reload_key_down

	if reload_pressed:
		weapon_system.start_reload()

	_update_weapon_label()

	var mouse_position := get_global_mouse_position()
	var new_aim := mouse_position - global_position

	if new_aim.length_squared() > 1.0:
		aim_direction = new_aim.normalized()

	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0

	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0

	if input_vector.length_squared() > 0.0:
		input_vector = input_vector.normalized()

	var roll_key_down := Input.is_key_pressed(KEY_SPACE)
	var roll_pressed := roll_key_down and not roll_key_was_down

	roll_key_was_down = roll_key_down

	if (
		roll_pressed
		and not is_rolling
		and roll_cooldown_timer <= 0.0
	):
		if input_vector.length_squared() > 0.0:
			roll_direction = input_vector
		else:
			roll_direction = aim_direction

		is_rolling = true
		roll_time_left = roll_duration
		roll_cooldown_timer = roll_cooldown

	if is_rolling:
		roll_time_left -= delta

		velocity = roll_direction * roll_speed

		move_and_slide()

		_clamp_to_room()

		if roll_time_left <= 0.0:
			is_rolling = false

		queue_redraw()
		return

	velocity = input_vector * move_speed

	move_and_slide()

	_clamp_to_room()

	var fire_button_down: bool = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_LEFT
		)
	)

	var carried_value: Variant = get_meta(
		"carried_object",
		null
	)

	var carrying_object: bool = (
		carried_value != null
		and is_instance_valid(
			carried_value
		)
	)

	var suppress_fire: bool = bool(
		get_meta(
			"suppress_fire_until_release",
			false
		)
	)

	# Sau khi LMB được dùng để ném object,
	# không cho súng bắn cho tới khi người chơi
	# nhả nút chuột hoàn toàn.
	if (
		suppress_fire
		and not fire_button_down
	):
		remove_meta(
			"suppress_fire_until_release"
		)

		suppress_fire = false

	var weapon: Dictionary = (
		weapon_system.get_current_weapon()
	)

	var wants_fire: bool = false

	if (
		not carrying_object
		and not suppress_fire
	):
		if bool(weapon["automatic"]):
			wants_fire = fire_button_down
		else:
			wants_fire = (
				fire_button_down
				and not fire_button_was_down
			)

	if wants_fire and fire_timer <= 0.0:
		_shoot()

	fire_button_was_down = fire_button_down

	_update_weapon_label()

	queue_redraw()


func _clamp_to_room() -> void:
	position.x = clampf(
		position.x,
		room_rect.position.x,
		room_rect.end.x
	)

	position.y = clampf(
		position.y,
		room_rect.position.y,
		room_rect.end.y
	)


func add_gold(amount: int) -> void:
	if not is_instance_valid(currency_system):
		return

	currency_system.call(
		"add_gold",
		amount
	)


func get_gold() -> int:
	if not is_instance_valid(currency_system):
		return 0

	return int(
		currency_system.get("gold")
	)


func spend_gold(amount: int) -> bool:
	if not is_instance_valid(currency_system):
		return false

	return bool(
		currency_system.call(
			"spend_gold",
			amount
		)
	)


func take_damage(amount: int) -> void:
	if dead:
		return

	if god_mode:
		return

	if is_rolling:
		return

	if invulnerable_timer > 0.0:
		return

	health -= amount

	invulnerable_timer = 0.75
	hit_flash = 0.12

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_damage_number"
	):
		scene.call(
			"spawn_damage_number",
			global_position + Vector2(0, -24),
			amount,
			true
		)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"impact"
		)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			6.0
		)

	if scene.has_method(
		"request_hit_stop"
	):
		scene.call(
			"request_hit_stop",
			0.045,
			0.12
		)

	if health <= 0:
		_die()

	queue_redraw()


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"death"
		)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			10.0
		)

	await get_tree().create_timer(0.8).timeout

	get_tree().reload_current_scene()


func _shoot() -> void:
	if (
		not god_mode
		and not weapon_system.can_fire()
	):
		if weapon_system.get_ammo_in_mag() <= 0:
			weapon_system.start_reload()

		return

	var weapon: Dictionary = (
		weapon_system.get_current_weapon()
	)

	if str(weapon.get("type", "ranged")) == "melee":
		var melee_style: String = str(
			weapon.get(
				"melee_style",
				""
			)
		).to_lower()

		var melee_name: String = str(
			weapon.get(
				"name",
				""
			)
		).to_lower()

		Milestone14CombatScript.record_attack_tags(
			self,
			weapon
		)

		# LMB chỉ còn là đòn đánh cơ bản.
		# Special của từng weapon được chuyển hoàn toàn sang RMB.
		if (
			melee_style == "slash"
			or (
				melee_style.is_empty()
				and "sword" in melee_name
			)
		):
			_swing_sword(
				weapon
			)

		else:
			MeleeAttackSystemScript.perform_attack(
				self,
				weapon,
				aim_direction
			)

		fire_timer = float(
			weapon["fire_interval"]
		)

		_update_weapon_label()
		return

	var pellet_count: int = int(
		weapon["pellets"]
	)

	var spread_deg: float = float(
		weapon["spread_deg"]
	)

	for _pellet in range(pellet_count):
		var spread_offset_deg: float = randf_range(
			-spread_deg * 0.5,
			spread_deg * 0.5
		)

		var shot_direction: Vector2 = (
			aim_direction.rotated(
				deg_to_rad(
					spread_offset_deg
				)
			)
		)

		var bullet = BulletScript.new()

		bullet.direction = shot_direction

		bullet.speed = float(
			weapon["bullet_speed"]
		)

		bullet.damage = int(
			weapon["damage"]
		)

		get_tree().current_scene.add_child(
			bullet
		)

		bullet.global_position = (
			global_position
			+ shot_direction * 17.0
		)

	if not god_mode:
		weapon_system.consume_round()

	fire_timer = float(
		weapon["fire_interval"]
	)

	var recoil: float = float(
		weapon["recoil"]
	)

	position -= aim_direction * recoil

	_clamp_to_room()

	muzzle_flash_timer = 0.055

	_update_weapon_label()


func _swing_sword(
	weapon: Dictionary
) -> void:
	var attack_range: float = float(
		weapon["range"]
	)

	var arc_deg: float = float(
		weapon["arc_deg"]
	)

	var damage: int = int(
		weapon["damage"]
	)

	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(enemy_value):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = enemy_value as Node2D

		if not is_instance_valid(enemy):
			continue

		var to_enemy: Vector2 = (
			enemy.global_position
			- global_position
		)

		var distance: float = to_enemy.length()

		if distance > attack_range:
			continue

		if distance <= 0.001:
			continue

		var angle_difference: float = absf(
			aim_direction.angle_to(
				to_enemy.normalized()
			)
		)

		if angle_difference > deg_to_rad(
			arc_deg * 0.5
		):
			continue

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				global_position,
				165.0
			)

		if enemy.has_method("take_damage"):
			enemy.call(
				"take_damage",
				damage
			)

		var scene: Node = (
			get_tree().current_scene
		)

		if scene.has_method(
			"request_hit_stop"
		):
			scene.call(
				"request_hit_stop",
				0.04,
				0.12
			)

		if scene.has_method(
			"request_camera_shake"
		):
			scene.call(
				"request_camera_shake",
				3.0
			)

	for prop_value in get_tree().get_nodes_in_group(
		"destructibles"
	):
		if not is_instance_valid(prop_value):
			continue

		if prop_value.is_queued_for_deletion():
			continue

		var prop: Node2D = prop_value as Node2D

		if not is_instance_valid(prop):
			continue

		var to_prop: Vector2 = (
			prop.global_position
			- global_position
		)

		var prop_distance: float = (
			to_prop.length()
		)

		if prop_distance > attack_range:
			continue

		if prop_distance <= 0.001:
			continue

		var prop_angle: float = absf(
			aim_direction.angle_to(
				to_prop.normalized()
			)
		)

		if prop_angle > deg_to_rad(
			arc_deg * 0.5
		):
			continue

		if prop.has_method("take_damage"):
			prop.call(
				"take_damage",
				damage
			)

	sword_swing_timer = sword_swing_duration

	# Tiny forward lunge for melee feel.
	position += aim_direction * 3.0

	_clamp_to_room()


func equip_weapon_pickup(
	weapon_id: String
) -> void:
	weapon_system.unlock_and_equip(
		weapon_id
	)

	_update_weapon_label()

	print(
		"Picked up: ",
		weapon_system.get_weapon_name()
	)


func _create_weapon_list_ui() -> void:
	var canvas := CanvasLayer.new()

	canvas.name = "WeaponInventoryUI"
	canvas.layer = 20

	add_child(canvas)

	var root := Control.new()

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	canvas.add_child(root)

	weapon_list_panel = ColorRect.new()

	weapon_list_panel.anchor_left = 1.0
	weapon_list_panel.anchor_right = 1.0
	weapon_list_panel.anchor_top = 0.0
	weapon_list_panel.anchor_bottom = 0.0

	weapon_list_panel.offset_left = -215.0
	weapon_list_panel.offset_right = -12.0
	weapon_list_panel.offset_top = 12.0
	weapon_list_panel.offset_bottom = 158.0

	weapon_list_panel.color = Color(
		0.03,
		0.035,
		0.05,
		0.82
	)

	weapon_list_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	root.add_child(
		weapon_list_panel
	)

	weapon_list_label = Label.new()

	weapon_list_label.position = Vector2(
		10,
		8
	)

	weapon_list_label.size = Vector2(
		185,
		130
	)

	weapon_list_label.add_theme_font_size_override(
		"font_size",
		11
	)

	weapon_list_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	weapon_list_panel.add_child(
		weapon_list_label
	)


func _update_weapon_label() -> void:
	if not is_instance_valid(weapon_label):
		return

	if not is_instance_valid(weapon_system):
		return

	var weapon_name: String = (
		weapon_system.get_weapon_name()
	)

	var weapon: Dictionary = (
		weapon_system.get_current_weapon()
	)

	if str(weapon.get("type", "ranged")) == "melee":
		weapon_label.text = (
			weapon_name
			+ "  MELEE"
		)

	elif weapon_system.reloading:
		weapon_label.text = (
			weapon_name
			+ "  RELOAD..."
		)

	else:
		weapon_label.text = (
			weapon_name
			+ "  "
			+ str(
				weapon_system.get_ammo_in_mag()
			)
			+ "/"
			+ str(
				weapon_system.get_reserve_ammo()
			)
		)

	_update_weapon_list()


func _update_weapon_list() -> void:
	if not is_instance_valid(weapon_list_label):
		return

	if not is_instance_valid(weapon_system):
		return

	var order: Array[String] = (
		weapon_system.get_weapon_order()
	)

	var current_weapon_id: String = str(
		weapon_system.current_weapon
	)

	var list_text := "WEAPONS\n"

	for i in range(order.size()):
		var weapon_id: String = order[i]

		if not weapon_system.weapons.has(
			weapon_id
		):
			continue

		var weapon: Dictionary = (
			weapon_system.weapons[
				weapon_id
			]
		)

		var marker := "  "

		if weapon_id == current_weapon_id:
			marker = "> "

		var slot_text := (
			"["
			+ str(i + 1)
			+ "] "
		)

		var weapon_name: String = str(
			weapon["name"]
		)

		var status_text := ""

		if str(
			weapon.get(
				"type",
				"ranged"
			)
		) == "melee":
			status_text = "MELEE"

		else:
			status_text = (
				str(
					weapon_system.ammo[
						weapon_id
					]
				)
				+ "/"
				+ str(
					weapon_system.reserve_ammo[
						weapon_id
					]
				)
			)

		list_text += (
			marker
			+ slot_text
			+ weapon_name
			+ "  "
			+ status_text
			+ "\n"
		)

	weapon_list_label.text = list_text


func _draw() -> void:
	# Pixel shadow.
	draw_rect(
		Rect2(-8, 7, 16, 5),
		Color8(10, 10, 14, 150),
		true
	)

	var body_color := Color8(61, 157, 210)

	if hit_flash > 0.0:
		body_color = Color8(255, 245, 220)

	elif is_rolling:
		body_color = Color8(90, 210, 235)

	# Body.
	draw_rect(
		Rect2(-7, -7, 14, 15),
		body_color,
		true
	)

	# Head highlight.
	draw_rect(
		Rect2(-5, -6, 10, 5),
		Color8(110, 206, 238),
		true
	)

	# Face.
	draw_rect(
		Rect2(-4, -1, 2, 2),
		Color8(15, 22, 28),
		true
	)

	draw_rect(
		Rect2(2, -1, 2, 2),
		Color8(15, 22, 28),
		true
	)

	var current_weapon: Dictionary = {}

	if is_instance_valid(weapon_system):
		current_weapon = (
			weapon_system.get_current_weapon()
		)

	var weapon_type: String = str(
		current_weapon.get(
			"type",
			"ranged"
		)
	)

	if weapon_type == "melee":
		var sword_direction: Vector2 = (
			aim_direction
		)

		if sword_swing_timer > 0.0:
			var swing_progress: float = (
				1.0
				- sword_swing_timer
				/ sword_swing_duration
			)

			var swing_angle: float = lerpf(
				-0.95,
				0.95,
				swing_progress
			)

			sword_direction = (
				aim_direction.rotated(
					swing_angle
				)
			)

			# Sword motion trail.
			var base_angle: float = (
				aim_direction.angle()
			)

			var current_angle: float = (
				base_angle
				+ swing_angle
			)

			var trail_start: float = (
				current_angle - 0.55
			)

			draw_arc(
				Vector2.ZERO,
				30.0,
				trail_start,
				current_angle,
				14,
				Color(
					0.75,
					0.90,
					1.0,
					0.48
				),
				5.0
			)

			draw_arc(
				Vector2.ZERO,
				25.0,
				trail_start - 0.10,
				current_angle,
				12,
				Color(
					1.0,
					0.88,
					0.45,
					0.28
				),
				2.0
			)

		var sword_handle_start := (
			sword_direction * 5.0
		)

		var sword_blade_start := (
			sword_direction * 10.0
		)

		var sword_tip := (
			sword_direction * 34.0
		)

		# Handle.
		draw_line(
			sword_handle_start,
			sword_blade_start,
			Color8(118, 77, 45),
			5.0
		)

		# Guard.
		var guard_direction := Vector2(
			-sword_direction.y,
			sword_direction.x
		)

		draw_line(
			sword_blade_start
				- guard_direction * 5.0,
			sword_blade_start
				+ guard_direction * 5.0,
			Color8(225, 180, 65),
			3.0
		)

		# Blade outline.
		draw_line(
			sword_blade_start,
			sword_tip,
			Color8(80, 88, 100),
			6.0
		)

		# Blade.
		draw_line(
			sword_blade_start,
			sword_tip,
			Color8(220, 230, 238),
			3.0
		)

	else:
		# Gun.
		var gun_start := aim_direction * 7.0
		var gun_end := aim_direction * 17.0

		draw_line(
			gun_start,
			gun_end,
			Color8(235, 222, 178),
			4.0
		)

		if muzzle_flash_timer > 0.0:
			var muzzle_position: Vector2 = (
				aim_direction * 20.0
			)

			draw_circle(
				muzzle_position,
				5.0,
				Color8(255, 215, 95)
			)

			draw_circle(
				muzzle_position,
				2.0,
				Color8(255, 250, 220)
			)

	# Small aiming marker.
	var crosshair := aim_direction * 30.0

	draw_rect(
		Rect2(
			crosshair - Vector2(2, 2),
			Vector2(4, 4)
		),
		Color8(244, 230, 140),
		false,
		1.0
	)

	# God mode indicator.
	if god_mode:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-16, -23),
			"GOD",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			8,
			Color8(255, 225, 80)
		)

	# Health pips.
	for i in range(max_health):
		var health_color := Color8(55, 45, 48)

		if i < health:
			health_color = Color8(232, 70, 80)

		draw_rect(
			Rect2(
				-10 + i * 5,
				-17,
				4,
				3
			),
			health_color,
			true
		)
