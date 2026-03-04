class_name MapNode
extends Resource

enum Type { COMBAT, ELITE, BOSS, SHOP, REST, EVENT }

@export var type: Type = Type.COMBAT
@export var position: Vector2
@export var connections: Array[int] = [] # Indices of next possible nodes
@export var act: int = 1

# Metadata like enemy type, etc.
@export var data: Dictionary = {}
