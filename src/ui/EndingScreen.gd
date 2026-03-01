extends Control

func _ready():
	RunManager.is_run_active = false

func _on_return_pressed():
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")
