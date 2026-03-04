extends Node

# Body system for Goblin Assassin
class Body:
	var name: String
	var max_hp: int
	var hp: int
	var character_class: CardResource.CharacterClass = CardResource.CharacterClass.NEUTRAL
	var deck: Array[CardResource] = []
	var enemy_resource: EnemyResource

var player_stats: Stats
var deck: Array[CardResource] = []
var gold: int = 0
var character_class: CardResource.CharacterClass = CardResource.CharacterClass.IRONCLAD

var bodies: Array[Body] = []
var current_body_index: int = 0
var fixed_cards: Array[CardResource] = []

var current_act: int = 1
var current_node_index: int = -1 # -1 means just started act
var current_map: MapAct = null
var is_run_active: bool = false

func initialize_run(p_class: CardResource.CharacterClass = CardResource.CharacterClass.IRONCLAD):
	is_run_active = true
	character_class = p_class
	player_stats = Stats.new()

	bodies.clear()
	fixed_cards.clear()
	current_body_index = 0

	var strike_res = "res://src/cards/resources/Strike.tres"
	var defend_res = "res://src/cards/resources/Defend.tres"
	var goblin_strike_res = "res://src/cards/resources/GoblinStrike.tres"
	var goblin_rally_res = "res://src/cards/resources/GoblinRally.tres"

	match character_class:
		CardResource.CharacterClass.IRONCLAD:
			player_stats.max_hp = 80
			var strike = load(strike_res)
			var defend = load(defend_res)
			var bash = load("res://src/cards/resources/Bash.tres")
			var start_deck: Array[CardResource] = [
				strike, strike, strike, strike, strike,
				defend, defend, defend, defend, bash
			]

			var core_body = Body.new()
			core_body.name = "鐵衛士"
			core_body.character_class = CardResource.CharacterClass.IRONCLAD
			core_body.max_hp = 80
			core_body.hp = 80
			core_body.deck.assign(start_deck)
			bodies.append(core_body)
		CardResource.CharacterClass.SILENT:
			player_stats.max_hp = 70
			var strike = load("res://src/cards/resources/SilentStrike.tres")
			var defend = load("res://src/cards/resources/SilentDefend.tres")
			var special = load("res://src/cards/resources/SilentSpecial.tres")
			var survivor = load("res://src/cards/resources/SilentSurvivor.tres")
			var start_deck: Array[CardResource] = [
				strike, strike, strike, strike, strike,
				defend, defend, defend, defend, defend, special, survivor
			]

			var core_body = Body.new()
			core_body.name = "寂靜者"
			core_body.character_class = CardResource.CharacterClass.SILENT
			core_body.max_hp = 70
			core_body.hp = 70
			core_body.deck.assign(start_deck)
			bodies.append(core_body)
		CardResource.CharacterClass.WATCHER:
			player_stats.max_hp = 72
			var strike = load("res://src/cards/resources/WatcherStrike.tres")
			var defend = load("res://src/cards/resources/WatcherDefend.tres")
			var special = load("res://src/cards/resources/WatcherSpecial.tres")
			var vigilance = load("res://src/cards/resources/WatcherVigilance.tres")
			var start_deck: Array[CardResource] = [
				strike, strike, strike, strike,
				defend, defend, defend, defend, special, vigilance
			]

			var core_body = Body.new()
			core_body.name = "觀者"
			core_body.character_class = CardResource.CharacterClass.WATCHER
			core_body.max_hp = 72
			core_body.hp = 72
			core_body.deck.assign(start_deck)
			bodies.append(core_body)
		CardResource.CharacterClass.GOBLIN_ASSASSIN:
			player_stats.max_hp = 50
			var execute_knife = load("res://src/cards/resources/ExecuteKnife.tres").duplicate()
			var goblin_strike = load(goblin_strike_res).duplicate()
			var goblin_rally = load(goblin_rally_res).duplicate()
			var strike = load(strike_res)
			var defend = load(defend_res)

			# Mark special cards
			execute_knife.is_goblin_special = true
			goblin_strike.is_goblin_special = true
			goblin_rally.is_goblin_special = true

			fixed_cards.assign([execute_knife,
				goblin_strike, goblin_strike, goblin_strike, goblin_strike,
				goblin_rally, goblin_rally, goblin_rally, goblin_rally
			])

			var body_deck: Array[CardResource] = [
				strike, strike, strike,
				defend, defend, defend
			]

			var core_body = Body.new()
			core_body.name = "哥布林刺客"
			core_body.character_class = CardResource.CharacterClass.GOBLIN_ASSASSIN
			core_body.max_hp = 50
			core_body.hp = 50
			core_body.deck.assign(body_deck)
			bodies.append(core_body)
		CardResource.CharacterClass.GOBLIN_MAGE:
			player_stats.max_hp = 40
			var body_swap = load("res://src/cards/resources/BodySwap.tres").duplicate()
			var fireball = load("res://src/cards/resources/Fireball.tres")
			var frostbolt = load("res://src/cards/resources/Frostbolt.tres")
			var mana_barrier = load("res://src/cards/resources/ManaBarrier.tres")
			var goblin_strike = load(goblin_strike_res).duplicate()
			var goblin_rally = load(goblin_rally_res).duplicate()

			# Mark special cards
			body_swap.is_goblin_special = true
			goblin_strike.is_goblin_special = true
			goblin_rally.is_goblin_special = true

			fixed_cards.assign([body_swap,
				goblin_strike, goblin_strike,
				goblin_rally, goblin_rally, goblin_rally
			])

			var body_deck: Array[CardResource] = [
				fireball, fireball, fireball,
				frostbolt, frostbolt, frostbolt,
				mana_barrier, mana_barrier, mana_barrier
			]

			var core_body = Body.new()
			core_body.name = "哥布林法師"
			core_body.character_class = CardResource.CharacterClass.GOBLIN_MAGE
			core_body.max_hp = 40
			core_body.hp = 40
			core_body.deck.assign(body_deck)
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
	var elite_enemies = []
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

	# Diversified sequence: Combat, Combat, Elite, Combat, Rest Site (with randomization)
	var node_types = [
		MapNode.Type.COMBAT,
		MapNode.Type.COMBAT,
		MapNode.Type.ELITE,
		MapNode.Type.COMBAT,
		MapNode.Type.REST
	]

	# Keep the first combat fixed, and the last rest site fixed
	# Shuffle the middle three nodes (indices 1, 2, 3)
	var middle = [node_types[1], node_types[2], node_types[3]]
	middle.shuffle()
	node_types[1] = middle[0]
	node_types[2] = middle[1]
	node_types[3] = middle[2]

	# Identify potential Elites from current pool (or hardcode for now)
	# In a real project, we'd have an 'elite/' folder.
	for enemy in normal_enemies:
		if "Adventurer" in enemy.enemy_name or "Bounty" in enemy.enemy_name or "ThiefElder" in enemy.enemy_id:
			elite_enemies.append(enemy)

	if elite_enemies.is_empty():
		elite_enemies = [normal_enemies[randi() % normal_enemies.size()]]

	for i in range(5):
		var node = MapNode.new()
		node.type = node_types[i]
		node.position = Vector2(0, i * 100)

		if node.type == MapNode.Type.COMBAT:
			# For Act 3, maybe have multiple enemies?
			if act_num == 3 and randf() > 0.5:
				var ens = []
				ens.append(normal_enemies[randi() % normal_enemies.size()])
				ens.append(normal_enemies[randi() % normal_enemies.size()])
				node.data["enemies"] = ens
			else:
				node.data["enemy_resource"] = normal_enemies[randi() % normal_enemies.size()]
		elif node.type == MapNode.Type.ELITE:
			node.data["enemy_resource"] = elite_enemies[randi() % elite_enemies.size()]

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

					# Filter by class
					var is_goblin = character_class == CardResource.CharacterClass.GOBLIN_ASSASSIN or \
									character_class == CardResource.CharacterClass.GOBLIN_MAGE

					var is_neutral = card.character_class == CardResource.CharacterClass.NEUTRAL
					var is_matching = card.character_class == character_class
					var is_goblin_shared = card.character_class == CardResource.CharacterClass.GOBLIN_SHARED

					if is_matching or is_neutral:
						pool.append(card)
					elif is_goblin and is_goblin_shared:
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
	new_body.character_class = enemy_res.character_class
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

