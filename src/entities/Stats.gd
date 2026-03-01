extends Resource
class_name Stats

@export var max_hp: int = 50
@export var hp: int = 50
@export var block: int = 0

func take_damage(amount: int):
	if block >= amount:
		block -= amount
	else:
		var remaining = amount - block
		block = 0
		hp = max(0, hp - remaining)

func add_block(amount: int):
	block += amount

func reset_block():
	block = 0
