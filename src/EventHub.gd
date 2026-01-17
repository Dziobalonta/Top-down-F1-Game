extends Node

signal on_lap_completed(info: LapCompleteData)

func emit_on_lap_completed(info: LapCompleteData) -> void:
	on_lap_completed.emit(info)
