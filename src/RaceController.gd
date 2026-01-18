extends Node
class_name RaceController

@export var total_laps: int = 5
@onready var race_over_timer: Timer = $RaceOverTimer

var _cars: Array[Car] = []
var _track_curve: Curve2D
var _race_data: Dictionary[Car,CarRaceData] = {}
var _started: bool = false
var _finished: bool = false
var _start_time: float

func setup(cars: Array[Car], track_curve: Curve2D) -> void:
	_cars = cars
	_track_curve = track_curve
	
	for c in cars:
		_race_data[c] = CarRaceData.new(
			c.car_name, c.car_number, total_laps
		)
	print("RaceController init with %d cars" % _cars.size())
	
func _enter_tree() -> void:
	EventHub.on_lap_completed.connect(on_lap_completed)
	EventHub.on_race_start.connect(on_race_start)
	
func on_race_start() -> void:
	if _started: return
	_started = true
	_finished = false
	_start_time = Time.get_ticks_msec()
	
func get_elapsed_time() -> float:
	return Time.get_ticks_msec() - _start_time
	
func on_lap_completed(info: LapCompleteData) -> void:
	print("RaceController on_lap_completed:", info)
	if not _started or _finished: return
	
	var car: Car = info.car
	var rd: CarRaceData = _race_data[car]
	rd.add_lap_time(info.lap_time)
	
	if rd.race_completed:
		car.change_state(Car.CarState.RACEOVER)
		rd.set_total_time(get_elapsed_time())
		if race_over_timer.is_stopped(): race_over_timer.start()
		
func finish_race()-> void:
	if _finished: return
	_finished = true
	
	var total_len: float = _track_curve.get_baked_length()
	var elapsed: float = get_elapsed_time()
	
	for c in _cars:
		var rd: CarRaceData = _race_data[c]
		if not rd.race_completed:
			var offset:float = _track_curve.get_closest_offset(c.global_position)
			var progress: float = offset / total_len
			rd.force_finish(elapsed, progress)
			c.change_state(Car.CarState.RACEOVER)
	pass

func _on_race_over_timer_timeout() -> void:
	finish_race()
