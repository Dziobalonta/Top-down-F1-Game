extends Node

const MAIN = preload("res://scenes/GameUI/Main/Main.tscn")

func change_to_main() -> void:
	get_tree().change_scene_to_packed(MAIN)
	
func change_to_track(info: TrackInfo) -> void:
	get_tree().change_scene_to_packed(info.track_scene)
