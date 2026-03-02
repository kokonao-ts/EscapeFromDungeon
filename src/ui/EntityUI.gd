extends Control
class_name EntityUI

@onready var hp_bar = $VBoxContainer/HPBar
@onready var hp_label = $VBoxContainer/HPLabel
@onready var block_label = $VBoxContainer/BlockLabel

func update_stats(stats: Stats):
	if not stats: return
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp

	var status_text = ""
	if stats.strength != 0:
		status_text += " Str: %d" % stats.strength
	if stats.vulnerable > 0:
		status_text += " Vul: %d" % stats.vulnerable
	if stats.weak > 0:
		status_text += " Weak: %d" % stats.weak

	hp_label.text = "HP: %d/%d%s" % [stats.hp, stats.max_hp, status_text]
	block_label.text = "Block: %d" % stats.block
	block_label.visible = stats.block > 0
