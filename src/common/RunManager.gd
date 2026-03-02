extends Node

enum CharacterClass { IRONCLAD, SILENT, WATCHER, NEUTRAL, GOBLIN_ASSASSIN }

var player_stats: Stats
var deck: Array[CardResource] = []
var gold: int = 0
var character_class: CharacterClass = CharacterClass.IRONCLAD

# Body system for Goblin Assassin
class Body:
	var name: String
	var max_hp: int
	var hp: int
	var deck: Array[CardResource] = []
	var enemy_resource: EnemyResource

var bodies: Array[Body] = []
var current_body_index: int = 0
var fixed_cards: Array[CardResource] = []

var current_act: int = 1
var current_node_index: int = -1 # -1 means just started act
var current_map: MapAct = null
var is_run_active: bool = false

func initialize_run(p_class: CharacterClass = CharacterClass.IRONCLAD):
	is_run_active = true
	character_class = p_class
	player_stats = Stats.new()

	bodies.clear()
	fixed_cards.clear()
	current_body_index = 0

	match character_class:
		CharacterClass.IRONCLAD:
			player_stats.max_hp = 80
			var strike = load("res://src/cards/resources/Strike.tres")
			var defend = load("res://src/cards/resources/Defend.tres")
			var bash = load("res://src/cards/resources/Bash.tres")
			deck = [strike, strike, strike, strike, strike, defend, defend, defend, defend, bash]
		CharacterClass.SILENT:
			player_stats.max_hp = 70
			var strike = load("res://src/cards/resources/SilentStrike.tres")
			var defend = load("res://src/cards/resources/SilentDefend.tres")
			var special = load("res://src/cards/resources/SilentSpecial.tres")
			deck = [strike, strike, strike, strike, strike, defend, defend, defend, defend, defend, special]
		CharacterClass.WATCHER:
			player_stats.max_hp = 72
			var strike = load("res://src/cards/resources/WatcherStrike.tres")
			var defend = load("res://src/cards/resources/WatcherDefend.tres")
			var special = load("res://src/cards/resources/WatcherSpecial.tres")
			deck = [strike, strike, strike, strike, defend, defend, defend, defend, special]
		CharacterClass.GOBLIN_ASSASSIN:
			player_stats.max_hp = 50
			var execute_knife = load("res://src/cards/resources/ExecuteKnife.tres")
			fixed_cards = [execute_knife]
			deck = [execute_knife]

			var core_body = Body.new()
			core_body.name = "哥布林刺客"
			core_body.max_hp = 50
			core_body.hp = 50
			core_body.deck = [execute_knife]
			bodies.append(core_body)

	player_stats.hp = player_stats.max_hp
	gold = 99
	current_act = 1
	current_node_index = -1
	current_map = null

func next_act():
	current_act += 1
	current_node_index = -1
	current_map = null

func get_map() -> MapAct:
	if current_map == null:
		generate_act(current_act)
	return current_map

func generate_act(act_num: int):
	current_map = MapAct.new(act_num)

	var possible_enemies = [
		load("res://src/entities/resources/JawWorm.tres"),
		load("res://src/entities/resources/Cultist.tres"),
		load("res://src/entities/resources/SmallSlime.tres")
	]

	# Basic linear act for now: 5 combats and a boss
	for i in range(5):
		var node = MapNode.new()
		node.type = MapNode.Type.COMBAT
		node.position = Vector2(0, i * 100)
		# Assign a random enemy
		node.data["enemy_resource"] = possible_enemies[randi() % possible_enemies.size()]
		current_map.nodes.append(node)

	var boss = MapNode.new()
	boss.type = MapNode.Type.BOSS
	boss.position = Vector2(0, 500)
	boss.data["enemy_resource"] = possible_enemies[0] # Use Jaw Worm as boss for now
	current_map.nodes.append(boss)

func get_card_pool() -> Array[CardResource]:
	var all_cards_path = "res://src/cards/resources/"
	var pool: Array[CardResource] = []
	var dir = DirAccess.open(all_cards_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card = load(all_cards_path + file_name) as CardResource
				# 3 is NEUTRAL
				if card and (card.character_class == character_class or card.character_class == 3):
					pool.append(card)
			file_name = dir.get_next()
	return pool

func possess_enemy(enemy_res: EnemyResource):
	var new_body = Body.new()
	new_body.name = enemy_res.enemy_name
	new_body.max_hp = enemy_res.max_hp
	new_body.hp = enemy_res.max_hp
	new_body.enemy_resource = enemy_res

	# Generate a deck for the enemy
	var enemy_deck: Array[CardResource] = []
	for action in enemy_res.actions:
		var card = CardResource.new()
		card.card_name = action.description if action.description != "" else "Enemy Move"
		card.damage = action.damage
		card.block = action.block
		card.strength = action.strength
		card.vulnerable = action.vulnerable
		card.weak = action.weak
		card.cost = 1 # Default cost for enemy moves
		card.character_class = CharacterClass.GOBLIN_ASSASSIN
		card.icon = "card_placeholder.png"
		enemy_deck.append(card)

	# If no actions, give some default strikes
	if enemy_deck.is_empty():
		var strike = load("res://src/cards/resources/Strike.tres").duplicate()
		strike.character_class = CharacterClass.GOBLIN_ASSASSIN
		strike.card_name = "Strike (Fallback)"
		enemy_deck = [strike, strike, strike]

	new_body.deck = enemy_deck
	bodies.append(new_body)

	# Automatically switch to the new body
	switch_body(bodies.size() - 1)

func switch_body(index: int):
	if index < 0 or index >= bodies.size():
		return

	# Save current HP if we are in a run
	if is_run_active:
		bodies[current_body_index].hp = player_stats.hp

	current_body_index = index
	var body = bodies[current_body_index]

	player_stats.max_hp = body.max_hp
	player_stats.hp = body.hp

	# Update deck: fixed cards + body specific deck
	deck.clear()
	deck.assign(fixed_cards)
	for c in body.deck:
		deck.append(c)

	# Notify UI if needed, but usually this happens between combats or via special card
	# If it happens DURING combat, we need to tell CombatManager

func revert_to_core():
	if current_body_index == 0:
		# Core died, game over
		return false

	# Current body is dead
	bodies.remove_at(current_body_index)
	switch_body(0)
	return true
