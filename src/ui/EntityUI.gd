extends Control
class_name EntityUI

@onready var hp_bar = $VBoxContainer/HPBar
@onready var hp_label = $VBoxContainer/HPLabel
@onready var block_label = $VBoxContainer/BlockLabel

func update_stats(stats: Stats):
	if not stats: return
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp
	hp_label.text = "HP: %d/%d" % [stats.hp, stats.max_hp]
	if stats.burn > 0:
		hp_label.text += " (Burn: %d)" % stats.burn
	block_label.text = "Block: %d" % stats.block
	block_label.visible = stats.block > 0
