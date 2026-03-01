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

	for i in range(current_act.nodes.size()):
		var node = current_act.nodes[i]
		var btn = Button.new()
		btn.text = get_node_name(node.type)
		node_container.add_child(btn)

		# Only allow clicking the next node
		if i == RunManager.current_node_index + 1:
			btn.disabled = false
			btn.pressed.connect(_on_node_selected.bind(i))
		else:
			btn.disabled = true
			if i <= RunManager.current_node_index:
				btn.text += " (Visited)"

func get_node_name(type: MapNode.Type) -> String:
	match type:
		MapNode.Type.COMBAT: return "Combat"
		MapNode.Type.BOSS: return "Boss"
		_: return "Unknown"

func _on_node_selected(index: int):
	RunManager.current_node_index = index
	var node = current_act.nodes[index]

	if node.type == MapNode.Type.COMBAT:
		get_tree().change_scene_to_file("res://src/combat/CombatRoom.tscn")
	elif node.type == MapNode.Type.BOSS:
		# After winning a boss battle, move to next act
		get_tree().change_scene_to_file("res://src/combat/CombatRoom.tscn")
	else:
		# Just refresh if it's some other type not implemented yet
		display_act()

func _on_menu_pressed():
	var pause_menu = load("res://src/ui/PauseMenu.tscn").instantiate()
	add_child(pause_menu)
