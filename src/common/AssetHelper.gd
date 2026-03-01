extends Node
class_name AssetHelper

const REAL_PATH = "res://assets/real/"
const PLACEHOLDER_PATH = "res://icon.svg"

static func get_texture(file_name: String) -> Texture2D:
	var full_path = REAL_PATH + file_name
	if FileAccess.file_exists(full_path):
		return load(full_path) as Texture2D

	# Fallback to a placeholder.
	# In a real scenario, we might have specific placeholders for cards vs entities.
	return load(PLACEHOLDER_PATH) as Texture2D
