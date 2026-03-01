extends Control

func _on_resume_pressed():
	queue_free()

func _on_return_pressed():
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")
