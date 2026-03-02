extends Control

@onready var continue_button = %ContinueButton

func _ready():
	# Only allow "Continue" if a run is already active in RunManager
	continue_button.disabled = not RunManager.is_run_active

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://src/ui/CharacterSelection.tscn")

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://src/map/MapRoom.tscn")

func _on_settings_pressed():
	# Placeholder for settings
	print("Settings pressed")

func _on_playground_pressed():
	get_tree().change_scene_to_file("res://src/playground/Playground.tscn")

func _on_quit_pressed():
	get_tree().quit()
