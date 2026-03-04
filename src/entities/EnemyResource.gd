class_name EnemyResource
extends Resource

@export var enemy_id: String = ""
@export var enemy_name: String = "Enemy"
@export var character_class: CardResource.CharacterClass = CardResource.CharacterClass.NEUTRAL
@export var max_hp: int = 50
@export var energy_per_turn: int = 2
@export var max_actions_per_turn: int = 3
@export var actions: Array[EnemyAction] = []
@export var behavior_script: GDScript # Optional: for complex logic

# Weight for random selection if simple
@export var action_weights: Array[float] = []

# For splitting behavior
@export var split_hp_threshold: float = 0.5
@export var split_result: Array[EnemyResource] = []
