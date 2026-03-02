extends Entity
class_name Enemy

@export var enemy_resource: EnemyResource
var selected_actions: Array[EnemyAction] = []
var next_action_index: int = -1
var split_triggered: bool = false

func setup(resource: EnemyResource):
	enemy_resource = resource
	stats = Stats.new()
	stats.max_hp = resource.max_hp
	stats.hp = resource.max_hp
	select_intent()
	update_ui()

func select_intent():
	if not enemy_resource: return
	selected_actions.clear()

	var energy = enemy_resource.energy_per_turn
	var actions_count = 0
	var max_actions = enemy_resource.max_actions_per_turn if enemy_resource.max_actions_per_turn > 0 else 3

	# Simple rotation or random based on weights for now, using energy system
	# For simplicity, we choose actions until energy or action limit is reached
	var safety_limit = 10
	while energy > 0 and actions_count < max_actions and safety_limit > 0:
		safety_limit -= 1
		var action: EnemyAction = null
		if enemy_resource.action_weights.size() > 0:
			var total_weight = 0.0
			for w in enemy_resource.action_weights:
				total_weight += w

			var r = randf() * total_weight
			var current_sum = 0.0
			for i in range(enemy_resource.action_weights.size()):
				current_sum += enemy_resource.action_weights[i]
				if r <= current_sum:
					action = enemy_resource.actions[i]
					break
		else:
			# Sequential
			next_action_index = (next_action_index + 1) % enemy_resource.actions.size()
			action = enemy_resource.actions[next_action_index]

		if action:
			# Only add if we have energy or if it's free
			if action.cost <= energy:
				# Prevent repeated free actions in same turn to avoid spamming
				if action.cost == 0 and selected_actions.has(action):
					break

				selected_actions.append(action)
				energy -= action.cost
				actions_count += 1
			else:
				# Not enough energy for this action, stop choosing
				break
		else:
			break

	update_ui()

func execute_turn(combat_manager, player):
	if selected_actions.is_empty():
		stats.end_turn()
		update_ui()
		select_intent()
		return

	for action in selected_actions:
		# Apply damage
		if action.damage > 0:
			var damage = action.damage
			# Special logic for Assassin: +10 damage if player is vulnerable
			if enemy_resource and enemy_resource.enemy_id == "chaos_assassin" and player.stats.vulnerable > 0:
				damage = 40

			if stats.strength > 0:
				damage += stats.strength
			if stats.weak > 0:
				damage = floor(damage * 0.75)

			for i in range(action.hits):
				player.take_damage(damage)
				# Apply thorns damage back to enemy if player has thorns
				if player.stats.thorns > 0:
					self.take_damage(player.stats.thorns)
				# Apply electrified damage back to enemy if player has electrified
				if player.stats.electrified > 0:
					self.take_damage(player.stats.electrified)

		# Apply block or armor break
		if action.block != 0:
			if action.block > 0:
				add_block(action.block)
			else:
				# Negative block = armor break (removes target block)
				player.stats.block = max(0, player.stats.block + action.block)

		# Apply buffs to self or debuffs to player
		if action.strength != 0:
			if action.type == EnemyAction.Type.DEBUFF:
				# Debuff intended for player (like Intimidate)
				player.stats.strength += action.strength
			else:
				# Buff intended for self
				stats.strength += action.strength

		if action.evasion > 0:
			stats.evasion += action.evasion
		if action.thorns > 0:
			stats.thorns += action.thorns
		if action.electrified > 0:
			stats.electrified += action.electrified
		if action.heal > 0:
			stats.hp = min(stats.max_hp, stats.hp + action.heal)

		# Apply debuffs to player
		if action.vulnerable > 0:
			player.stats.vulnerable += action.vulnerable
		if action.weak > 0:
			player.stats.weak += action.weak
		if action.poison > 0:
			player.stats.poison += action.poison
		if action.burn > 0:
			player.stats.burn += action.burn
		if action.chill > 0:
			combat_manager.apply_chill(player, action.chill)
		if action.slow > 0:
			player.stats.slow += action.slow
		if action.draw_reduction > 0:
			player.stats.draw_reduction += action.draw_reduction
		if action.stun > 0:
			player.stats.stunned += action.stun
		if action.attack_lock > 0:
			player.stats.attack_locked += action.attack_lock

		# Self damage
		if action.self_damage > 0:
			self.take_damage(action.self_damage)

		# Summon/Split
		if action.type == EnemyAction.Type.SUMMON and action.summon_enemy:
			combat_manager.spawn_enemy(action.summon_enemy)
		elif action.type == EnemyAction.Type.SPLIT:
			trigger_split()

		player.update_ui()
		if not is_alive():
			break

	stats.end_turn()
	update_ui()
	select_intent() # Select next intent after turn

func take_damage(amount: int):
	super.take_damage(amount)
	# Check for splitting
	if is_alive() and not split_triggered and enemy_resource and not enemy_resource.split_result.is_empty():
		if float(stats.hp) / stats.max_hp <= enemy_resource.split_hp_threshold:
			split_triggered = true
			trigger_split()

func trigger_split():
	if not enemy_resource or enemy_resource.split_result.is_empty():
		return

	print("%s is splitting!" % enemy_resource.enemy_name)
	var combat_manager = get_tree().root.find_child("CombatManager", true, false)
	if combat_manager:
		for res in enemy_resource.split_result:
			combat_manager.spawn_enemy(res)
		# After splitting, the original usually disappears or changes
		# For simplicity, we kill the original
		self.take_damage(9999)