func _rebuild_deck():
	if current_body_index < 0 or current_body_index >= bodies.size():
		return

	var body = bodies[current_body_index]

	# Update active deck: filtered fixed cards + body specific deck
	deck.clear()

	for card in fixed_cards:
		# Always keep goblin special cards
		if card.is_goblin_special:
			deck.append(card)
			continue

		# Keep non-technique fixed cards
		if not card.is_technique:
			deck.append(card)
			continue

		# Filter techniques by body class
		var is_goblin_body = body.character_class == CardResource.CharacterClass.GOBLIN_ASSASSIN or \
							body.character_class == CardResource.CharacterClass.GOBLIN_MAGE

		var is_neutral = card.character_class == CardResource.CharacterClass.NEUTRAL
		var is_matching = card.character_class == body.character_class
		var is_goblin_shared = card.character_class == CardResource.CharacterClass.GOBLIN_SHARED

		if is_matching or is_neutral:
			deck.append(card)
		elif is_goblin_body and is_goblin_shared:
			deck.append(card)

	for c in body.deck:
		deck.append(c)

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

	_rebuild_deck()

func add_card_to_run(card: CardResource):
	if card.is_technique or card.is_goblin_special:
		fixed_cards.append(card)
	else:
		if current_body_index >= 0 and current_body_index < bodies.size():
			bodies[current_body_index].deck.append(card)

	_rebuild_deck()

func revert_to_core():
	if current_body_index == 0:
		# Core died, game over
		return false

	# Current body is dead
	bodies.remove_at(current_body_index)
	# Set to invalid index so switch_body doesn't try to save HP
	current_body_index = -1
	switch_body(0)
	return true
