extends Control
class_name CardUI

signal card_played(card_ui)

var card_resource: CardResource
@onready var name_label = $VBoxContainer/Name
@onready var cost_label = $VBoxContainer/Cost
@onready var description_label = $VBoxContainer/Description
@onready var icon_texture = $VBoxContainer/Icon

func setup(card: CardResource):
	card_resource = card
	name_label.text = card.card_name
	cost_label.text = str(card.cost)
	description_label.text = card.description
	icon_texture.texture = AssetHelper.get_texture(card.icon)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_played.emit(self)
