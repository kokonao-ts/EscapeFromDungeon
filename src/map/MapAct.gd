class_name MapAct
extends Resource

@export var nodes: Array[MapNode] = []
@export var act_number: int = 1

func _init(number = 1):
	act_number = number
