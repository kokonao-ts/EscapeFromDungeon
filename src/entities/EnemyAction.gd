extends Resource
class_name EnemyAction

enum Type { ATTACK, DEFEND, BUFF, DEBUFF, STUN }

@export var type: Type = Type.ATTACK
@export var damage: int = 0
@export var block: int = 0
@export var strength: int = 0
@export var vulnerable: int = 0
@export var weak: int = 0
@export var description: String = ""
@export var icon: String = "" # Path to icon or some identifier
