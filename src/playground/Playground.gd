extends Control

@onready var card_list = %CardList
@onready var combat_manager = %CombatManager
@onready var player = %Player
@onready var dummy = %Dummy
@onready var energy_label = %EnergyLabel
@onready var hand_ui = %HandUI

@onready var reset_button = %ResetButton
@onready var add_energy_button = %AddEnergyButton
@onready var clear_status_button = %ClearStatusButton
@onready var back_button = %BackButton

var card_ui_scene = preload("res://src/ui/CardUI.tscn")
var cards_path = "res://src/cards/resources/"

func _ready():
	# Initial setup
	RunManager.initialize_run()
	player.stats = RunManager.player_stats

	reset_dummy()

	combat_manager.deck_manager.hand_updated.connect(_on_hand_updated)
	combat_manager.start_combat(player, [dummy], [])

	# Connect buttons
	reset_button.pressed.connect(reset_dummy)
	add_energy_button.pressed.connect(_on_add_energy)
	clear_status_button.pressed.connect(_on_clear_status)
	back_button.pressed.connect(_on_back_pressed)

	load_cards()
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
	else:
		print("An error occurred when trying to access the path.")

func add_card_to_list(card: CardResource):
	var btn = Button.new()
	btn.text = card.card_name
	btn.pressed.connect(func(): _on_card_list_item_pressed(card))
	card_list.add_child(btn)

func _on_card_list_item_pressed(card: CardResource):
	# Add a copy of the card to the "hand"
	combat_manager.deck_manager.hand.append(card.duplicate())
	combat_manager.deck_manager.hand_updated.emit()

func reset_dummy():
	dummy.stats = Stats.new()
	dummy.stats.max_hp = 999
	dummy.stats.hp = 999
	dummy.update_ui()
	update_ui()

func _on_add_energy():
	combat_manager.energy += 3
	update_ui()

func _on_clear_status():
	player.stats.strength = 0
	player.stats.weak = 0
	player.stats.vulnerable = 0
	dummy.stats.strength = 0
	dummy.stats.weak = 0
	dummy.stats.vulnerable = 0
	player.update_ui()
	dummy.update_ui()
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
