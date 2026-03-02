extends Node2D
class_name Entity

@export var stats: Stats
@onready var entity_ui = $EntityUI

signal died

func _ready():
	if stats:
		stats = stats.duplicate() # Unique stats for each instance
	update_ui()

func take_damage(amount: int):
	if stats:
		stats.take_damage(amount)
		update_ui()
		if stats.hp <= 0:
			died.emit()

func add_block(amount: int):
	if stats:
		stats.add_block(amount)
		update_ui()

func is_alive() -> bool:
	return stats.hp > 0 if stats else false

func update_ui():
	if not entity_ui:
		entity_ui = get_node_or_null("EntityUI")
	if entity_ui:
		entity_ui.update_stats(stats)
