extends Node

var player_stats: Stats
var deck: Array[CardResource] = []
var gold: int = 0

var current_act: int = 1
var current_node_index: int = -1 # -1 means just started act
var current_map: MapAct = null
var is_run_active: bool = false

func initialize_run():
	is_run_active = true
	player_stats = Stats.new()
	player_stats.max_hp = 80
	player_stats.hp = 80

	gold = 99
	current_act = 1
	current_node_index = -1
	current_map = null

	# Initial deck
	var strike = load("res://src/cards/resources/Strike.tres")
	var defend = load("res://src/cards/resources/Defend.tres")
	deck = [strike, strike, strike, defend, defend]

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
