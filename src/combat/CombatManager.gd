extends Node
class_name CombatManager

enum State { START_COMBAT, START_TURN, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }

signal combat_finished(win: bool)

var current_state: State = State.START_COMBAT
var energy: int = 0
var max_energy: int = 3

@onready var deck_manager: DeckManager = $DeckManager

# In a real setup, these would be references to the actual nodes
var player = null
var enemies: Array = []

func _ready():
	pass

func start_combat(p, ens: Array, deck: Array[CardResource]):
	player = p
	enemies = ens
	deck_manager.setup_deck(deck)
	transition_to(State.START_TURN)

func transition_to(new_state: State):
	current_state = new_state
	match current_state:
		State.START_TURN:
			player.stats.reset_block()
			energy = max_energy
			deck_manager.draw_cards(5)
			transition_to(State.PLAYER_TURN)
		State.PLAYER_TURN:
			pass # Wait for player input
		State.ENEMY_TURN:
			execute_enemy_turns()
		State.WIN:
			print("Combat Won!")
			combat_finished.emit(true)
		State.LOSE:
			print("Combat Lost!")
			combat_finished.emit(false)

func play_card(card: CardResource, target = null):
	if energy >= card.cost:
		energy -= card.cost

		# Damage Calculation
		var base_damage = card.damage
		if base_damage > 0:
			base_damage += player.stats.strength
			if player.stats.weak > 0:
				base_damage = floor(base_damage * 0.75)

		# Apply effects
		if base_damage > 0:
			for i in range(card.hits):
				if target:
					target.take_damage(base_damage)
				elif card.target == CardResource.Target.ALL_ENEMIES:
					for e in enemies:
						if e.is_alive():
							e.take_damage(base_damage)

		if card.block > 0:
			player.add_block(card.block)

		if card.draw_cards > 0:
			deck_manager.draw_cards(card.draw_cards)

		energy += card.energy_gain

		if card.vulnerable > 0:
			if target:
				target.stats.vulnerable += card.vulnerable
				target.update_ui()
			elif card.target == CardResource.Target.ALL_ENEMIES:
				for e in enemies:
					if e.is_alive():
						e.stats.vulnerable += card.vulnerable
						e.update_ui()

		if card.weak > 0:
			if target:
				target.stats.weak += card.weak
				target.update_ui()
			elif card.target == CardResource.Target.ALL_ENEMIES:
				for e in enemies:
					if e.is_alive():
						e.stats.weak += card.weak
						e.update_ui()

		if card.strength > 0:
			player.stats.strength += card.strength
			player.update_ui()

		if card.self_damage > 0:
			player.stats.lose_hp(card.self_damage)
			player.update_ui()

		if card.exhaust:
			deck_manager.exhaust_card(card)
		else:
			deck_manager.discard_card(card)

		check_enemies_alive()
	else:
		print("Not enough energy!")

func end_player_turn():
	if current_state == State.PLAYER_TURN:
		player.stats.end_turn()
		player.update_ui()
		deck_manager.discard_hand()
		transition_to(State.ENEMY_TURN)

func execute_enemy_turns():
	for enemy in enemies:
		if enemy.is_alive():
			var damage = 6
			# Simple implementation of status for enemies if they had stats
			if enemy.stats.strength > 0:
				damage += enemy.stats.strength
			if enemy.stats.weak > 0:
				damage = floor(damage * 0.75)

			player.take_damage(damage)
			enemy.stats.end_turn()
			enemy.update_ui()

	if player.stats.hp <= 0:
		transition_to(State.LOSE)
	else:
		transition_to(State.START_TURN)

func check_enemies_alive():
	var all_dead = true
	for e in enemies:
		if e.is_alive():
			all_dead = false
			break

	if all_dead:
		transition_to(State.WIN)
