class_name EntityUI
extends Control

var intent_label: Label
var name_label: Label

@onready var hp_bar = $VBoxContainer/HPBar
@onready var hp_label = $VBoxContainer/HPLabel
@onready var block_label = $VBoxContainer/BlockLabel

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
	if not stats:
		return
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.hp

	var status_text = ""
	if stats.strength != 0:
		status_text += " Str:%d" % stats.strength
	if stats.vulnerable > 0:
		status_text += " Vul:%d" % stats.vulnerable
	if stats.weak > 0:
		status_text += " Weak:%d" % stats.weak
	if stats.burn > 0:
		status_text += " Burn:%d" % stats.burn
	if stats.chill > 0:
		status_text += " Chill:%d" % stats.chill
	if stats.frozen > 0:
		status_text += " Frozen:%d" % stats.frozen
	if stats.poison > 0:
		status_text += " Poison:%d" % stats.poison
	if stats.evasion > 0:
		status_text += " Evade:%d" % stats.evasion
	if stats.thorns > 0:
		status_text += " Thorn:%d" % stats.thorns
	if stats.electrified > 0:
		status_text += " Elec:%d" % stats.electrified
	if stats.slow > 0:
		status_text += " Slow:%d" % stats.slow
	if stats.draw_reduction > 0:
		status_text += " Draw-:%d" % stats.draw_reduction
	if stats.stunned > 0:
		status_text += " Stun:%d" % stats.stunned
	if stats.attack_locked > 0:
		status_text += " Lock:%d" % stats.attack_locked

	hp_label.text = "HP:%d/%d%s" % [stats.hp, stats.max_hp, status_text]
	block_label.text = "Block:%d" % stats.block
	block_label.visible = stats.block > 0

	# Show name and intent if this belongs to an enemy
	var owner_node = get_parent()
	if owner_node is Enemy:
		_update_enemy_ui(owner_node)
	else:
		if name_label:
			name_label.visible = false
		if intent_label:
			intent_label.visible = false

func _update_enemy_ui(owner_node: Enemy):
	if owner_node.enemy_resource:
		name_label.text = owner_node.enemy_resource.enemy_name
		name_label.visible = true
	elif owner_node.stats.hp > 0: # Fallback
		name_label.text = "Enemy"
		name_label.visible = true
	else:
		name_label.visible = false

	if not owner_node.selected_actions.is_empty():
		var intents = []
		for action in owner_node.selected_actions:
			intents.append(_get_intent_text(action, owner_node))
		intent_label.text = "Intent: " + ", ".join(intents)
		intent_label.visible = true
	else:
		if intent_label:
			intent_label.visible = false

func _get_intent_text(action: EnemyAction, owner_node: Enemy) -> String:
	var result = "Action"
	match action.type:
		EnemyAction.Type.ATTACK:
			result = _get_attack_intent_text(action, owner_node)
		EnemyAction.Type.DEFEND:
			result = "Def %d" % action.block
		EnemyAction.Type.BUFF:
			result = "Buff"
		EnemyAction.Type.DEBUFF:
			result = "Debuff"
		EnemyAction.Type.HEAL:
			result = "Heal"
		EnemyAction.Type.SUMMON:
			result = "Summon"
		EnemyAction.Type.SPLIT:
			result = "Split"
	return result

func _get_attack_intent_text(action: EnemyAction, owner_node: Enemy) -> String:
	var damage = action.damage
	if owner_node.stats.strength > 0:
		damage += owner_node.stats.strength
	if owner_node.stats.weak > 0:
		damage = floor(damage * 0.75)
	if action.hits > 1:
		return "Atk %dx%d" % [damage, action.hits]
	return "Atk %d" % damage
