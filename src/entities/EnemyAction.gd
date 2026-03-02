extends Resource
class_name EnemyAction

enum Type { ATTACK, DEFEND, BUFF, DEBUFF, STUN, HEAL, SUMMON, SPLIT, SPECIAL }

@export var type: Type = Type.ATTACK
@export var damage: int = 0
@export var block: int = 0
@export var strength: int = 0
@export var vulnerable: int = 0
@export var weak: int = 0
@export var poison: int = 0
@export var burn: int = 0
@export var chill: int = 0
@export var evasion: int = 0
@export var thorns: int = 0
@export var electrified: int = 0
@export var slow: int = 0
@export var draw_reduction: int = 0
@export var stun: int = 0
@export var attack_lock: int = 0
@export var heal: int = 0
@export var self_damage: int = 0
@export var hits: int = 1
@export var cost: int = 1
@export var description: String = ""
@export var icon: String = ""
@export var summon_enemy: EnemyResource # For SUMMON and SPLIT type actions
