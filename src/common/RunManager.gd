extends Node

# Body system for Goblin Assassin
class Body:
	var name: String
	var max_hp: int
	var hp: int
	var character_class: CardResource.CharacterClass = CardResource.CharacterClass.NEUTRAL
	var supported_categories: int = 1 # GENERAL
	var deck: Array[CardResource] = []
	var enemy_resource: EnemyResource
	var sync_level: int = 0 # 0: Common, 1: Uncommon, 2: Rare

var player_stats: Stats
var deck: Array[CardResource] = []
var gold: int = 0
var character_class: CardResource.CharacterClass = CardResource.CharacterClass.NEUTRAL

var bodies: Array[Body] = []
var current_body_index: int = 0
var fixed_cards: Array[CardResource] = []

var current_act: int = 1
var current_node_index: int = -1 # -1 means just started act
var current_map: MapAct = null
var is_run_active: bool = false

func initialize_run(p_class: CardResource.CharacterClass = CardResource.CharacterClass.NEUTRAL):
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
			core_body.supported_categories = CardResource.Category.GENERAL | CardResource.Category.WEAPON | CardResource.Category.SWORD_SKILL | CardResource.Category.UNIQUE
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
			core_body.supported_categories = CardResource.Category.GENERAL | CardResource.Category.MAGIC | CardResource.Category.UNIQUE
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

	# Identify potential Elites from current pool
	for enemy in normal_enemies:
		if "Adventurer" in enemy.enemy_name or "Bounty" in enemy.enemy_name or "ThiefElder" in enemy.enemy_id:
			elite_enemies.append(enemy)

	if elite_enemies.is_empty():
		# Fallback: use some random normal enemies as elites if none identified
		var tmp = normal_enemies.duplicate()
		tmp.shuffle()
		elite_enemies = tmp.slice(0, min(3, tmp.size()))

	var layers = [] # Array of Arrays of node indices
	var total_layers = 8
	var node_count = 0

	# Create nodes in layers
	for l in range(total_layers):
		var layer_nodes = []
		var num_nodes = randi_range(2, 4)
		if l == total_layers - 1: num_nodes = 1 # Last layer before boss is a rest site

		for i in range(num_nodes):
			var node = MapNode.new()
			node.layer = l
			# Position will be refined in UI, but we store logical grid pos
			node.position = Vector2(i, l)

			if l == 0:
				node.type = MapNode.Type.COMBAT
			elif l == total_layers - 1:
				node.type = MapNode.Type.REST
			elif l < 2:
				node.type = MapNode.Type.COMBAT if randf() < 0.8 else MapNode.Type.EVENT
			else:
				var r = randf()
				if r < 0.6: node.type = MapNode.Type.COMBAT
				elif r < 0.8: node.type = MapNode.Type.ELITE
				elif r < 0.9: node.type = MapNode.Type.REST
				else: node.type = MapNode.Type.EVENT

			current_map.nodes.append(node)
			layer_nodes.append(node_count)
			node_count += 1
		layers.append(layer_nodes)

	# Connect nodes between layers
	for l in range(total_layers - 1):
		var current_layer = layers[l]
		var next_layer = layers[l+1]

		for i in range(current_layer.size()):
			var node_idx = current_layer[i]
			var node = current_map.nodes[node_idx]

			# Every node connects to at least one in the next layer
			var target_idx = i % next_layer.size()
			node.connections.append(next_layer[target_idx])

			# Chance to connect to an adjacent node in next layer
			if next_layer.size() > 1:
				var other_idx = (target_idx + 1) % next_layer.size()
				if randf() > 0.6 and not next_layer[other_idx] in node.connections:
					node.connections.append(next_layer[other_idx])

	# Ensure every node in the next layer (except the first layer) has at least one incoming connection
	for l in range(1, total_layers):
		var current_layer = layers[l]
		var prev_layer = layers[l-1]
		for node_idx in current_layer:
			var has_incoming = false
			for prev_idx in prev_layer:
				if node_idx in current_map.nodes[prev_idx].connections:
					has_incoming = true
					break
			if not has_incoming:
				# Connect a random node from prev layer to this one
				var random_prev = prev_layer[randi() % prev_layer.size()]
				current_map.nodes[random_prev].connections.append(node_idx)

	# Boss node
	var boss_node = MapNode.new()
	boss_node.type = MapNode.Type.BOSS
	boss_node.layer = total_layers
	boss_node.position = Vector2(0, total_layers)
	current_map.nodes.append(boss_node)
	var boss_idx = node_count

	# Connect all nodes in last layer to boss
	for node_idx in layers[total_layers - 1]:
		current_map.nodes[node_idx].connections.append(boss_idx)

	# Assign enemies and ensure uniqueness within the act as much as possible
	var shuffled_normals = normal_enemies.duplicate()
	shuffled_normals.shuffle()
	var normal_idx = 0

	var shuffled_elites = elite_enemies.duplicate()
	shuffled_elites.shuffle()
	var elite_idx = 0

	for node in current_map.nodes:
		if node.type == MapNode.Type.COMBAT:
			if normal_idx < shuffled_normals.size():
				node.data["enemy_resource"] = shuffled_normals[normal_idx]
				normal_idx += 1
			else:
				# Reuse if act is very long, but try to stay unique
				node.data["enemy_resource"] = normal_enemies[randi() % normal_enemies.size()]
		elif node.type == MapNode.Type.ELITE:
			if elite_idx < shuffled_elites.size():
				node.data["enemy_resource"] = shuffled_elites[elite_idx]
				elite_idx += 1
			else:
				node.data["enemy_resource"] = elite_enemies[randi() % elite_enemies.size()]
		elif node.type == MapNode.Type.BOSS:
			if act_num == 4:
				var naraku = load("res://src/entities/resources/boss/NarakuAbyss.tres")
				node.data["enemy_resource"] = naraku if naraku else bosses[0]
			else:
				node.data["enemy_resource"] = bosses[randi() % bosses.size()]

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
	new_body.supported_categories = enemy_res.supported_categories
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

		# Assign rarity based on "power"
		var power_score = action.damage * action.hits + action.block * 2 + action.strength * 5
		if action.stun > 0 or action.attack_lock > 0 or power_score > 20:
			card.rarity = CardResource.Rarity.RARE
		elif action.vulnerable > 0 or action.weak > 0 or action.poison > 0 or action.burn > 0 or power_score > 10:
			card.rarity = CardResource.Rarity.UNCOMMON
		else:
			card.rarity = CardResource.Rarity.COMMON

		enemy_deck.append(card)

	# If no actions, give some default strikes
	if enemy_deck.is_empty():
		var strike = load("res://src/cards/resources/Strike.tres").duplicate()
		strike.character_class = character_class
		strike.card_name = "Strike (Fallback)"
		enemy_deck = [strike, strike, strike]

	new_body.deck = enemy_deck

	if character_class == CardResource.CharacterClass.GOBLIN_MAGE:
		# Mage can only have one body besides core
		if bodies.size() > 1:
			bodies[1] = new_body
		else:
			bodies.append(new_body)
		switch_body(1)
	else:
		# Assassin adds to collection
		bodies.append(new_body)
		switch_body(bodies.size() - 1)

func _is_card_allowed(card: CardResource, body: Body) -> bool:
	# Check sync level for non-starter, non-special cards
	if not card.is_goblin_special and card.rarity != CardResource.Rarity.STARTER:
		if card.rarity == CardResource.Rarity.UNCOMMON and body.sync_level < 1:
			return false
		if card.rarity == CardResource.Rarity.RARE and body.sync_level < 2:
			return false

	# UNIQUE cards must match character class
	if card.categories & CardResource.Category.UNIQUE:
		return card.character_class == body.character_class

	# Otherwise check category intersection
	return (card.categories & body.supported_categories) != 0

func _rebuild_deck():
	if current_body_index < 0 or current_body_index >= bodies.size():
		return

	var body = bodies[current_body_index]

	# Update active deck: filtered fixed cards + body specific deck
	deck.clear()

	for card in fixed_cards:
		if _is_card_allowed(card, body):
			deck.append(card)

	for card in body.deck:
		if _is_card_allowed(card, body):
			deck.append(card)

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
