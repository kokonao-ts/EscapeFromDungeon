extends SceneTree

func _init():
	print("Starting functional verification test...")

	# Ensure RunManager is initialized
	RunManager.initialize_run()

	# Mock objects
	var player_stats = RunManager.player_stats

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

	combat_manager.start_combat(player_mock, [enemy_mock], RunManager.deck)

	print("Initial Enemy HP: ", enemy_stats.hp)
	print("Initial Player HP: ", player_stats.hp)
	print("Initial Player Energy: ", combat_manager.energy)

	# Test playing a strike
	var card_to_play = deck_manager.hand[0]
	print("Playing card: ", card_to_play.card_name)
	combat_manager.play_card(card_to_play, enemy_mock)

	print("Enemy HP after strike: ", enemy_stats.hp)
	assert(enemy_stats.hp == 44)
	print("Energy after strike: ", combat_manager.energy)
	assert(combat_manager.energy == 2)

	# Test end turn
	print("Ending turn...")
	combat_manager.end_player_turn()
	print("Player HP after enemy turn: ", player_stats.hp)
	# Enemy AI in CombatManager attacks for 6
	assert(player_stats.hp == 74)

	# Test combat won signal
	var won_signal_emitted = false
	combat_manager.combat_won.connect(func(): won_signal_emitted = true)

	print("Killing enemy...")
	enemy_stats.hp = 0
	combat_manager.check_enemies_alive()

	print("Combat state: ", combat_manager.current_state)
	assert(combat_manager.current_state == CombatManager.State.WIN)
	assert(won_signal_emitted == true)
	print("Combat won signal verified!")

	print("Verification test passed!")
	quit()
