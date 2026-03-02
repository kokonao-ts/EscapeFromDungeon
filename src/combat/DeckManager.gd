extends Node
class_name DeckManager

signal hand_updated

var draw_pile: Array[CardResource] = []
var hand: Array[CardResource] = []
var discard_pile: Array[CardResource] = []
var exhaust_pile: Array[CardResource] = []

func setup_deck(starting_deck: Array[CardResource]):
	draw_pile = starting_deck.duplicate()
	draw_pile.shuffle()
	hand = []
	discard_pile = []
	exhaust_pile = []

func draw_cards(amount: int):
	for i in range(amount):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			reshuffle_discard_to_draw()

		var card = draw_pile.pop_back()
		hand.append(card)

	hand_updated.emit()

func reshuffle_discard_to_draw():
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile = []

func discard_card(card: CardResource):
	var idx = hand.find(card)
	if idx != -1:
		hand.remove_at(idx)
		discard_pile.append(card)
		hand_updated.emit()

func exhaust_card(card: CardResource):
	var idx = hand.find(card)
	if idx != -1:
		hand.remove_at(idx)
		exhaust_pile.append(card)
		hand_updated.emit()

func discard_hand():
	while not hand.is_empty():
		discard_pile.append(hand.pop_back())
	hand_updated.emit()
