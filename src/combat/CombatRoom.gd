extends Node2D

var card_ui_scene = preload("res://src/ui/CardUI.tscn")
var battle_reward_scene = preload("res://src/ui/BattleReward.tscn")
var enemy_scene = preload("res://src/entities/Enemy.tscn")

var selected_enemy: Enemy = null

@onready var combat_manager = $CombatManager
@onready var hand_ui = $CanvasLayer/HandUI
@onready var energy_label = $CanvasLayer/UI/EnergyLabel
@onready var player = $Player
@onready var enemies_container = $Enemies

func _ready():
	# Use data from RunManager
	player.stats = RunManager.player_stats

	# Setup enemies based on RunManager data
	var map = RunManager.get_map()
	var current_node = map.nodes[RunManager.current_node_index]

	var enemies_list = []
	var enemy_resources = current_node.data.get("enemies")
	if enemy_resources:
		var i = 0
		for res in enemy_resources:
			var enemy_inst = enemy_scene.instantiate()
			enemies_container.add_child(enemy_inst)
			enemy_inst.setup(res)
			# Distribute enemies
			enemy_inst.position = Vector2(800, 200 + i * 150)
			enemies_list.append(enemy_inst)
			i += 1
	else:
		# Compatibility with old single-enemy data
		var enemy_res = current_node.data.get("enemy_resource")
		var enemy_inst = enemy_scene.instantiate()
		enemies_container.add_child(enemy_inst)
		if enemy_res:
			enemy_inst.setup(enemy_res)
		else:
			var stats = Stats.new()
			stats.max_hp = 50
			stats.hp = 50
			enemy_inst.stats = stats
		enemy_inst.position = Vector2(800, 400)
		enemies_list.append(enemy_inst)

	combat_manager.deck_manager.hand_updated.connect(_on_hand_updated)
	combat_manager.combat_finished.connect(_on_combat_finished)
	combat_manager.start_combat(player, enemies_list, RunManager.deck)

	$CanvasLayer/EndTurnButton.pressed.connect(_on_end_turn_pressed)
	$CanvasLayer/MenuButton.pressed.connect(_on_menu_pressed)
	$CanvasLayer/DebugUI/KillEnemyButton.pressed.connect(_on_kill_enemy_pressed)
	$CanvasLayer/DebugUI/KillPlayerButton.pressed.connect(_on_kill_player_pressed)
	update_ui()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			$CanvasLayer/DebugUI.visible = !$CanvasLayer/DebugUI.visible

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if an enemy was clicked for targeting
		for enemy in combat_manager.enemies:
			if enemy.is_alive():
				# Simple rect check for targeting if not using areas
				var mouse_pos = get_local_mouse_position()
				if mouse_pos.distance_to(enemy.position) < 100: # Approximate
					selected_enemy = enemy
					print("Selected enemy: ", enemy.enemy_resource.enemy_name if enemy.enemy_resource else "Enemy")
					break

func _on_kill_enemy_pressed():
	for enemy in combat_manager.enemies:
		if enemy.is_alive():
			enemy.take_damage(999)
			break
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
	# If no enemy selected, pick the first alive one
	var target = selected_enemy
	if not target or not target.is_alive():
		for e in combat_manager.enemies:
			if e.is_alive():
				target = e
				break

	combat_manager.play_card(card_ui.card_resource, target)
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
	RunManager.add_card_to_run(card)
	print("Added %s to run deck" % card.card_name)

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
	for enemy in combat_manager.enemies:
		enemy.update_ui()
