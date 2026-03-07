extends Control

signal choice_made

func _ready():
	var body = RunManager.bodies[RunManager.current_body_index]
	if body.sync_level >= 2:
		%SyncButton.disabled = true
		%SyncButton.text = "同步 (已達最高等級)"

func _on_heal_pressed():
	var body = RunManager.bodies[RunManager.current_body_index]
	var heal_amount = floor(body.max_hp * 0.3)
	RunManager.player_stats.hp = min(RunManager.player_stats.max_hp, RunManager.player_stats.hp + heal_amount)
	body.hp = RunManager.player_stats.hp
	choice_made.emit()
	queue_free()

func _on_sync_pressed():
	var body = RunManager.bodies[RunManager.current_body_index]
	if body.sync_level < 2:
		body.sync_level += 1
		print("Body synchronization improved to Level %d" % body.sync_level)
		RunManager._rebuild_deck() # Update deck with new allowed cards
	choice_made.emit()
	queue_free()
