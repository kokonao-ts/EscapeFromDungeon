extends Resource
class_name CardResource

enum Type { ATTACK, SKILL, POWER }
enum Target { ENEMY, SELF, ALL_ENEMIES }

@export var card_id: String = ""
@export var card_name: String = "Card"
@export var cost: int = 1
@export var type: Type = Type.ATTACK
@export var target: Target = Target.ENEMY
@export var icon: String = "card_placeholder.png"
@export var description: String = ""

@export var damage: int = 0
@export var block: int = 0
@export var draw_cards: int = 0
@export var energy_gain: int = 0

func apply_effects(user, targets):
	# Basic implementation to be expanded in CombatManager or Entity logic
	pass
