extends Control

const MODE_SELECTOR = preload("res://scenes/GameUI/Main/TrackSelector.tscn")
const MAIN = preload("res://scenes/GameUI/Main/Main.tscn")


func _ready() -> void:
	get_tree().paused = false


func _on_sprint_button_pressed() -> void:
	get_tree().change_scene_to_packed(MODE_SELECTOR)


func _on_gp_button_pressed() -> void:
	get_tree().change_scene_to_packed(MODE_SELECTOR)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameUI/Main/Main.tscn")
