extends Control

var card_ui_scene = preload("res://src/ui/CardUI.tscn")
var cards_path = "res://src/cards/resources/"
var enemies_path = "res://src/entities/resources/"

@onready var card_list = %CardList
@onready var enemy_list = %EnemyList
@onready var combat_manager = %CombatManager
@onready var player = %Player
@onready var dummy = %Dummy
@onready var energy_label = %EnergyLabel
@onready var hand_ui = %HandUI

@onready var reset_button = %ResetButton
@onready var add_energy_button = %AddEnergyButton
@onready var clear_status_button = %ClearStatusButton
@onready var enemy_turn_button = $HBoxContainer/CombatArea/Controls/EnemyTurnButton
@onready var back_button = %BackButton

func _ready():
	# Initial setup
	RunManager.initialize_run()
	player.stats = RunManager.player_stats

	reset_dummy()

	combat_manager.deck_manager.hand_updated.connect(_on_hand_updated)
	var empty_deck: Array[CardResource] = []
	combat_manager.start_combat(player, [dummy], empty_deck)

	# Connect buttons
	reset_button.pressed.connect(reset_dummy)
	add_energy_button.pressed.connect(_on_add_energy)
	clear_status_button.pressed.connect(_on_clear_status)
	enemy_turn_button.pressed.connect(_on_enemy_turn)
	back_button.pressed.connect(_on_back_pressed)

	load_cards()
	load_enemies_recursive(enemies_path)
	update_ui()

func load_cards():
	var dir = DirAccess.open(cards_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var card = load(cards_path + file_name)
				if card is CardResource:
					add_card_to_list(card)
			file_name = dir.get_next()

func load_enemies_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					load_enemies_recursive(path + file_name + "/")
			elif file_name.ends_with(".tres"):
				var res = load(path + file_name)
				if res is EnemyResource:
					add_enemy_to_list(res)
			file_name = dir.get_next()

func add_card_to_list(card: CardResource):
	var btn = Button.new()
	btn.text = card.card_name
	btn.pressed.connect(func(): _on_card_list_item_pressed(card))
	card_list.add_child(btn)

func add_enemy_to_list(res: EnemyResource):
	var btn = Button.new()
	btn.text = res.enemy_name
	btn.pressed.connect(func(): _on_enemy_selected(res))
	enemy_list.add_child(btn)

func _on_card_list_item_pressed(card: CardResource):
	# Add a copy of the card to the "hand"
	combat_manager.deck_manager.hand.append(card.duplicate())
	combat_manager.deck_manager.hand_updated.emit()

func _on_enemy_selected(res: EnemyResource):
	# Replace dummy with real enemy logic
	dummy.set_script(load("res://src/entities/Enemy.gd"))
	dummy.setup(res)
	combat_manager.enemies = [dummy]
	update_ui()

func reset_dummy():
	dummy.set_script(load("res://src/entities/Entity.gd"))
	dummy.stats = Stats.new()
	dummy.stats.max_hp = 999
	dummy.stats.hp = 999
	# Reset position in case it moved during split/summon testing
	dummy.position = Vector2(600, 300)
	combat_manager.enemies = [dummy]
	dummy.update_ui()
	update_ui()

func _on_add_energy():
	combat_manager.energy += 3
	update_ui()

func _on_clear_status():
	player.stats = Stats.new()
	player.stats.max_hp = 80
	player.stats.hp = 80

	if dummy is Enemy:
		dummy.setup(dummy.enemy_resource)
	else:
		reset_dummy()

	player.update_ui()
	dummy.update_ui()
	update_ui()

func _on_enemy_turn():
	if dummy is Enemy:
		dummy.execute_turn(combat_manager, player)
	update_ui()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")

func _on_hand_updated():
	for child in hand_ui.get_children():
		child.queue_free()

	for card in combat_manager.deck_manager.hand:
		var card_ui = card_ui_scene.instantiate()
		hand_ui.add_child(card_ui)
		card_ui.setup(card)
		card_ui.card_played.connect(_on_card_played)

func _on_card_played(card_ui):
	combat_manager.play_card(card_ui.card_resource, dummy)
	update_ui()

func update_ui():
	if energy_label:
		energy_label.text = "Energy: %d/%d" % [combat_manager.energy, combat_manager.max_energy]
	player.update_ui()
	dummy.update_ui()
