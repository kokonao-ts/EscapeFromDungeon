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
	draw_pile.append_array(discard_pile)
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

func swap_deck_on_possession(new_body_deck: Array[CardResource], body_class: int):
	# 1. Collect all non-removable cards from current combat state
	var preserved_cards: Array[CardResource] = []

	var all_current_cards = draw_pile + hand + discard_pile
	for card in all_current_cards:
		# Preserve techniques and starter cards
		if card.is_technique or card.rarity == CardResource.Rarity.STARTER:
			preserved_cards.append(card)

	# 2. Add any owned techniques that might not be in the current deck but match the body
	# This ensures if we switch to a body that CAN use a technique we own, it gets added.
	for tech in RunManager.owned_techniques:
		if not preserved_cards.has(tech):
			preserved_cards.append(tech)

	# 3. Reset combat piles
	hand = []
	discard_pile = []
	# Exhaust pile usually persists across body swaps as it represents spent energy/actions

	# 4. Build new draw pile
	draw_pile = []

	# Add the new body's intrinsic cards
	draw_pile.append_array(new_body_deck)

	# Add valid preserved cards
	for card in preserved_cards:
		if card.is_technique:
			# Filter techniques by the new body's class
			var matches = card.character_class == body_class or \
						  card.character_class == 3 or \
						  card.character_class == 6
			if matches:
				draw_pile.append(card)
		else:
			# Always preserve starter/fixed cards
			draw_pile.append(card)

	draw_pile.shuffle()
	hand_updated.emit()
