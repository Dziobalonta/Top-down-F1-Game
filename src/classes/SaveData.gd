extends Resource
class_name SaveData

const SAVE_PATH: String = "user://best_laps.res"

@export var best_laps: Dictionary[String, float]

func get_best_lap(track_name: String) -> float:
	return best_laps.get(track_name, CarRaceData.DEFAULT_LAPTIME)
	
func save_best_lap(track_name: String, lap_time: float) -> void:
	var prev: float = get_best_lap(track_name)
	if lap_time	 < prev:
		best_laps[track_name] = lap_time
		ResourceSaver.save(self,SAVE_PATH)
		
static func load_or_create() -> SaveData:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH)
	var data: SaveData = SaveData.new()
	return data
		
