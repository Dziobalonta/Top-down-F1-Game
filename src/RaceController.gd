extends Node
class_name RaceController

@export var total_laps: int = 5
@onready var race_over_timer: Timer = $RaceOverTimer
@export var time_penalty_per_violation: float = 5.0  # 5 seconds penalty
@export var penalty_interval: float = 3.0  # Penalty every 3 seconds off track
@export var max_total_off_track_time: float = 10.0  # 10 seconds total = disqualified to WAITING

var car_penalties: Dictionary = {}  # {car: total_penalty_time}
var car_violations: Dictionary = {}  # {car: violation_count}
var car_total_off_track_time: Dictionary = {}  # {car: total_time_off_track}
var car_currently_off_track: Dictionary = {}  # {car: is_off_track}
var car_last_penalty_threshold: Dictionary = {}  # {car: last_threshold_crossed}

var player_best_laptime: float = 0.0
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
		car_last_penalty_threshold[car] = 0
	
	MusicManager.stop_menu_track()
	EventHub.emit_set_max_off_track_time(max_total_off_track_time)
	EventHub.on_wheels_left_track.connect(_on_car_left_track)
	EventHub.on_wheels_returned_to_track.connect(_on_car_returned_to_track)
	EventHub.on_lap_completed.connect(on_lap_completed)
		
	print("RaceController init with %d cars" % _cars.size())
	
func _process(delta: float) -> void:
	if not _started or _finished:
		return
	
	# Update off-track time for cars currently off track
	for car in _cars:
		if car_currently_off_track.get(car, false):
			var old_time = car_total_off_track_time[car]
			car_total_off_track_time[car] += delta
			
			# Check if crossed a new 3-second threshold
			check_penalty_threshold(car, old_time, car_total_off_track_time[car])
	
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

func check_if_exceeded_max_time(car: Car) -> bool:
	# Check if total off-track time exceeds max time
	if car_total_off_track_time[car] >= max_total_off_track_time:
		print(car.name + " exceeded max off-track time (" + str(car_total_off_track_time[car]) + "s) - DISQUALIFIED!")
		car_currently_off_track[car] = false
		car.change_state(Car.CarState.RACEOVER)
		EventHub.emit_penalty_applied(car, 0.0, car_violations[car])  # Notify UI
		
		# If the player is disqualified, end the race immediately
		if car.is_in_group("player"):
			finish_race()
		
		return true
	return false

func _on_car_returned_to_track(car: Car):
	car_currently_off_track[car] = false

func check_penalty_threshold(car: Car, old_time: float, new_time: float) -> void:
	# Calculate how many 3-second thresholds have been crossed
	var old_threshold = int(old_time / penalty_interval)
	var new_threshold = int(new_time / penalty_interval)
	
	# If we crossed into a new threshold, apply penalty
	if new_threshold > old_threshold and new_threshold > car_last_penalty_threshold[car]:
		car_last_penalty_threshold[car] = new_threshold
		apply_penalty(car, time_penalty_per_violation)
		print(car.name + " crossed " + str(new_threshold * penalty_interval) + "s threshold - PENALTY APPLIED!")

func apply_penalty(car: Car, penalty_time: float):
	car_penalties[car] += penalty_time
	car_violations[car] += 1
	
	EventHub.emit_penalty_applied(car, penalty_time, car_violations[car])
	
	print("Penalty: +" + str(penalty_time) + "s for " + car.name)
	print("Total penalties: " + str(car_penalties[car]) + "s")

func get_final_time(car: Car, race_time: float) -> float:
	return race_time + car_penalties[car]

func get_car_penalties(car: Car) -> float:
	return car_penalties.get(car, 0.0)
	
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
	EventHub.emit_on_lap_update(car, rd.completed_laps, total_laps, info.lap_time, rd.best_lap)
	
	if car is PlayerCar:
		GameManager.save_best_lap(info.lap_time)
	
	if rd.race_completed:
		car.change_state(Car.CarState.RACEOVER)
		
		# Convert penalty seconds to milliseconds (* 1000.0)
		var penalty_ms = get_car_penalties(car) * 1000.0
		var final_race_time_ms = get_elapsed_time() + penalty_ms
		
		rd.set_total_time(final_race_time_ms)
		rd.set_meta("penalty_time", get_car_penalties(car))
		
		# Only finish the race session if the PLAYER finishes.
		# If a bot finishes, the race continues until the player is done.
		if car.is_in_group("player"):
			finish_race()
		

func finish_race() -> void:
	if _finished:
		return
	_finished = true
	
	# force finish logic for bots
	var total_len: float = _track_curve.get_baked_length()
	var elapsed: float = get_elapsed_time()
	
	for c in _cars:
		var rd: CarRaceData = _race_data[c]
		var penalty = get_car_penalties(c)
		
		# Ensure metadata is set for all cars (even if they DNF)
		rd.set_meta("penalty_time", penalty)
		
		if not rd.race_completed:
			var offset: float = _track_curve.get_closest_offset(c.global_position)
			var progress: float = offset / total_len
			rd.force_finish(elapsed, progress)
			
			# Add penalty to DNF/Forced finish time as well
			if rd.total_time > 0:
				rd.total_time += penalty
				
			c.change_state(Car.CarState.RACEOVER)
	
	# Sorting and displaying info
	var results: Array[CarRaceData] = []
	for rd in _race_data.values():
		results.append(rd)
	results.sort_custom(CarRaceData.compare)
	
	var final_string = ""
	
	# Add Header
	final_string += CarRaceData.get_header_string() + "\n"
	final_string += "--------------------------------------------------------\n"

	# Add Rows with Rank
	for i in range(results.size()):
		var data = results[i]
		var rank = i + 1
		final_string += data.get_formatted_row(rank) + "\n" 
	
	print(final_string)
	EventHub.emit_on_race_over(results)
	
func _on_race_over_timer_timeout() -> void:
	finish_race()
