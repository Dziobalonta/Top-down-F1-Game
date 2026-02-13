extends Control

const MODE_SELECTOR_S = preload("res://scenes/GameUI/Menu/TrackSelector_S.tscn")
const MODE_SELECTOR_GP = preload("res://scenes/GameUI/Menu/TrackSelector_GP.tscn")
const MAIN = preload("res://scenes/GameUI/Menu/Main.tscn")


func _ready() -> void:
	get_tree().paused = false


func _on_sprint_button_pressed() -> void:
	get_tree().change_scene_to_packed(MODE_SELECTOR_S)


func _on_gp_button_pressed() -> void:
	get_tree().change_scene_to_packed(MODE_SELECTOR_GP)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameUI/Menu/Main.tscn")
