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
			# Frozen turn skipping
			if player.stats.frozen > 0:
				player.stats.frozen -= 1
				player.update_ui()
				print("Player frozen, skipping turn!")
				transition_to(State.ENEMY_TURN)
				return

			# Stunned skipping
			if player.stats.stunned > 0:
				player.stats.stunned -= 1
				player.update_ui()
				print("Player stunned, skipping turn!")
				transition_to(State.ENEMY_TURN)
				return

			player.stats.reset_block()

			var actual_max_energy = max_energy
			if player.stats.slow > 0:
				actual_max_energy = max(0, actual_max_energy - player.stats.slow)

			energy = actual_max_energy

			var draw_count = 5
			if player.stats.draw_reduction > 0:
				draw_count = max(0, draw_count - player.stats.draw_reduction)

			deck_manager.draw_cards(draw_count)
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
	if card.type == CardResource.Type.ATTACK and player.stats.attack_locked > 0:
		print("Attacks are locked!")
		return

	var actual_cost = card.cost
	if card.free_if_chilled:
		var has_chill = false
		if target:
			if target.stats.chill > 0:
				has_chill = true
		elif card.target == CardResource.Target.ALL_ENEMIES:
			for e in enemies:
				if e.is_alive() and e.stats.chill > 0:
					has_chill = true
					break
		if has_chill:
			actual_cost = 0

	if energy >= actual_cost:
		energy -= actual_cost

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
					# Thorns damage back to player
					if target.stats.thorns > 0:
						player.stats.lose_hp(target.stats.thorns)
					# Electrified damage back to player
					if target.stats.electrified > 0:
						player.stats.lose_hp(target.stats.electrified)
				elif card.target == CardResource.Target.ALL_ENEMIES:
					for e in enemies:
						if e.is_alive():
							e.take_damage(base_damage)
							if e.stats.thorns > 0:
								player.stats.lose_hp(e.stats.thorns)
							if e.stats.electrified > 0:
								player.stats.lose_hp(e.stats.electrified)

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

		if card.burn > 0:
			if target:
				target.stats.burn += card.burn
				target.update_ui()
			elif card.target == CardResource.Target.ALL_ENEMIES:
				for e in enemies:
					if e.is_alive():
						e.stats.burn += card.burn
						e.update_ui()

		if card.chill > 0:
			if target:
				apply_chill(target, card.chill)
			elif card.target == CardResource.Target.ALL_ENEMIES:
				for e in enemies:
					if e.is_alive():
						apply_chill(e, card.chill)

		if card.self_damage > 0:
			player.stats.lose_hp(card.self_damage)
			player.update_ui()

		if card.exhaust:
			deck_manager.exhaust_card(card)
		else:
			deck_manager.discard_card(card)

		# Possession mechanic for Goblin Assassin
		if RunManager.character_class == CardResource.CharacterClass.GOBLIN_ASSASSIN:
			if card.card_id == "execute_knife" and target and not target.is_alive():
				if target is Enemy and target.enemy_resource:
					print("Possessing %s!" % target.enemy_resource.enemy_name)
					RunManager.possess_enemy(target.enemy_resource)
					# Handle body swap logic: filter hand, discard to draw, shuffle
					deck_manager.handle_body_swap(RunManager.deck)
					# Replenish hand if filtered cards left it small
					if deck_manager.hand.size() < 5:
						deck_manager.draw_cards(5 - deck_manager.hand.size())
					player.update_ui()

		# Body Swap mechanic for Goblin Mage
		if RunManager.character_class == CardResource.CharacterClass.GOBLIN_MAGE:
			if card.card_id == "body_swap" and target:
				var hp_threshold = player.stats.max_hp * 0.25
				if player.stats.hp <= hp_threshold:
					if target is Enemy and target.enemy_resource:
						print("Body Swapping with %s!" % target.enemy_resource.enemy_name)
						# Kill the target
						target.take_damage(9999)
						# Possess the body
						RunManager.possess_enemy(target.enemy_resource)
						# Handle body swap logic: filter hand, discard to draw, shuffle
						deck_manager.handle_body_swap(RunManager.deck)
						# Replenish hand
						if deck_manager.hand.size() < 5:
							deck_manager.draw_cards(5 - deck_manager.hand.size())
						player.update_ui()
				else:
					print("HP too high for Body Swap!")

		check_enemies_alive()
	else:
		print("Not enough energy!")

