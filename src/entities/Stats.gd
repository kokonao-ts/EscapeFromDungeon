extends Resource
class_name Stats

@export var max_hp: int = 50
@export var hp: int = 50
@export var block: int = 0

@export var strength: int = 0
@export var weak: int = 0
@export var vulnerable: int = 0

func take_damage(amount: int):
	var modified_damage = amount
	if vulnerable > 0:
		modified_damage = floor(modified_damage * 1.5)

	if block >= modified_damage:
		block -= modified_damage
	else:
		var remaining = modified_damage - block
		block = 0
		hp = max(0, hp - remaining)

func add_block(amount: int):
	block += amount

func lose_hp(amount: int):
	hp = max(0, hp - amount)

func reset_block():
	block = 0

func end_turn():
	if weak > 0:
		weak -= 1
	if vulnerable > 0:
		vulnerable -= 1
