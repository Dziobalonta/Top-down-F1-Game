extends Node

signal on_lap_completed(info: LapCompleteData)
signal on_race_start

func emit_on_lap_completed(info: LapCompleteData) -> void:
	on_lap_completed.emit(info)
	
func emit_on_race_start() -> void:
	on_race_start.emit()