func end_player_turn():
	if current_state == State.PLAYER_TURN:
		# Process Burn at end of player turn
		_process_burn(player)
		_process_poison(player)

		player.stats.end_turn()
		player.update_ui()
		deck_manager.discard_hand()

		if player.stats.hp <= 0:
			var is_goblin = RunManager.character_class == CardResource.CharacterClass.GOBLIN_ASSASSIN or \
							RunManager.character_class == CardResource.CharacterClass.GOBLIN_MAGE
			if is_goblin:
				if RunManager.revert_to_core():
					print("Body died! Reverting to core...")
					deck_manager.handle_body_swap(RunManager.deck)
					player.update_ui()
					transition_to(State.ENEMY_TURN)
					return

			transition_to(State.LOSE)
		else:
			transition_to(State.ENEMY_TURN)

func execute_enemy_turns():
	for enemy in enemies:
		if enemy.is_alive():
			# Skip if frozen
			if enemy.stats.frozen > 0:
				enemy.stats.frozen -= 1
				enemy.update_ui()
				print("Enemy frozen, skipping turn!")
				continue

			# Skip if stunned
			if enemy.stats.stunned > 0:
				enemy.stats.stunned -= 1
				enemy.update_ui()
				print("Enemy stunned, skipping turn!")
				continue

			if enemy is Enemy:
				enemy.execute_turn(self, player)
			else:
				# Basic behavior fallback
				var damage = 6
				if enemy.stats.strength > 0:
					damage += enemy.stats.strength
				if enemy.stats.weak > 0:
					damage = floor(damage * 0.75)
				player.take_damage(damage)
				enemy.stats.end_turn()

			_process_burn(enemy)
			_process_poison(enemy)
			enemy.update_ui()

	if player.stats.hp <= 0:
		var is_goblin = RunManager.character_class == CardResource.CharacterClass.GOBLIN_ASSASSIN or \
						RunManager.character_class == CardResource.CharacterClass.GOBLIN_MAGE
		if is_goblin:
			if RunManager.revert_to_core():
				print("Body died! Reverting to core...")
				deck_manager.handle_body_swap(RunManager.deck)
				player.update_ui()
				transition_to(State.START_TURN)
				return

		transition_to(State.LOSE)
	else:
		transition_to(State.START_TURN)

func _process_burn(entity):
	if entity.stats.burn > 0:
		entity.stats.lose_hp(entity.stats.burn)
		entity.stats.burn = max(0, entity.stats.burn - 10)
		entity.update_ui()

func _process_poison(entity):
	if entity.stats.poison > 0:
		entity.stats.lose_hp(entity.stats.poison)
		entity.stats.poison = max(0, entity.stats.poison - 1)
		entity.update_ui()

func apply_chill(entity, stacks: int):
	entity.stats.chill += stacks
	if entity.stats.chill >= 10:
		entity.stats.chill -= 10
		entity.stats.frozen += 1
	entity.update_ui()

func check_enemies_alive():
	var all_dead = true
	for e in enemies:
		if e.is_alive():
			all_dead = false
			break

	if all_dead:
		transition_to(State.WIN)

func spawn_enemy(enemy_resource: EnemyResource):
	var enemy_scene = load("res://src/entities/Enemy.tscn")
	if not enemy_scene:
		# Fallback if scene is not found (assuming it exists or can be created)
		print("Enemy scene not found, cannot spawn!")
		return

	var new_enemy = enemy_scene.instantiate()
	var enemies_container = get_tree().root.find_child("Enemies", true, false)
	if enemies_container:
		enemies_container.add_child(new_enemy)
		new_enemy.setup(enemy_resource)
		enemies.append(new_enemy)
		# Position it randomly or based on existing enemies
		new_enemy.position = Vector2(800 + randf_range(-100, 100), 400 + randf_range(-100, 100))
	else:
		print("Enemies container not found!")
