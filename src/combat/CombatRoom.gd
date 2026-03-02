extends Node2D

@onready var combat_manager = $CombatManager
@onready var hand_ui = $CanvasLayer/HandUI
@onready var energy_label = $CanvasLayer/UI/EnergyLabel
@onready var player = $Player
@onready var enemy = $Enemy

var card_ui_scene = preload("res://src/ui/CardUI.tscn")
var battle_reward_scene = preload("res://src/ui/BattleReward.tscn")

func _ready():
	# Use data from RunManager
	player.stats = RunManager.player_stats

	# Setup enemy based on RunManager data
	var map = RunManager.get_map()
	var current_node = map.nodes[RunManager.current_node_index]
	var enemy_res = current_node.data.get("enemy_resource")

	if enemy_res and enemy_res is EnemyResource:
		enemy.set_script(load("res://src/entities/Enemy.gd"))
		enemy.setup(enemy_res)
	else:
		# Fallback to simple enemy
		enemy.stats = Stats.new()
		enemy.stats.max_hp = 50
		enemy.stats.hp = 50

	combat_manager.deck_manager.hand_updated.connect(_on_hand_updated)
	combat_manager.combat_finished.connect(_on_combat_finished)
	combat_manager.start_combat(player, [enemy], RunManager.deck)

	$CanvasLayer/EndTurnButton.pressed.connect(_on_end_turn_pressed)
	$CanvasLayer/MenuButton.pressed.connect(_on_menu_pressed)
	$CanvasLayer/DebugUI/KillEnemyButton.pressed.connect(_on_kill_enemy_pressed)
	$CanvasLayer/DebugUI/KillPlayerButton.pressed.connect(_on_kill_player_pressed)
	update_ui()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			$CanvasLayer/DebugUI.visible = !$CanvasLayer/DebugUI.visible

func _on_kill_enemy_pressed():
	enemy.take_damage(999)
	combat_manager.check_enemies_alive()

func _on_kill_player_pressed():
	player.take_damage(999)
	combat_manager.transition_to(CombatManager.State.LOSE)

func _on_hand_updated():
	if not hand_ui:
		return

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

func _on_menu_pressed():
	var pause_menu = load("res://src/ui/PauseMenu.tscn").instantiate()
	$CanvasLayer.add_child(pause_menu)

func _on_combat_finished(win: bool):
	if win:
		print("You won!")
		show_rewards()
	else:
		print("Game Over!")
		get_tree().change_scene_to_file("res://src/ui/EndingScreen.tscn")

func show_rewards():
	var reward_ui = battle_reward_scene.instantiate()
	$CanvasLayer.add_child(reward_ui)
	reward_ui.card_selected.connect(_on_reward_card_selected)
	# Connect to tree_exited to handle returning to map after reward is closed
	reward_ui.tree_exited.connect(_on_reward_finished)

func _on_reward_card_selected(card: CardResource):
	RunManager.deck.append(card)
	print("Added %s to deck" % card.card_name)

func _on_reward_finished():
	# Check if it was a boss battle
	var act = RunManager.get_map()
	if RunManager.current_node_index == act.nodes.size() - 1:
		print("Boss defeated! Moving to next act...")
		if RunManager.current_act < 3:
			RunManager.next_act()
			get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")
		else:
			print("You've completed the game!")
			RunManager.initialize_run(RunManager.character_class)
			get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")
	else:
		print("Returning to map...")
		get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func update_ui():
	if energy_label:
		energy_label.text = "Energy: %d/%d" % [combat_manager.energy, combat_manager.max_energy]
	player.update_ui()
	enemy.update_ui()
