extends Control

var current_act: MapAct

@onready var node_container = $ScrollContainer/NodeContainer
@onready var act_label = $ActLabel

func _ready():
	current_act = RunManager.get_map()
	display_act()
	$MenuButton.pressed.connect(_on_menu_pressed)

func display_act():
	if not act_label or not node_container:
		return

	act_label.text = "Act %d" % current_act.act_number
	for child in node_container.get_children():
		child.queue_free()

	# Map layout parameters
	var layer_height = 100
	var node_width = 80
	var total_width = node_container.get_parent().size.x

	# Determine max layer for scroll height
	var max_layer = 0
	for node in current_act.nodes:
		max_layer = max(max_layer, node.layer)
	node_container.custom_minimum_size.y = (max_layer + 1) * layer_height + 50

	# Calculate which nodes are reachable
	var reachable_nodes = []
	if RunManager.current_node_index == -1:
		# Just started, all nodes in layer 0 are reachable
		for i in range(current_act.nodes.size()):
			if current_act.nodes[i].layer == 0:
				reachable_nodes.append(i)
	else:
		# Reachable from current node's connections
		reachable_nodes = current_act.nodes[RunManager.current_node_index].connections

	# First pass: create buttons for positioning and basic info
	var buttons = []
	for i in range(current_act.nodes.size()):
		var node = current_act.nodes[i]
		var btn = Button.new()
		btn.text = get_node_name(node.type)
		node_container.add_child(btn)

		# Center node in its slot
		var layer_nodes = []
		for n in current_act.nodes:
			if n.layer == node.layer: layer_nodes.append(n)

		var x_offset = (total_width / (layer_nodes.size() + 1)) * (node.position.x + 1)
		var y_offset = (max_layer - node.layer) * layer_height + 20

		btn.position = Vector2(x_offset - node_width/2, y_offset)
		btn.custom_minimum_size = Vector2(node_width, 40)

		if i in reachable_nodes:
			btn.disabled = false
			btn.pressed.connect(_on_node_selected.bind(i))
		else:
			btn.disabled = true
			if i == RunManager.current_node_index:
				btn.text = "[" + btn.text + "]"
			elif node.layer <= (current_act.nodes[RunManager.current_node_index].layer if RunManager.current_node_index != -1 else -1):
				btn.modulate.a = 0.5 # Visited or skipped
		buttons.append(btn)

	# Drawing connections (simple way using Line2D)
	for i in range(current_act.nodes.size()):
		var node = current_act.nodes[i]
		var from_pos = buttons[i].position + buttons[i].size / 2

		for target_idx in node.connections:
			var target_btn = buttons[target_idx]
			var to_pos = target_btn.position + target_btn.size / 2

			var line = Line2D.new()
			line.points = [from_pos, to_pos]
			line.width = 2
			line.default_color = Color.WHITE
			line.z_index = -1
			node_container.add_child(line)

func get_node_name(type: MapNode.Type) -> String:
	match type:
		MapNode.Type.COMBAT: return "戰鬥"
		MapNode.Type.ELITE: return "精英"
		MapNode.Type.REST: return "休息"
		MapNode.Type.BOSS: return "首領"
		MapNode.Type.EVENT: return "事件"
		_: return "未知"

func _on_node_selected(index: int):
	RunManager.current_node_index = index
	var node = current_act.nodes[index]

	if node.type == MapNode.Type.COMBAT or node.type == MapNode.Type.ELITE:
		get_tree().change_scene_to_file("res://src/combat/CombatRoom.tscn")
	elif node.type == MapNode.Type.BOSS:
		get_tree().change_scene_to_file("res://src/combat/CombatRoom.tscn")
	elif node.type == MapNode.Type.REST:
		var body = RunManager.bodies[RunManager.current_body_index]
		var heal_amount = floor(body.max_hp * 0.3)
		RunManager.player_stats.hp = min(RunManager.player_stats.max_hp, RunManager.player_stats.hp + heal_amount)
		body.hp = RunManager.player_stats.hp
		display_act()
	else:
		# Events not implemented yet, just skip
		display_act()

func _on_menu_pressed():
	var pause_menu = load("res://src/ui/PauseMenu.tscn").instantiate()
	add_child(pause_menu)
