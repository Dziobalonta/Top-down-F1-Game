extends CharacterBody2D
class_name Car

enum CarState {WAITING, DRIVING, RACEOVER}

@export var car_texture: Texture2D = preload("res://assets/sprites/f1_car_body.svg")
@export var car_wing_texture: Texture2D = preload("res://assets/sprites/f1_car_rear_wing.svg")
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

var lap_time: float = 0.0
var race_started: bool = false
var sectors_count: int = 0
var sectors_passed: Array[int] = []

@onready var left_front_wheel_area: Area2D = $LeftFrontWheel/LeftFrontWheelArea
@onready var right_front_wheel_area: Area2D = $RightFrontWheel/RightFrontWheelArea
@onready var left_rear_wheel_area: Area2D = $LeftRearWheel/LeftRearWheelArea
@onready var right_rear_wheel_area: Area2D = $RightRearWheel/RightRearWheelArea
@onready var car_body: Sprite2D = $CarBody
@onready var rear_wing: Sprite2D = $RearWing

@onready var crash_sound: AudioStreamPlayer2D = $CrashSound
@onready var engine_idle: AudioStreamPlayer2D = $EngineIdle
@onready var engine_high_rpm: AudioStreamPlayer2D = $EngineHighRPM
@onready var crash_detector: Area2D = $CrashDetector
@onready var start_line_passed: AudioStreamPlayer2D = $StartLinePassed
@onready var sector_passed_sound: AudioStreamPlayer2D = $SectorPassed
@onready var off_track_sound: AudioStreamPlayer2D = $OffTrack
var is_accelerating: bool = false
var min_volume: float = -80.0
var max_idle_volume: float = -20.0
var max_high_rpm_volume: float = -30.0
var crash_cooldown: float = 0.0
var crash_cooldown_time: float = 0.5  # prevent spamming
var last_crash_time: float = 0.0


var wheels_on_track: Dictionary = {
	"left_front": false,
	"right_front": false,
	"left_rear": false,
	"right_rear": false
}

var is_on_track: bool = true
var off_track_time: float = 0.0  # Track how long car is off track

func _physics_process(delta: float) -> void:
	get_input()
	apply_friction()
	calculate_steering(delta)
	velocity += acceleration * delta
	move_and_slide()
	
	update_engine_sound(delta)
	
	if not is_on_track:
		off_track_time += delta
		
func get_input():
	# Empty - to be overridden by child classes
	pass
	
func _process(delta: float) -> void:
	if race_started and state == CarState.DRIVING:
		lap_time += delta
	
func _ready() -> void:
	car_body.texture = car_texture
	rear_wing.texture = car_wing_texture
	
	left_front_wheel_area.area_entered.connect(_on_wheel_entered.bind("left_front"))
	left_front_wheel_area.area_exited.connect(_on_wheel_exited.bind("left_front"))
	
	right_front_wheel_area.area_entered.connect(_on_wheel_entered.bind("right_front"))
	right_front_wheel_area.area_exited.connect(_on_wheel_exited.bind("right_front"))
	
	left_rear_wheel_area.area_entered.connect(_on_wheel_entered.bind("left_rear"))
	left_rear_wheel_area.area_exited.connect(_on_wheel_exited.bind("left_rear"))
	
	right_rear_wheel_area.area_entered.connect(_on_wheel_entered.bind("right_rear"))
	right_rear_wheel_area.area_exited.connect(_on_wheel_exited.bind("right_rear"))
	
	crash_detector.body_entered.connect(_on_crash_detector_body_entered)
	
	EventHub.on_race_start.connect(on_race_start)
	set_physics_process(false)
	
	engine_idle.bus = "CarEngine"
	engine_high_rpm.bus = "CarEngine"
	
	engine_idle.play()
	engine_high_rpm.play()
	engine_high_rpm.volume_db = min_volume  # mute completely
	engine_idle.volume_db = max_idle_volume

#region Sound Settings
func update_engine_sound(delta: float) -> void:
	#DEBUG
	#print("is_accelerating: ", is_accelerating, " | idle_vol: ", engine_idle.volume_db, " | high_vol: ", engine_high_rpm.volume_db)
	if is_accelerating:
		engine_high_rpm.volume_db = lerp(engine_high_rpm.volume_db, max_high_rpm_volume, 20.0 * delta)
		engine_idle.volume_db = lerp(engine_idle.volume_db, min_volume, delta)
	else:
		engine_high_rpm.volume_db = lerp(engine_high_rpm.volume_db, min_volume, delta)
		engine_idle.volume_db = lerp(engine_idle.volume_db, max_idle_volume, 20.0 * delta)
		
func _on_crash_detector_body_entered(body: Node2D) -> void:
	if body is Car:
		var current_time = Time.get_ticks_msec() / 1000.0
		
		if current_time - last_crash_time > 0.1:
			var other_car = body as Car
			var relative_speed = (velocity - other_car.velocity).length()
			
			if relative_speed > 0:
				play_crash_sound(relative_speed)
				last_crash_time = current_time

func play_crash_sound(speed: float) -> void:
	# loudness depending on speed
	var max_speed = 5500.0
	var volume_factor = clamp(speed / max_speed, 0.4, 1.0)
	crash_sound.volume_db = lerp(-35.0, -20.0, volume_factor)
	
	# Random pitch
	crash_sound.pitch_scale = randf_range(0.9, 1.1)
	
	crash_sound.play()
	
	#print(name + " crashed at speed: " + str(int(speed)))
	
#endregion	

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
	#var wheels_count_on = wheels_on_track.values().filter(func(x): return x == false).size()
	#print("Wheels on track: ", wheels_count_on, "/4")
	
	# Wszystkie koła wróciły na tor
	if all_wheels_on_track and not is_on_track:
		on_all_wheels_returned_to_track()
		is_on_track = true
		#print("All 4 wheels back on track")
	
	# Wszystkie koła zjechały z toru
	elif all_wheels_off_track and is_on_track:
		on_wheels_left_track()
		is_on_track = false
		#print("All 4 wheels off track - START COUNTING!")
	
	# Stan pośredni (część kół na torze, część nie)
	elif not all_wheels_on_track and not all_wheels_off_track:
		# Jeśli był poza torem i wrócił choć jednym kołem - przestań liczyć
		if not is_on_track:
			#print("Partial return - stopping timer")
			on_all_wheels_returned_to_track()  # Zatrzymaj licznik
			is_on_track = true  # Uznaj że "wrócił"

func on_all_wheels_returned_to_track():
	#print(name + ": Back on track")
	off_track_sound.stop()
	EventHub.emit_on_wheels_returned_to_track(self)

func on_wheels_left_track():
	#print(name + ": LEFT THE TRACK!")
	off_track_sound.play()
	EventHub.emit_on_wheels_left_track(self)

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
			off_track_sound.stop()
			engine_idle.stop()
			engine_high_rpm.stop()
			set_physics_process(false)

#endregion

#region Steering Physics

func apply_friction():
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction
	var drag_force = velocity * velocity.length() * drag
	acceleration += drag_force + friction_force
				
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
		start_line_passed.play()
		lap_time = 0.0
	
func hit_verfication(sector_id: int ) -> void:
	
	print("%s hit sector %d" % [name, sector_id])
	
	if sector_id not in sectors_passed:
		sectors_passed.append(sector_id)
		sector_passed_sound.play()
#endregion

func on_race_start() -> void:
	change_state(CarState.DRIVING)
	race_started = true
