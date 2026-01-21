extends CharacterBody2D
class_name Car

enum CarState {WAITING, DRIVING, RACEOVER}

@export var car_number: int = 0
@export var car_name: String = "Car"
var state: CarState = CarState.WAITING

@export var wheel_base = 250 # How apart are wheels from each other
@export var steering_angle = 50
@export var engine_power = 10000
@export var friction = -2 # Based on velocity (Important when slow)
@export var drag = -0.0001 # Based on square of velocity (Important when fast)
@export var braking = -1000
@export var max_speed_reverse = 500
@export var slip_speed = 4000
@export var traction_fast = 0.2
@export var traction_slow = 0.9
@export var min_steering_factor = 0.15 # Minimalny współczynnik skrętu przy max prędkości
@export var steering_curve_speed = 1500.0 # Prędkość, przy której zaczyna się znacząca redukcja

var acceleration = Vector2.ZERO
var steer_direction

var sectors_count: int = 0
var sectors_passed: Array[int] = []
var lap_time: float = 0.0

@onready var left_front_wheel_area: Area2D = $LeftFrontWheel/LeftFrontWheelArea
@onready var right_front_wheel_area: Area2D = $RightFrontWheel/RightFrontWheelArea
@onready var left_rear_wheel_area: Area2D = $LeftRearWheel/LeftRearWheelArea
@onready var right_rear_wheel_area: Area2D = $RightRearWheel/RightRearWheelArea

var wheels_on_track: Dictionary = {
	"left_front": false,
	"right_front": false,
	"left_rear": false,
	"right_rear": false
}

var is_on_track: bool = true
var off_track_time: float = 0.0  # Track how long car is off track

func _physics_process(delta: float) -> void:
	acceleration = Vector2.ZERO
	get_input()
	apply_friction()
	calculate_steering(delta)
	velocity += acceleration * delta
	move_and_slide()
	
	if not is_on_track:
		off_track_time += delta
	
func _process(delta: float) -> void:
	lap_time += delta
	
func _ready() -> void:
	left_front_wheel_area.area_entered.connect(_on_wheel_entered.bind("left_front"))
	left_front_wheel_area.area_exited.connect(_on_wheel_exited.bind("left_front"))
	
	right_front_wheel_area.area_entered.connect(_on_wheel_entered.bind("right_front"))
	right_front_wheel_area.area_exited.connect(_on_wheel_exited.bind("right_front"))
	
	left_rear_wheel_area.area_entered.connect(_on_wheel_entered.bind("left_rear"))
	left_rear_wheel_area.area_exited.connect(_on_wheel_exited.bind("left_rear"))
	
	right_rear_wheel_area.area_entered.connect(_on_wheel_entered.bind("right_rear"))
	right_rear_wheel_area.area_exited.connect(_on_wheel_exited.bind("right_rear"))
	
	EventHub.on_race_start.connect(on_race_start)
	set_physics_process(false)
	
#region Wheels Touch Logic
func _on_wheel_entered(area: Area2D, wheel_name: String):
	if area.is_in_group("track_collision"):
		wheels_on_track[wheel_name] = true
		check_all_wheels_status()

func _on_wheel_exited(area: Area2D, wheel_name: String):
	if area.is_in_group("track_collision"):
		wheels_on_track[wheel_name] = false
		check_all_wheels_status()
	
func check_all_wheels_status():
	var all_wheels_off_track = wheels_on_track.values().all(func(x): return x == true)
	var all_wheels_on_track = wheels_on_track.values().all(func(x): return x == false)
	
	# Debug
	var wheels_count_on = wheels_on_track.values().filter(func(x): return x == false).size()
	print("Wheels on track: ", wheels_count_on, "/4")
	
	# Wszystkie koła wróciły na tor
	if all_wheels_on_track and not is_on_track:
		on_all_wheels_on_track()
		is_on_track = true
		print("All 4 wheels back on track")
	
	# Wszystkie koła zjechały z toru
	elif all_wheels_off_track and is_on_track:
		on_wheels_off_track()
		is_on_track = false
		print("All 4 wheels off track - START COUNTING!")
	
	# Stan pośredni (część kół na torze, część nie)
	elif not all_wheels_on_track and not all_wheels_off_track:
		# Jeśli był poza torem i wrócił choć jednym kołem - przestań liczyć
		if not is_on_track:
			print("Partial return - stopping timer")
			on_all_wheels_on_track()  # Zatrzymaj licznik
			is_on_track = true  # Uznaj że "wrócił"

func on_all_wheels_on_track():
	print(name + ": Back on track")
	EventHub.emit_on_all_wheels_on_track(self)

func on_wheels_off_track():
	print(name + ": LEFT THE TRACK!")
	EventHub.emit_on_wheels_off_track(self)

func get_off_track_time() -> float:
	return off_track_time

func reset_off_track_time():
	off_track_time = 0.0
	
#endregion

#region State
func change_state(new_state: CarState) -> void:
	if new_state == state: return
	if state == CarState.RACEOVER: return
	
	state = new_state
	
	match new_state:
		CarState.DRIVING:
			set_physics_process(true)
		CarState.RACEOVER:
			set_physics_process(false)

#endregion

#region Steering Physics

func apply_friction():
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction
	var drag_force = velocity * velocity.length() * drag
	acceleration += drag_force + friction_force
		
	
func get_input():
	var turn = 0
	if Input.is_action_pressed("Right"):
		turn += 1
	if Input.is_action_pressed("Left"):
		turn -= 1
	
	if steering_curve_speed > 0:
		var speed_ratio = velocity.length() / steering_curve_speed
		var speed_factor = lerp(1.0, min_steering_factor, clamp(speed_ratio, 0.0, 1.0))
		steer_direction = turn * deg_to_rad(steering_angle) * speed_factor
	else:
		steer_direction = turn * deg_to_rad(steering_angle)
	
	if Input.is_action_pressed("Throttle"):
		acceleration = transform.x * engine_power
		
	if Input.is_action_pressed("Brake"):
		acceleration = transform.x * braking
		
func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_direction) * delta
	
	var new_heading = (front_wheel - rear_wheel).normalized()
	
	var traction = traction_slow
	
	if velocity.length() > slip_speed:
		traction = traction_fast
	
	var d = new_heading.dot(velocity.normalized())
	if d > 0: 
		# linear_interpolate
		velocity = velocity.lerp(new_heading * velocity.length(), traction)
	if d < 0:
		velocity = - new_heading * min(velocity.length(),max_speed_reverse)
	
	#print(velocity.length())
	
	rotation = new_heading.angle()

#endregion

#region Lapping Logic
func setup(sc: int) -> void:	
	sectors_count = sc

func lap_completed() -> void:
	if sectors_count == sectors_passed.size():
		var lcd: LapCompleteData = LapCompleteData.new(self, lap_time)
		print("lap_completed %s" % lcd)
		EventHub.emit_on_lap_completed(lcd)
	sectors_passed.clear()
	lap_time = 0.0
	
func hit_verfication(sector_id: int ) -> void:
	if sector_id not in sectors_passed:
		sectors_passed.append(sector_id)
#endregion

func on_race_start() -> void:
	change_state(CarState.DRIVING)
