extends Resource
class_name Stats

@export var max_hp: int = 50
@export var hp: int = 50
@export var block: int = 0

@export var strength: int = 0
@export var weak: int = 0
@export var vulnerable: int = 0
@export var burn: int = 0
@export var chill: int = 0
@export var frozen: int = 0

# New status effects
@export var poison: int = 0
@export var evasion: int = 0
@export var thorns: int = 0
@export var electrified: int = 0
@export var slow: int = 0
@export var draw_reduction: int = 0
@export var stunned: int = 0
@export var attack_locked: int = 0

func take_damage(amount: int):
	if evasion > 0:
		evasion -= 1
		print("Evaded attack!")
		return

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
	if stunned > 0:
		stunned -= 1
	if attack_locked > 0:
		attack_locked -= 1
	if slow > 0:
		slow -= 1
	if draw_reduction > 0:
		draw_reduction -= 1
	# Evasion usually expires at end of turn in Slay the Spire clones
	if evasion > 0:
		evasion = 0
	# Burn, Chill/Frozen, and Poison are typically handled by CombatManager
