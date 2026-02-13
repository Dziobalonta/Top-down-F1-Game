extends Control

const MODE_SELECTOR = preload("res://scenes/GameUI/Menu/ModeSelector.tscn")


func _ready() -> void:
	get_tree().paused = false
	MusicManager.play_menu_track()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(MODE_SELECTOR)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
