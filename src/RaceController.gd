extends Node
class_name RaceController

@export var total_laps: int = 5
@onready var race_over_timer: Timer = $RaceOverTimer
@export var time_penalty_per_violation: float = 5.0  # 5 seconds penalty
@export var max_off_track_time_allowed: float = 3.0  # 3 seconds off track = penalty
@export var max_total_off_track_time: float = 10.0  # 10 seconds total = disqualified to WAITING

var car_penalties: Dictionary = {}  # {car: total_penalty_time}
var car_violations: Dictionary = {}  # {car: violation_count}
var car_total_off_track_time: Dictionary = {}  # {car: total_time_off_track}
var car_currently_off_track: Dictionary = {}  # {car: is_off_track}

var _cars: Array[Car] = []
var _track_curve: Curve2D
var _race_data: Dictionary = {}
var _started: bool = false
var _finished: bool = false
var _start_time: float
var _off_track_check_timer: float = 0.0
const OFF_TRACK_CHECK_INTERVAL: float = 0.5  # Check every 0.5 seconds

func setup(cars: Array[Car], track_curve: Curve2D) -> void:
	_cars = cars
	_track_curve = track_curve
	
	for c in cars:
		_race_data[c] = CarRaceData.new(
			c.car_name, c.car_number, total_laps
		)
		
	# Initialize penalty tracking
	for car in cars:
		car_penalties[car] = 0.0
		car_violations[car] = 0
		car_total_off_track_time[car] = 0.0
		car_currently_off_track[car] = false
	
	EventHub.wheels_left_track.connect(_on_car_left_track)
	EventHub.wheels_returned_to_track.connect(_on_car_returned_to_track)
	EventHub.on_lap_completed.connect(on_lap_completed)
		
	print("RaceController init with %d cars" % _cars.size())
	
func _process(delta: float) -> void:
	if not _started or _finished:
		return
	
	# Update off-track time for cars currently off track
	for car in _cars:
		if car_currently_off_track.get(car, false):
			car_total_off_track_time[car] += delta
	
	# Check violations periodically
	_off_track_check_timer += delta
	if _off_track_check_timer >= OFF_TRACK_CHECK_INTERVAL:
		_off_track_check_timer = 0.0
		for car in _cars:
			if car_currently_off_track.get(car, false):
				check_if_exceeded_max_time(car)
	
#region Car Outside Track	
func _on_car_left_track(car: Car):
	car_currently_off_track[car] = true
	print(car.name + " left the track - violation recorded!")

func check_if_exceeded_max_time(car: Car) -> bool:
	# Check if total off-track time exceeds max time
	if car_total_off_track_time[car] >= max_total_off_track_time:
		print(car.name + " exceeded max off-track time (" + str(car_total_off_track_time[car]) + "s) - DISQUALIFIED!")
		car_currently_off_track[car] = false
		car.change_state(Car.CarState.RACEOVER)
		EventHub.emit_penalty_applied(car, 0.0, car_violations[car])  # Notify UI
		car.reset_off_track_time()
		return true
	return false

func _on_car_returned_to_track(car: Car):
	car_currently_off_track[car] = false
	var time_off_track = car.get_off_track_time()
	
	# Note: car_total_off_track_time is already updated in _process
	# so we don't add it again here
	
	# Check one last time if exceeded max time
	if check_if_exceeded_max_time(car):
		return
	
	# Apply penalty if this violation exceeded the threshold
	if time_off_track >= max_off_track_time_allowed:
		apply_penalty(car, time_penalty_per_violation)
		print(car.name + " was off track for " + str(time_off_track) + "s - PENALTY APPLIED!")
	
	car.reset_off_track_time()

func apply_penalty(car: Car, penalty_time: float):
	car_penalties[car] += penalty_time
	car_violations[car] += 1
	
	EventHub.emit_penalty_applied(car, penalty_time, car_violations[car])
	
	print("Penalty: +" + str(penalty_time) + "s for " + car.name)
	print("Total penalties: " + str(car_penalties[car]) + "s")
	print("Total off-track time: " + str(car_total_off_track_time[car]) + "s")

func get_final_time(car: Car, race_time: float) -> float:
	return race_time + car_penalties[car]

func get_car_penalties(car: Car) -> float:
	return car_penalties.get(car, 0.0)

func get_car_violations(car: Car) -> int:
	return car_violations.get(car, 0)

func get_car_total_off_track_time(car: Car) -> float:
	return car_total_off_track_time.get(car, 0.0)
	
#endregion	
	
func _enter_tree() -> void:
	EventHub.on_race_start.connect(on_race_start)
	
func on_race_start() -> void:
	if _started:
		return
	_started = true
	_finished = false
	_start_time = Time.get_ticks_msec()
	
func get_elapsed_time() -> float:
	return Time.get_ticks_msec() - _start_time
	
func on_lap_completed(info: LapCompleteData) -> void:
	print("RaceController on_lap_completed:", info)
	if not _started or _finished:
		return
	
	var car: Car = info.car
	var rd: CarRaceData = _race_data[car]
	rd.add_lap_time(info.lap_time)
	EventHub.emit_on_lap_update(
		car, 
		rd.completed_laps,
		total_laps,
		info.lap_time
	)
	
	if rd.race_completed:
		car.change_state(Car.CarState.RACEOVER)
		rd.set_total_time(get_elapsed_time())
		if race_over_timer.is_stopped():
			race_over_timer.start()
		
func finish_race() -> void:
	if _finished:
		return
	_finished = true
	
	var total_len: float = _track_curve.get_baked_length()
	var elapsed: float = get_elapsed_time()
	
	for c in _cars:
		var rd: CarRaceData = _race_data[c]
		if not rd.race_completed:
			var offset: float = _track_curve.get_closest_offset(c.global_position)
			var progress: float = offset / total_len
			rd.force_finish(elapsed, progress)
			c.change_state(Car.CarState.RACEOVER)
		
	var results: Array[CarRaceData] = _race_data.values()
	results.sort_custom(CarRaceData.compare)
			
	EventHub.emit_on_race_over(results)
	
func _on_race_over_timer_timeout() -> void:
	finish_race()
