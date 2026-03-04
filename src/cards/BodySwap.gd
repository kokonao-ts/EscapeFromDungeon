extends CardResource

func apply_effects(user: Entity, targets: Array[Entity], combat_manager):
	# Apply standard effects first
	super.apply_effects(user, targets, combat_manager)

	# Body Swap mechanic for Goblin Mage
	if RunManager.character_class == CharacterClass.GOBLIN_MAGE:
		var hp_threshold = user.stats.max_hp * 0.25
		if user.stats.hp <= hp_threshold:
			for target in targets:
				if target is Enemy and target.enemy_resource:
					print("Body Swapping with %s!" % target.enemy_resource.enemy_name)
					# Kill the target
					target.take_damage(9999)
					# Possess the body
					RunManager.possess_enemy(target.enemy_resource)
					# Handle body swap logic: filter hand, discard to draw, shuffle
					combat_manager.deck_manager.handle_body_swap(RunManager.deck)
					# Replenish hand
					if combat_manager.deck_manager.hand.size() < 5:
						combat_manager.deck_manager.draw_cards(5 - combat_manager.deck_manager.hand.size())
					user.update_ui()
					break
		else:
			print("HP too high for Body Swap!")
