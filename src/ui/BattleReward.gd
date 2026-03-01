extends Control
class_name BattleReward

signal card_selected(card: CardResource)

@onready var card_container = $CenterContainer/VBoxContainer/CardContainer
var card_ui_scene = preload("res://src/ui/CardUI.tscn")

func setup(available_cards: Array[CardResource]):
	# Clear existing
	for child in card_container.get_children():
		child.queue_free()

	# Create 3 random choices from available_cards
	var choices = available_cards.duplicate()
	choices.shuffle()

	for i in range(min(3, choices.size())):
		var card = choices[i]
		var card_ui = card_ui_scene.instantiate()
		card_container.add_child(card_ui)
		card_ui.setup(card)
		card_ui.card_played.connect(_on_card_selected.bind(card))

func _on_card_selected(card_ui_not_used, card: CardResource):
	card_selected.emit(card)
	queue_free()
