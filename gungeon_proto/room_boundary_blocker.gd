extends Node2D

var room_rect: Rect2 = Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)


func _ready() -> void:
	add_to_group(
		"bullet_blockers"
	)


func configure(
	rect_value: Rect2
) -> void:
	room_rect = rect_value


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	var local_point: Vector2 = to_local(
		global_point
	)

	# Thu nhỏ vùng đi được theo bán kính projectile.
	# Khi mép projectile chạm tường bao thì được tính là impact,
	# thay vì đợi tâm projectile bay hẳn ra ngoài.
	var safe_rect: Rect2 = room_rect.grow(
		-projectile_radius
	)

	if (
		safe_rect.size.x <= 0.0
		or safe_rect.size.y <= 0.0
	):
		return true

	return not safe_rect.has_point(
		local_point
	)


func is_outer_boundary() -> bool:
	return true