extends Control

@onready var body_container = $Panel/VBoxContainer/ScrollContainer/BodyContainer

func _ready():
	refresh_bodies()

func refresh_bodies():
	for child in body_container.get_children():
		child.queue_free()

	for i in range(RunManager.bodies.size()):
		var body = RunManager.bodies[i]
		var btn = Button.new()
		var status = ""
		if i == RunManager.current_body_index:
			status = " (使用中)"

		btn.text = "%s - HP: %d/%d - 同步: %d%s" % [body.name, body.hp, body.max_hp, body.sync_level, status]
		btn.pressed.connect(_on_body_selected.bind(i))
		body_container.add_child(btn)

func _on_body_selected(index: int):
	RunManager.switch_body(index)
	queue_free()

func _on_close_pressed():
	queue_free()
