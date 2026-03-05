class_name CombatManager
extends Node

signal combat_finished(win: bool)

enum State { START_COMBAT, START_TURN, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }

var current_state: State = State.START_COMBAT
var energy: int = 0
var max_energy: int = 3
var player = null
var enemies: Array = []

@onready var deck_manager: DeckManager = $DeckManager

func _ready():
	pass

func start_combat(p, ens: Array, deck_arr: Array[CardResource]):
	player = p
	enemies = ens
	deck_manager.setup_deck(deck_arr)
	transition_to(State.START_TURN)

func transition_to(new_state: State):
	current_state = new_state
	match current_state:
		State.START_TURN:
			_handle_start_turn()
		State.PLAYER_TURN:
			pass # Wait for player input
		State.ENEMY_TURN:
			execute_enemy_turns()
		State.WIN:
			print("Combat Won!")
			_award_gold()
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
		if _is_target_chilled(card, target):
			actual_cost = 0

	if energy >= actual_cost:
		energy -= actual_cost

		var targets: Array[Entity] = []
		if card.target == CardResource.Target.SELF:
			targets.append(player)
		elif card.target == CardResource.Target.ENEMY:
			if target:
				targets.append(target)
		elif card.target == CardResource.Target.ALL_ENEMIES:
			for e in enemies:
				if e.is_alive():
					targets.append(e)

		# Execute card effects
		card.apply_effects(player, targets, self)

		if card.exhaust:
			deck_manager.exhaust_card(card)
		else:
			deck_manager.discard_card(card)

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
			if _check_goblin_revert():
				return
			transition_to(State.LOSE)
		else:
			transition_to(State.ENEMY_TURN)

func execute_enemy_turns():
	for enemy in enemies:
		if enemy.is_alive():
			if _should_skip_enemy_turn(enemy):
				continue

			if enemy is Enemy:
				enemy.execute_turn(self, player)
			else:
				_basic_enemy_behavior(enemy)

			_process_burn(enemy)
			_process_poison(enemy)
			enemy.update_ui()

	if player.stats.hp <= 0:
		if _check_goblin_revert():
			return
		transition_to(State.LOSE)
	else:
		transition_to(State.START_TURN)

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
		print("Enemy scene not found, cannot spawn!")
		return

	var new_enemy = enemy_scene.instantiate()
	var enemies_container = get_tree().root.find_child("Enemies", true, false)
	if enemies_container:
		enemies_container.add_child(new_enemy)
		new_enemy.setup(enemy_resource)
		enemies.append(new_enemy)
		new_enemy.position = Vector2(800 + randf_range(-100, 100), 400 + randf_range(-100, 100))
	else:
		print("Enemies container not found!")

func _handle_start_turn():
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

func _is_target_chilled(card: CardResource, target) -> bool:
	if target:
		if target.stats.chill > 0:
			return true
	elif card.target == CardResource.Target.ALL_ENEMIES:
		for e in enemies:
			if e.is_alive() and e.stats.chill > 0:
				return true
	return false

func _check_goblin_revert() -> bool:
	var is_goblin = RunManager.character_class == CardResource.CharacterClass.GOBLIN_ASSASSIN or \
					RunManager.character_class == CardResource.CharacterClass.GOBLIN_MAGE
	if is_goblin:
		if RunManager.revert_to_core():
			print("Body died! Reverting to core...")
			deck_manager.handle_body_swap(RunManager.deck)
			player.update_ui()
			# If it was player turn, we still go to enemy turn
			# If it was enemy turn, we go back to start turn
			if current_state == State.PLAYER_TURN:
				transition_to(State.ENEMY_TURN)
			else:
				transition_to(State.START_TURN)
			return true
	return false

func _should_skip_enemy_turn(enemy) -> bool:
	# Skip if frozen
	if enemy.stats.frozen > 0:
		enemy.stats.frozen -= 1
		enemy.update_ui()
		print("Enemy frozen, skipping turn!")
		return true

	# Skip if stunned
	if enemy.stats.stunned > 0:
		enemy.stats.stunned -= 1
		enemy.update_ui()
		print("Enemy stunned, skipping turn!")
		return true

	return false

func _basic_enemy_behavior(enemy):
	var damage = 6
	if enemy.stats.strength > 0:
		damage += enemy.stats.strength
	if enemy.stats.weak > 0:
		damage = floor(damage * 0.75)
	player.take_damage(damage)
	enemy.stats.end_turn()

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

func _award_gold():
	var map = RunManager.get_map()
	if RunManager.current_node_index < 0 or RunManager.current_node_index >= map.nodes.size():
		return

	var node = map.nodes[RunManager.current_node_index]
	var amount = 0
	if node.type == MapNode.Type.COMBAT:
		amount = randi_range(10, 20)
	elif node.type == MapNode.Type.ELITE:
		amount = randi_range(30, 50)
	elif node.type == MapNode.Type.BOSS:
		amount = randi_range(80, 120)

	RunManager.gold += amount
	print("Awarded %d Gold!" % amount)
