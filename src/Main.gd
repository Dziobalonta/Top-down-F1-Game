extends Control

const MODE_SELECTOR = preload("res://scenes/GameUI/Main/ModeSelector.tscn")


func _ready() -> void:
	get_tree().paused = false


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(MODE_SELECTOR)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
