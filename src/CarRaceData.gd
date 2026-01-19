extends Object
class_name CarRaceData

const  DEFAULT_LAPTIME: float = 999.999

var _car_number: int
var _car_name: String
var _total_time: float = 0.0
var _completed_laps: int
var _partial_progress: float
var _best_lap: float = DEFAULT_LAPTIME
var _target_laps: int = 0

var total_time: float:
	get: return _total_time

var completed_laps: int:
	get: return _completed_laps

var race_completed: bool:
	get: return _completed_laps == _target_laps
	
var total_progress: float:
	get: return _completed_laps + _partial_progress
	
func _init(car_name: String, car_number: int, target_laps: int) -> void:
	_car_name = car_name
	_car_number = car_number
	_target_laps = target_laps
	
func add_lap_time(lap_time: float) -> void:
	_completed_laps += 1
	_best_lap = min(_best_lap, lap_time)
	
func set_total_time(total_time: float) -> void:
	_total_time = total_time
	
func force_finish(total_time: float, progres: float) -> void:
	_partial_progress = progres
	_total_time = total_time
	
func _to_string() -> String:
	var total_str = "DNF"
	if race_completed: 
		total_str = "%0.fs" % (_total_time/ 1000)
	
	var best_lap_str: String = ""
	
	if _best_lap != DEFAULT_LAPTIME: 
		best_lap_str = "%.3fs" % _best_lap
	
	return "%10s %6s %6s %5d" % [
		_car_name, total_str, best_lap_str, _completed_laps
	]
	
static func compare(a: CarRaceData, b: CarRaceData) -> bool:
	if a.completed_laps == b.completed_laps:
		if a.race_completed:
			return a.total_time < b.total_time
		return a.total_progress > b.total_progress
	return a.completed_laps > b.completed_laps
			
