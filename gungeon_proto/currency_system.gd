extends Node

var gold: int = 0


func add_gold(amount: int) -> void:
	gold += maxi(
		0,
		amount
	)


func can_afford(amount: int) -> bool:
	return gold >= amount


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true

	if gold < amount:
		return false

	gold -= amount

	return true