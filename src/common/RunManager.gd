extends Node

enum CharacterClass { IRONCLAD, SILENT, WATCHER, NEUTRAL, GOBLIN_ASSASSIN, GOBLIN_MAGE, GOBLIN_SHARED }

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
			deck.assign([strike, strike, strike, strike, strike, defend, defend, defend, defend, bash])
		CharacterClass.SILENT:
			player_stats.max_hp = 70
			var strike = load("res://src/cards/resources/SilentStrike.tres")
			var defend = load("res://src/cards/resources/SilentDefend.tres")
			var special = load("res://src/cards/resources/SilentSpecial.tres")
			deck.assign([strike, strike, strike, strike, strike, defend, defend, defend, defend, defend, special])
		CharacterClass.WATCHER:
			player_stats.max_hp = 72
			var strike = load("res://src/cards/resources/WatcherStrike.tres")
			var defend = load("res://src/cards/resources/WatcherDefend.tres")
			var special = load("res://src/cards/resources/WatcherSpecial.tres")
			deck.assign([strike, strike, strike, strike, defend, defend, defend, defend, special])
		CharacterClass.GOBLIN_ASSASSIN:
			player_stats.max_hp = 50
			var execute_knife = load("res://src/cards/resources/ExecuteKnife.tres")
			var goblin_strike = load("res://src/cards/resources/GoblinStrike.tres")
			var goblin_rally = load("res://src/cards/resources/GoblinRally.tres")
			var strike = load("res://src/cards/resources/Strike.tres")
			var defend = load("res://src/cards/resources/Defend.tres")

			fixed_cards.assign([execute_knife])
			# One Execute Knife from fixed_cards, 14 from start_deck = 15 total
			var start_deck: Array[CardResource] = [
				goblin_strike, goblin_strike, goblin_strike, goblin_strike,
				goblin_rally, goblin_rally, goblin_rally, goblin_rally,
				strike, strike, strike,
				defend, defend, defend
			]
			deck.assign(start_deck)

			var core_body = Body.new()
			core_body.name = "哥布林刺客"
			core_body.max_hp = 50
			core_body.hp = 50
			core_body.deck.assign(start_deck)
			bodies.append(core_body)
		CharacterClass.GOBLIN_MAGE:
			player_stats.max_hp = 40
			var body_swap = load("res://src/cards/resources/BodySwap.tres")
			var fireball = load("res://src/cards/resources/Fireball.tres")
			var frostbolt = load("res://src/cards/resources/Frostbolt.tres")
			var mana_barrier = load("res://src/cards/resources/ManaBarrier.tres")
			var goblin_strike = load("res://src/cards/resources/GoblinStrike.tres")
			var goblin_rally = load("res://src/cards/resources/GoblinRally.tres")

			fixed_cards.assign([body_swap])
			# One Body Swap from fixed_cards, 14 from start_deck = 15 total
			var start_deck: Array[CardResource] = [
				fireball, fireball, fireball,
				frostbolt, frostbolt, frostbolt,
				mana_barrier, mana_barrier, mana_barrier,
				goblin_strike, goblin_strike,
				goblin_rally, goblin_rally, goblin_rally
			]
			deck.assign(start_deck)

			var core_body = Body.new()
			core_body.name = "哥布林法師"
			core_body.max_hp = 40
			core_body.hp = 40
			core_body.deck.assign(start_deck)
			bodies.append(core_body)

	# Build initial deck using switch_body logic
	switch_body(0)
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

	var pool_path = "res://src/entities/resources/act%d/" % act_num
	var boss_path = "res://src/entities/resources/boss/"

	var normal_enemies = []
	var bosses = []

	# Try to load from new structure, fallback to old if not found
	var dir = DirAccess.open(pool_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				normal_enemies.append(load(pool_path + file_name))
			file_name = dir.get_next()

	dir = DirAccess.open(boss_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				bosses.append(load(boss_path + file_name))
			file_name = dir.get_next()

	# Fallback to defaults if pools are empty
	if normal_enemies.is_empty():
		normal_enemies = [
			load("res://src/entities/resources/JawWorm.tres"),
			load("res://src/entities/resources/Cultist.tres"),
			load("res://src/entities/resources/SmallSlime.tres")
		]
	if bosses.is_empty():
		bosses = [normal_enemies[0]]

	# Basic linear act for now: 5 combats and a boss
	for i in range(5):
		var node = MapNode.new()
		node.type = MapNode.Type.COMBAT
		node.position = Vector2(0, i * 100)

		# For Act 3, maybe have multiple enemies?
		if act_num == 3 and randf() > 0.5:
			var ens = []
			ens.append(normal_enemies[randi() % normal_enemies.size()])
			ens.append(normal_enemies[randi() % normal_enemies.size()])
			node.data["enemies"] = ens
		else:
			node.data["enemy_resource"] = normal_enemies[randi() % normal_enemies.size()]

		current_map.nodes.append(node)

	var boss = MapNode.new()
	boss.type = MapNode.Type.BOSS
	boss.position = Vector2(0, 500)

	# If final act (3 or hidden 4), use specific bosses
	if act_num == 4:
		var naraku = load("res://src/entities/resources/boss/NarakuAbyss.tres")
		boss.data["enemy_resource"] = naraku if naraku else bosses[0]
	else:
		boss.data["enemy_resource"] = bosses[randi() % bosses.size()]

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
				if card:
					# Filter out STARTER cards
					if card.rarity == CardResource.Rarity.STARTER:
						file_name = dir.get_next()
						continue

					# 3 is NEUTRAL, 6 is GOBLIN_SHARED
					var is_goblin = character_class == CharacterClass.GOBLIN_ASSASSIN or character_class == CharacterClass.GOBLIN_MAGE
					if card.character_class == character_class or card.character_class == 3:
						pool.append(card)
					elif is_goblin and card.character_class == 6:
						pool.append(card)
			file_name = dir.get_next()
	return pool

func get_card_pool_by_rarity(rarity: CardResource.Rarity) -> Array[CardResource]:
	var pool = get_card_pool()
	var filtered: Array[CardResource] = []
	for card in pool:
		if card.rarity == rarity:
			filtered.append(card)
	return filtered

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
		card.cost = action.cost
		card.hits = action.hits
		card.character_class = character_class
		card.icon = "card_placeholder.png"
		enemy_deck.append(card)

	# If no actions, give some default strikes
	if enemy_deck.is_empty():
		var strike = load("res://src/cards/resources/Strike.tres").duplicate()
		strike.character_class = character_class
		strike.card_name = "Strike (Fallback)"
		enemy_deck = [strike, strike, strike]

	new_body.deck = enemy_deck
	bodies.append(new_body)

	# Automatically switch to the new body
	switch_body(bodies.size() - 1)

func switch_body(index: int):
	if index < 0 or index >= bodies.size():
		return

	# Save current HP if we are in a run and current index is still valid
	if is_run_active and current_body_index >= 0 and current_body_index < bodies.size():
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
	# Set to invalid index so switch_body doesn't try to save HP to the shifted array
	current_body_index = -1
	switch_body(0)
	return true
