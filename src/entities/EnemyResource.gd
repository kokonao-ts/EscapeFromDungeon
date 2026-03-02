extends Resource
class_name EnemyResource

@export var enemy_id: String = ""
@export var enemy_name: String = "Enemy"
@export var max_hp: int = 50
@export var actions: Array[EnemyAction] = []
@export var behavior_script: GDScript # Optional: for complex logic

# Weight for random selection if simple
@export var action_weights: Array[float] = []
