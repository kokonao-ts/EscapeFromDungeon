extends SceneTree

func _init():
	print("Starting advanced functional verification test...")

	# Ensure RunManager is initialized
	RunManager.initialize_run()

	# Mock objects
	var player_stats = Stats.new()
	player_stats.max_hp = 80
	player_stats.hp = 80

	var enemy_stats = Stats.new()
	enemy_stats.hp = 50
	enemy_stats.max_hp = 50

	var player_mock = {
		"stats": player_stats,
		"add_block": func(amt): player_stats.add_block(amt),
		"take_damage": func(amt): player_stats.take_damage(amt),
		"update_ui": func(): pass
	}

	var enemy_mock = {
		"stats": enemy_stats,
		"take_damage": func(amt): enemy_stats.take_damage(amt),
		"is_alive": func(): return enemy_stats.hp > 0,
		"update_ui": func(): pass
	}

	var combat_manager = CombatManager.new()
	var deck_manager = DeckManager.new()
	combat_manager.add_child(deck_manager)
	combat_manager.deck_manager = deck_manager

	# Test 1: Vulnerable logic
	print("--- Test 1: Vulnerable ---")
	enemy_stats.vulnerable = 2
	player_stats.strength = 0
	player_stats.weak = 0

	var strike = load("res://src/cards/resources/Strike.tres")
	combat_manager.player = player_mock
	combat_manager.enemies = [enemy_mock]
	combat_manager.energy = 3

	print("Initial Enemy HP: ", enemy_stats.hp)
	combat_manager.play_card(strike, enemy_mock)
	# Strike deals 6. Vulnerable increases by 50% -> 9.
	print("Enemy HP after strike on vulnerable target: ", enemy_stats.hp)
	assert(enemy_stats.hp == 41)

	# Test 2: Strength and Multi-hit
	print("--- Test 2: Strength and Multi-hit ---")
	player_stats.strength = 2
	var twin_strike = load("res://src/cards/resources/TwinStrike.tres")
	combat_manager.energy = 3
	var start_hp = enemy_stats.hp
	combat_manager.play_card(twin_strike, enemy_mock)
	# Twin Strike deals 5x2. With +2 Strength, it's (5+2)x2 = 14.
	print("Enemy HP after Twin Strike with +2 Strength: ", enemy_stats.hp)
	assert(enemy_stats.hp == start_hp - 14)

	# Test 3: Weak
	print("--- Test 3: Weak ---")
	player_stats.weak = 1
	player_stats.strength = 0
	combat_manager.energy = 3
	start_hp = enemy_stats.hp
	# Reset vulnerable for clean test
	enemy_stats.vulnerable = 0
	combat_manager.play_card(strike, enemy_mock)
	# Strike deals 6. Weak reduces by 25% -> 4.5, floored to 4.
	print("Enemy HP after strike while player is weak: ", enemy_stats.hp)
	assert(enemy_stats.hp == start_hp - 4)

	# Test 4: Self Damage and Exhaust
	print("--- Test 4: Self Damage and Exhaust ---")
	var offering = load("res://src/cards/resources/Offering.tres")
	deck_manager.hand = [offering]
	combat_manager.energy = 3
	var start_player_hp = player_stats.hp
	combat_manager.play_card(offering, player_mock)
	print("Player HP after Offering (self damage 6): ", player_stats.hp)
	assert(player_stats.hp == start_player_hp - 6)
	assert(deck_manager.exhaust_pile.has(offering))
	print("Offering successfully exhausted.")

	print("All verification tests passed!")
	quit()
