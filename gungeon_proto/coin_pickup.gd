extends Node2D

var amount: int = 1

var magnet_radius: float = 130.0
var collect_radius: float = 13.0

var magnet_speed: float = 260.0

var life_time: float = 0.0


func _ready() -> void:
	add_to_group("room_pickups")

	queue_redraw()


func _process(delta: float) -> void:
	life_time += delta

	var player_value = get_tree().get_first_node_in_group(
		"player"
	)

	if not is_instance_valid(player_value):
		return

	var player: Node2D = player_value as Node2D

	var to_player: Vector2 = (
		player.global_position
		- global_position
	)

	var distance: float = to_player.length()

	if distance <= collect_radius:
		if player.has_method("add_gold"):
			player.call(
				"add_gold",
				amount
			)

		queue_free()
		return

	if (
		distance <= magnet_radius
		and distance > 0.001
	):
		global_position += (
			to_player.normalized()
			* magnet_speed
			* delta
		)

	queue_redraw()


func _draw() -> void:
	var bounce: float = (
		sin(life_time * 7.0)
		* 2.0
	)

	draw_rect(
		Rect2(
			-5,
			5,
			10,
			3
		),
		Color8(8, 8, 12, 140),
		true
	)

	draw_circle(
		Vector2(0, bounce),
		5.0,
		Color8(160, 105, 25)
	)

	draw_circle(
		Vector2(0, bounce),
		3.0,
		Color8(245, 195, 55)
	)

	draw_rect(
		Rect2(
			-1,
			bounce - 3,
			2,
			6
		),
		Color8(255, 235, 135),
		true
	)