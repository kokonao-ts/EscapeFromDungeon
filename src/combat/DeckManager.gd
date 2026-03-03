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

func handle_body_swap(new_master_deck: Array[CardResource]):
	# Use a dictionary to track instance counts in the new master deck
	var master_counts = {}
	for card in new_master_deck:
		master_counts[card] = master_counts.get(card, 0) + 1

	# 1. Filter hand: remove cards that are no longer in the master deck or exceed allowed count
	var new_hand: Array[CardResource] = []
	var active_counts = {}
	for card in hand:
		if master_counts.get(card, 0) > active_counts.get(card, 0):
			new_hand.append(card)
			active_counts[card] = active_counts.get(card, 0) + 1
	hand = new_hand

	# 2. Filter exhaust_pile
	var new_exhaust: Array[CardResource] = []
	for card in exhaust_pile:
		if master_counts.get(card, 0) > active_counts.get(card, 0):
			new_exhaust.append(card)
			active_counts[card] = active_counts.get(card, 0) + 1
	exhaust_pile = new_exhaust

	# 3. Rebuild draw_pile: all cards remaining from master_counts that are not in active_counts
	draw_pile.clear()
	for card in master_counts:
		var remaining = master_counts[card] - active_counts.get(card, 0)
		for i in range(remaining):
			draw_pile.append(card)

	# 4. Clear discard_pile as requested
	discard_pile.clear()

	draw_pile.shuffle()
	hand_updated.emit()
