extends Object
class_name CarRaceData

const DEFAULT_LAPTIME: float = 999.999
# Define columns: Rank(4), Name(16), BestLap(12), Laps(8), Time(Remaining)
const ROW_FORMAT = "%-4s %-16s %-12s %-8s %s"

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
	
var car_name: String:
	get: return _car_name
	
var best_lap: float:
	get: return _best_lap
	
func _init(car_name_: String, car_number: int, target_laps: int) -> void:
	_car_name = car_name_
	_car_number = car_number
	_target_laps = target_laps
	
func add_lap_time(lap_time: float) -> void:
	_completed_laps += 1
	_best_lap = min(_best_lap, lap_time)
	
func set_total_time(totaltime: float) -> void:
	_total_time = totaltime
	
func force_finish(totaltime: float, progress: float) -> void:
	_partial_progress = progress
	_total_time = totaltime

static func get_header_string() -> String:
	# NEW (Fixed): Add "Time" at the end
	return ROW_FORMAT % ["Pos", "Driver", "Best Lap", "Laps", "Gap"]

func get_formatted_row(rank: int) -> String:
	var rank_str = str(rank) + "."
	
	var best_str = "--"
	if _best_lap != DEFAULT_LAPTIME:
		best_str = "%.3fs" % _best_lap
		
	var time_str = "DNF"
	# Show time if race completed OR if forced finish time exists (> 0)
	if race_completed or _total_time > 0:
		time_str = "%.3fs" % (_total_time / 1000.0)
	
	return ROW_FORMAT % [
		rank_str,
		_car_name,
		best_str,
		str(_completed_laps),
		time_str
	]
	
func _to_string() -> String:
	return get_formatted_row(0) # Fallback

static func compare(a: CarRaceData, b: CarRaceData) -> bool:
	if a.completed_laps == b.completed_laps:
		if a.race_completed:
			return a.total_time < b.total_time
		return a.total_progress > b.total_progress
	return a.completed_laps > b.completed_laps
