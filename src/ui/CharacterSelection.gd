extends Control

func _on_ironclad_pressed():
	RunManager.initialize_run(CardResource.CharacterClass.IRONCLAD)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_silent_pressed():
	RunManager.initialize_run(CardResource.CharacterClass.SILENT)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_watcher_pressed():
	RunManager.initialize_run(CardResource.CharacterClass.WATCHER)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_goblin_assassin_pressed():
	RunManager.initialize_run(CardResource.CharacterClass.GOBLIN_ASSASSIN)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_goblin_mage_pressed():
	RunManager.initialize_run(CardResource.CharacterClass.GOBLIN_MAGE)
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")
