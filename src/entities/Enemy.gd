extends Entity
class_name Enemy

@export var enemy_resource: EnemyResource
var current_action: EnemyAction
var next_action_index: int = -1

func setup(resource: EnemyResource):
	enemy_resource = resource
	stats = Stats.new()
	stats.max_hp = resource.max_hp
	stats.hp = resource.max_hp
	select_intent()
	update_ui()

func select_intent():
	if not enemy_resource: return

	# Simple rotation or random based on weights for now
	if enemy_resource.action_weights.size() > 0:
		var total_weight = 0.0
		for w in enemy_resource.action_weights:
			total_weight += w

		var r = randf() * total_weight
		var current_sum = 0.0
		for i in range(enemy_resource.action_weights.size()):
			current_sum += enemy_resource.action_weights[i]
			if r <= current_sum:
				next_action_index = i
				break
	else:
		# Sequential
		next_action_index = (next_action_index + 1) % enemy_resource.actions.size()

	current_action = enemy_resource.actions[next_action_index]
	update_ui()

func execute_turn(combat_manager, player):
	if not current_action: return

	# Apply damage
	if current_action.damage > 0:
		var damage = current_action.damage
		if stats.strength > 0:
			damage += stats.strength
		if stats.weak > 0:
			damage = floor(damage * 0.75)
		player.take_damage(damage)

	# Apply block
	if current_action.block > 0:
		add_block(current_action.block)

	# Apply buffs
	if current_action.strength > 0:
		stats.strength += current_action.strength

	# Apply debuffs to player
	if current_action.vulnerable > 0 or current_action.weak > 0:
		player.stats.vulnerable += current_action.vulnerable
		player.stats.weak += current_action.weak
		player.update_ui()

	stats.end_turn()
	update_ui()
	select_intent() # Select next intent after turn
