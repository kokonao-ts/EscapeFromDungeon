extends Control

signal card_selected(card: CardResource)

@onready var card_container = $VBoxContainer/CardContainer
var card_ui_scene = preload("res://src/ui/CardUI.tscn")

func _ready():
	generate_rewards()

func generate_rewards():
	var pool = RunManager.get_card_pool()
	pool.shuffle()

	# Select 3 unique cards from the pool
	var choices = pool.slice(0, 3)

	for card in choices:
		var card_ui = card_ui_scene.instantiate()
		card_container.add_child(card_ui)
		card_ui.setup(card)
		card_ui.card_played.connect(_on_card_selected.bind(card))

func _on_card_selected(card_ui, card: CardResource):
	card_selected.emit(card)
	queue_free()
