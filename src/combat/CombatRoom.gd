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
	# Use data from RunManager
	player.stats = RunManager.player_stats
	# Setup sample data
	var strike = load("res://src/cards/resources/Strike.tres")
	var defend = load("res://src/cards/resources/Defend.tres")
	deck = [strike, strike, strike, defend, defend]

	player.stats = Stats.new()
	player.stats.max_hp = 80
	player.stats.hp = 80

	# Setup simple enemy for now
	enemy.stats = Stats.new()
	enemy.stats.max_hp = 50
	enemy.stats.hp = 50

	combat_manager.deck_manager.hand_updated.connect(_on_hand_updated)
	combat_manager.combat_finished.connect(_on_combat_finished)
	combat_manager.start_combat(player, [enemy], RunManager.deck)
	combat_manager.combat_won.connect(_on_combat_won)

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

func _on_combat_finished(win: bool):
	if win:
		print("You won!")
		# Check if it was a boss battle
		var act = RunManager.get_map()
		if RunManager.current_node_index == act.nodes.size() - 1:
			print("Boss defeated! Moving to next act...")
			if RunManager.current_act < 3:
				RunManager.next_act()
				get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")
			else:
				print("You've completed the game!")
				RunManager.initialize_run()
				get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")
		else:
			print("Combat won! Returning to map...")
			get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")
	else:
		print("Game Over!")
		RunManager.initialize_run()
		get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")
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
