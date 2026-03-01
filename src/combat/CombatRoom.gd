extends Node2D

@onready var combat_manager = $CombatManager
@onready var hand_ui = $CanvasLayer/HandUI
@onready var energy_label = $CanvasLayer/UI/EnergyLabel
@onready var player = $Player
@onready var enemy = $Enemy

var card_ui_scene = preload("res://src/ui/CardUI.tscn")
var reward_ui_scene = preload("res://src/ui/BattleReward.tscn")

var deck: Array[CardResource] = []

func _ready():
	# Setup sample data
	var strike = load("res://src/cards/resources/Strike.tres")
	var defend = load("res://src/cards/resources/Defend.tres")
	deck = [strike, strike, strike, defend, defend]

	player.stats = Stats.new()
	player.stats.max_hp = 80
	player.stats.hp = 80

	enemy.stats = Stats.new()
	enemy.stats.max_hp = 50
	enemy.stats.hp = 50

	combat_manager.deck_manager.hand_updated.connect(_on_hand_updated)
	combat_manager.combat_won.connect(_on_combat_won)
	combat_manager.start_combat(player, [enemy], deck)

	$CanvasLayer/EndTurnButton.pressed.connect(_on_end_turn_pressed)
	update_ui()

func _on_hand_updated():
	for child in hand_ui.get_children():
		child.queue_free()

	for card in combat_manager.deck_manager.hand:
		var card_ui = card_ui_scene.instantiate()
		hand_ui.add_child(card_ui)
		card_ui.setup(card)
		card_ui.card_played.connect(_on_card_played)

func _on_card_played(card_ui):
	combat_manager.play_card(card_ui.card_resource, enemy)
	update_ui()

func _on_end_turn_pressed():
	combat_manager.end_player_turn()
	update_ui()

func _on_combat_won():
	var reward_ui = reward_ui_scene.instantiate()
	$CanvasLayer.add_child(reward_ui)

	var possible_rewards: Array[CardResource] = [
		load("res://src/cards/resources/Strike.tres"),
		load("res://src/cards/resources/Defend.tres"),
		load("res://src/cards/resources/Bash.tres"),
		load("res://src/cards/resources/IronWave.tres")
	]
	reward_ui.setup(possible_rewards)
	reward_ui.card_selected.connect(_on_reward_selected)

func _on_reward_selected(card: CardResource):
	deck.append(card)
	print("Added card to deck: ", card.card_name)
	print("Current deck size: ", deck.size())

func update_ui():
	energy_label.text = "Energy: %d/%d" % [combat_manager.energy, combat_manager.max_energy]
	player.update_ui()
	enemy.update_ui()
