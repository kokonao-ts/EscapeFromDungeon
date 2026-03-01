extends Node
class_name CombatManager

enum State { START_COMBAT, START_TURN, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }

signal combat_won
signal combat_lost

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
			combat_won.emit()
		State.LOSE:
			print("Combat Lost!")
			combat_lost.emit()

func play_card(card: CardResource, target = null):
	if energy >= card.cost:
		energy -= card.cost

		# Apply effects
		if card.damage > 0:
			if target:
				target.take_damage(card.damage)
			elif card.target == CardResource.Target.ALL_ENEMIES:
				for e in enemies:
					e.take_damage(card.damage)

		if card.block > 0:
			player.add_block(card.block)

		if card.draw_cards > 0:
			deck_manager.draw_cards(card.draw_cards)

		energy += card.energy_gain

		deck_manager.discard_card(card)
		check_enemies_alive()
	else:
		print("Not enough energy!")

func end_player_turn():
	if current_state == State.PLAYER_TURN:
		deck_manager.discard_hand()
		transition_to(State.ENEMY_TURN)

func execute_enemy_turns():
	for enemy in enemies:
		if enemy.is_alive():
			# Simple AI: attack for 6
			player.take_damage(6)

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
