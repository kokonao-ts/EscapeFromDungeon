extends CardResource

func apply_effects(user: Entity, targets: Array[Entity], combat_manager):
	# Apply standard effects first (damage)
	super.apply_effects(user, targets, combat_manager)

	# Possession mechanic for Goblin Assassin
	if RunManager.character_class == CharacterClass.GOBLIN_ASSASSIN:
		for target in targets:
			if not target.is_alive():
				if target is Enemy and target.enemy_resource:
					print("Possessing %s!" % target.enemy_resource.enemy_name)
					RunManager.possess_enemy(target.enemy_resource)
					# Handle body swap logic: filter hand, discard to draw, shuffle
					combat_manager.deck_manager.handle_body_swap(RunManager.deck)
					# Replenish hand if filtered cards left it small
					if combat_manager.deck_manager.hand.size() < 5:
						combat_manager.deck_manager.draw_cards(5 - combat_manager.deck_manager.hand.size())
					user.update_ui()
					break # Only possess one if multiple targets died
