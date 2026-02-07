extends Node

const MAIN = preload("res://scenes/GameUI/Menu/Main.tscn")

var data: SaveData
var current_track_name: String = ""

func _enter_tree() -> void:
	data = SaveData.load_or_create()
	
func save_best_lap(new_time: float):
	data.save_best_lap(current_track_name, new_time)
	
func get_best_lap(track_name: String) -> float:
	return data.get_best_lap(track_name)

func change_to_main() -> void:
	get_tree().change_scene_to_packed(MAIN)
	
func change_to_track(info: TrackInfo) -> void:
	current_track_name = info.track_name
	get_tree().change_scene_to_packed(info.track_scene)
