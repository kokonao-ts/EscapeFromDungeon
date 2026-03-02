extends Control

func _on_ironclad_pressed():
	RunManager.initialize_run(RunManager.CharacterClass.IRONCLAD)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_silent_pressed():
	RunManager.initialize_run(RunManager.CharacterClass.SILENT)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_watcher_pressed():
	RunManager.initialize_run(RunManager.CharacterClass.WATCHER)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")
