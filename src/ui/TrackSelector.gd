extends Control

func _ready() -> void:
	get_tree().paused = false
	
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameUI/Main/ModeSelector.tscn")
