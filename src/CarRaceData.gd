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
	
