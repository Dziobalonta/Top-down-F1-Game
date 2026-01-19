extends Node

signal on_lap_completed(info: LapCompleteData)
signal on_race_start
signal on_lap_update
signal on_race_over(data: Array[CarRaceData])

func emit_on_lap_completed(info: LapCompleteData) -> void:
	on_lap_completed.emit(info)
	
func emit_on_race_start() -> void:
	on_race_start.emit()

func emit_on_lap_update(car: Car, lap_count: int, total_laps: int, lap_time: float) -> void:
	on_lap_update.emit(car, lap_count, total_laps, lap_time)
	
func emit_on_race_over(data: Array[CarRaceData]) -> void:
	on_race_over.emit(data)
