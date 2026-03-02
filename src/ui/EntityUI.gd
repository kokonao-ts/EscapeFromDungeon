extends Control
class_name EntityUI

@onready var hp_bar = $VBoxContainer/HPBar
@onready var hp_label = $VBoxContainer/HPLabel
@onready var block_label = $VBoxContainer/BlockLabel
var intent_label: Label
var name_label: Label

func _ready():
	# Dynamically add name label if it doesn't exist
	if not $VBoxContainer.has_node("NameLabel"):
		name_label = Label.new()
		name_label.name = "NameLabel"
		# Add to the top of the VBoxContainer
		$VBoxContainer.add_child(name_label)
		$VBoxContainer.move_child(name_label, 0)
	else:
		name_label = $VBoxContainer/NameLabel

	# Dynamically add intent label if it doesn't exist
	if not $VBoxContainer.has_node("IntentLabel"):
		intent_label = Label.new()
		intent_label.name = "IntentLabel"
		$VBoxContainer.add_child(intent_label)
	else:
		intent_label = $VBoxContainer/IntentLabel

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
	if stats.burn > 0:
		status_text += " Burn: %d" % stats.burn
	if stats.chill > 0:
		status_text += " Chill: %d" % stats.chill
	if stats.frozen > 0:
		status_text += " Frozen: %d" % stats.frozen

	hp_label.text = "HP: %d/%d%s" % [stats.hp, stats.max_hp, status_text]
	block_label.text = "Block: %d" % stats.block
	block_label.visible = stats.block > 0

	# Show name and intent if this belongs to an enemy
	var owner_node = get_parent()
	if owner_node is Enemy:
		if owner_node.enemy_resource:
			name_label.text = owner_node.enemy_resource.enemy_name
			name_label.visible = true
		elif owner_node is Enemy and owner_node.stats.hp > 0: # Fallback
			name_label.text = "Enemy"
			name_label.visible = true
		else:
			name_label.visible = false

		if owner_node.current_action:
			var action = owner_node.current_action
			var intent_text = "Intent: "
			match action.type:
				EnemyAction.Type.ATTACK:
					var damage = action.damage
					if owner_node.stats.strength > 0:
						damage += owner_node.stats.strength
					if owner_node.stats.weak > 0:
						damage = floor(damage * 0.75)
					intent_text += "Attack %d" % damage
				EnemyAction.Type.DEFEND:
					intent_text += "Defend %d" % action.block
				EnemyAction.Type.BUFF:
					intent_text += "Buff"
				EnemyAction.Type.DEBUFF:
					intent_text += "Debuff"
			intent_label.text = intent_text
			intent_label.visible = true
		else:
			if intent_label:
				intent_label.visible = false
	else:
		if name_label:
			name_label.visible = false
		if intent_label:
			intent_label.visible = false
