extends Resource
class_name CardResource

enum Type { ATTACK, SKILL, POWER }
enum Target { ENEMY, SELF, ALL_ENEMIES }
enum CharacterClass { IRONCLAD, SILENT, WATCHER, NEUTRAL, GOBLIN_ASSASSIN }

@export var card_id: String = ""
@export var card_name: String = "Card"
@export var character_class: CharacterClass = CharacterClass.IRONCLAD
@export var cost: int = 1
@export var type: Type = Type.ATTACK
@export var target: Target = Target.ENEMY
@export var icon: String = "card_placeholder.png"
@export_multiline var description: String = ""

@export_group("Effects")
@export var damage: int = 0
@export var block: int = 0
@export var draw_cards: int = 0
@export var energy_gain: int = 0
@export var hits: int = 1

@export_group("Statuses")
@export var vulnerable: int = 0
@export var weak: int = 0
@export var strength: int = 0
@export var burn: int = 0
@export var chill: int = 0

@export_group("Special")
@export var exhaust: bool = false
@export var self_damage: int = 0
@export var free_if_chilled: bool = false

func apply_effects(user, targets):
	# Basic implementation to be expanded in CombatManager or Entity logic
	pass
