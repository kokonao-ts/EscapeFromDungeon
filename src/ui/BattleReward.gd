extends Control

signal card_selected(card: CardResource)

@onready var card_container = $VBoxContainer/CardContainer
var card_ui_scene = preload("res://src/ui/CardUI.tscn")

func _ready():
	generate_rewards()

func generate_rewards():
	var map = RunManager.get_map()
	var current_node = map.nodes[RunManager.current_node_index]
	var choices: Array[CardResource] = []

	# 1. First card from the monster's body (enemy deck)
	var enemy_deck: Array[CardResource] = []
	var enemy_res = current_node.data.get("enemy_resource")
	var enemy_resources = current_node.data.get("enemies")

	if enemy_res:
		enemy_deck.assign(_get_enemy_cards(enemy_res))
	elif enemy_resources:
		# Use cards from the first enemy in the group
		enemy_deck.assign(_get_enemy_cards(enemy_resources[0]))

	if not enemy_deck.is_empty():
		enemy_deck.shuffle()
		choices.append(enemy_deck[0])

	# 2. Remaining 2 cards based on rarity probabilities
	var remaining_count = 3 - choices.size()
	var is_elite = current_node.type == MapNode.Type.ELITE or current_node.type == MapNode.Type.BOSS

	for i in range(remaining_count):
		var card = _get_random_card_by_rarity(is_elite)
		if card:
			choices.append(card)

	# Setup UI
	for card in choices:
		var card_ui = card_ui_scene.instantiate()
		card_container.add_child(card_ui)
		card_ui.setup(card)
		card_ui.card_played.connect(_on_card_selected.bind(card))

func _get_enemy_cards(enemy_res: EnemyResource) -> Array[CardResource]:
	var cards: Array[CardResource] = []
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
		card.character_class = RunManager.character_class
		card.icon = "card_placeholder.png"
		cards.append(card)
	return cards

func _get_random_card_by_rarity(must_be_rare: bool) -> CardResource:
	if must_be_rare:
		var rare_pool = RunManager.get_card_pool_by_rarity(CardResource.Rarity.RARE)
		if not rare_pool.is_empty():
			rare_pool.shuffle()
			return rare_pool[0]
		# Fallback to uncommon if no rare cards found
		must_be_rare = false

	# Normal probability logic
	var r = randf()
	var target_rarity = CardResource.Rarity.COMMON

	# Probabilities: 3% Rare, 37% Uncommon, 60% Common (simplified)
	# Elite/Boss usually have higher probabilities, but prompt says elite/boss get 100% gold (Rare)
	if r < 0.03:
		target_rarity = CardResource.Rarity.RARE
	elif r < 0.40:
		target_rarity = CardResource.Rarity.UNCOMMON

	var pool = RunManager.get_card_pool_by_rarity(target_rarity)
	if pool.is_empty():
		# Fallback to common if target pool is empty
		pool = RunManager.get_card_pool_by_rarity(CardResource.Rarity.COMMON)

	if not pool.is_empty():
		pool.shuffle()
		return pool[0]

	return null

func _on_card_selected(card_ui, card: CardResource):
	card_selected.emit(card)
	queue_free()
