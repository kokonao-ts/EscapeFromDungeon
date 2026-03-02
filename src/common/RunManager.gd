extends Node

enum CharacterClass { IRONCLAD, SILENT, WATCHER }

var player_stats: Stats
var deck: Array[CardResource] = []
var gold: int = 0
var character_class: CharacterClass = CharacterClass.IRONCLAD

var current_act: int = 1
var current_node_index: int = -1 # -1 means just started act
var current_map: MapAct = null
var is_run_active: bool = false

func initialize_run(p_class: CharacterClass = CharacterClass.IRONCLAD):
	is_run_active = true
	character_class = p_class
	player_stats = Stats.new()

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

	# Basic linear act for now: 5 combats and a boss
	for i in range(5):
		var node = MapNode.new()
		node.type = MapNode.Type.COMBAT
		node.position = Vector2(0, i * 100)
		current_map.nodes.append(node)

	var boss = MapNode.new()
	boss.type = MapNode.Type.BOSS
	boss.position = Vector2(0, 500)
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
				if card and (card.character_class == character_class or card.character_class == 3): # 3 is NEUTRAL
					pool.append(card)
			file_name = dir.get_next()
	return pool
