extends RigidBody2D
class_name Car

enum CarState {WAITING, DRIVING, RACEOVER}

@export_category("Finish Behavior")
@export var coast_friction: float = 0.9999  # How quickly to slow down after finish

@export_category("Visuals")
@export var car_texture: Texture2D = preload("res://assets/sprites/f1_car_body.svg")
@export var car_wing_texture: Texture2D = preload("res://assets/sprites/f1_car_rear_wing.svg")
@export var car_number: int = 0
@export var car_name: String = "Car"

@export_category("Physics / Handling")
@export var wheel_base = 250
@export var steering_angle: float = 50.0
@export var engine_power = 9000 
@export var braking = -4000
@export var max_speed_reverse = 1500
@export var slip_speed = 00
@export var traction_fast = 0.2
@export var traction_slow = 0.9
@export var min_steering_factor = 0.3
@export var steering_curve_speed = 3000.0 

@export_category("RigidBody Properties")
@export var body_mass: float = 1000.0
@export var linear_damp_value: float = 2.0
@export var angular_damp_value: float = 5.0 
@export var bounce_amount: float = 0.2

# State variables
var state: CarState = CarState.WAITING
var acceleration_input: float = 0.0 
var steer_direction: float = 0.0 
var is_accelerating: bool = false

# Lapping
var lap_time: float = 0.0
var race_started: bool = false
var sectors_count: int = 0
var sectors_passed: Array[int] = []

# References
@onready var car_body: Sprite2D = $CarBody
@onready var rear_wing: Sprite2D = $RearWing
@onready var crash_sound: AudioStreamPlayer2D = $CrashSound
@onready var engine_idle: AudioStreamPlayer2D = $EngineIdle
@onready var engine_high_rpm: AudioStreamPlayer2D = $EngineHighRPM
@onready var start_line_passed: AudioStreamPlayer2D = $StartLinePassed
@onready var sector_passed_sound: AudioStreamPlayer2D = $SectorPassed
@onready var off_track_sound: AudioStreamPlayer2D = $OffTrack

# Wheel Detectors
@onready var left_front_wheel_area: Area2D = $LeftFrontWheel/LeftFrontWheelArea
@onready var right_front_wheel_area: Area2D = $RightFrontWheel/RightFrontWheelArea
@onready var left_rear_wheel_area: Area2D = $LeftRearWheel/LeftRearWheelArea
@onready var right_rear_wheel_area: Area2D = $RightRearWheel/RightRearWheelArea

# Track Status
var wheels_on_track: Dictionary = {
	"left_front": false,
	"right_front": false,
	"left_rear": false,
	"right_rear": false
}
var is_on_track: bool = true
var off_track_time: float = 0.0
var min_volume: float = -80.0
var max_idle_volume: float = -20.0
var max_high_rpm_volume: float = -30.0
var last_crash_time: float = 0.0

func _ready() -> void:
	car_body.texture = car_texture
	rear_wing.texture = car_wing_texture
	
	mass = body_mass
	linear_damp = linear_damp_value
	angular_damp = angular_damp_value
	gravity_scale = 0 
	
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = bounce_amount
	physics_material_override.friction = 0.5
	
	freeze = true 
	contact_monitor = true
	max_contacts_reported = 4
	
	# RigidBody collision detection
	body_entered.connect(_on_body_entered)
	
	left_front_wheel_area.area_entered.connect(_on_wheel_entered.bind("left_front"))
	left_front_wheel_area.area_exited.connect(_on_wheel_exited.bind("left_front"))
	right_front_wheel_area.area_entered.connect(_on_wheel_entered.bind("right_front"))
	right_front_wheel_area.area_exited.connect(_on_wheel_exited.bind("right_front"))
	left_rear_wheel_area.area_entered.connect(_on_wheel_entered.bind("left_rear"))
	left_rear_wheel_area.area_exited.connect(_on_wheel_exited.bind("left_rear"))
	right_rear_wheel_area.area_entered.connect(_on_wheel_entered.bind("right_rear"))
	right_rear_wheel_area.area_exited.connect(_on_wheel_exited.bind("right_rear"))
	
	EventHub.on_race_start.connect(on_race_start)
	
	engine_idle.play()
	engine_high_rpm.play()
	engine_idle.bus = "Master"
	engine_high_rpm.bus = "Master"

func _physics_process(delta: float) -> void:
	get_input()
	update_engine_sound(delta)
	
	if not is_on_track:
		off_track_time += delta

func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	# Throttle / Brake
	if acceleration_input != 0:
		var applied_force = transform.x * acceleration_input * mass
		apply_central_force(applied_force)

	# Steering Physics
	var lv = _state.linear_velocity
	var current_speed = lv.length()
	var traction = traction_slow
	if current_speed > slip_speed:
		traction = traction_fast
	
	if abs(steer_direction) > 0.001 and current_speed > 10:
		
		var turn_radius = wheel_base / sin(steer_direction)
		var target_angular_speed = current_speed / turn_radius
		
		var smooth_factor = 0.15
		_state.angular_velocity = lerp(_state.angular_velocity, target_angular_speed, smooth_factor)
	else:
		_state.angular_velocity = lerp(_state.angular_velocity, 0.0, 0.1)

	# Traction
	var forward_dir = transform.x
	var right_dir = transform.y
	
	var forward_velocity = forward_dir * lv.dot(forward_dir)
	var right_velocity = right_dir * lv.dot(right_dir)
	
	_state.linear_velocity = forward_velocity + (right_velocity * (1.0 - traction))
	
	# Reverse Cap
	var d = forward_dir.dot(lv.normalized())
	if d < -0.5 and lv.length() > max_speed_reverse:
		_state.linear_velocity = lv.normalized() * max_speed_reverse

func get_input():
	pass

func _process(delta: float) -> void:
	if race_started and state == CarState.DRIVING:
		lap_time += delta

func _on_body_entered(body: Node) -> void:
	if body is Car:
		var other_car = body as Car
		var current_time = Time.get_ticks_msec() / 1000.0
		
		if current_time - last_crash_time > 0.1:
			# linear_velocity for RigidBody
			var relative_speed = (linear_velocity - other_car.linear_velocity).length()
			
			if relative_speed > 100.0:
				play_crash_sound(relative_speed)
				last_crash_time = current_time

#region Sound & Helpers
func update_engine_sound(delta: float) -> void:
	if is_accelerating:
		engine_high_rpm.volume_db = lerp(engine_high_rpm.volume_db, max_high_rpm_volume, 20.0 * delta)
		engine_idle.volume_db = lerp(engine_idle.volume_db, min_volume, delta)
	else:
		engine_high_rpm.volume_db = lerp(engine_high_rpm.volume_db, min_volume, delta)
		engine_idle.volume_db = lerp(engine_idle.volume_db, max_idle_volume, 20.0 * delta)

func play_crash_sound(speed: float) -> void:
	var max_crash_speed = 5500.0
	var volume_factor = clamp(speed / max_crash_speed, 0.0, 1.0)
	
	# Dynamic volume (-35db quiet to -5db loud)
	crash_sound.volume_db = lerp(-35.0, -10.0, volume_factor)
	crash_sound.pitch_scale = randf_range(0.8, 1.2)
	crash_sound.play()
# ---------------------------

func setup(sc: int) -> void:	
	sectors_count = sc

func lap_completed() -> void:
	if sectors_count == sectors_passed.size():
		var lcd: LapCompleteData = LapCompleteData.new(self, lap_time)
		EventHub.emit_on_lap_completed(lcd)
		sectors_passed.clear()
		start_line_passed.play()
		lap_time = 0.0

func hit_verification(sector_id: int ) -> void:
	if sector_id not in sectors_passed:
		sectors_passed.append(sector_id)
		sector_passed_sound.play()

func change_state(new_state: CarState) -> void:
	state = new_state
	if state == CarState.DRIVING:
		freeze = false
	elif state == CarState.RACEOVER:
		engine_idle.stop()
		engine_high_rpm.stop()

func on_race_start() -> void:
	change_state(CarState.DRIVING)
	race_started = true
#endregion

#region Wheels Logic
func _on_wheel_entered(area: Area2D, wheel_name: String):
	if area.is_in_group("track_collision"):
		wheels_on_track[wheel_name] = true
		check_all_wheels_status()

func _on_wheel_exited(area: Area2D, wheel_name: String):
	if area.is_in_group("track_collision"):
		wheels_on_track[wheel_name] = false
		check_all_wheels_status()
	
func check_all_wheels_status():
	# True = Trawa (Kara), False = Asfalt (Bezpiecznie)
	var all_wheels_in_grass = wheels_on_track.values().all(func(x): return x == true)
	var any_wheel_safe = wheels_on_track.values().has(false)
	
	if is_on_track and all_wheels_in_grass:
		on_wheels_left_track()
		is_on_track = false
		
	elif not is_on_track and any_wheel_safe:
		on_all_wheels_returned_to_track()
		is_on_track = true

func on_all_wheels_returned_to_track():
	off_track_sound.stop()
	EventHub.emit_on_wheels_returned_to_track(self)

func on_wheels_left_track():
	off_track_sound.play()
	EventHub.emit_on_wheels_left_track(self)

func get_off_track_time() -> float:
	return off_track_time

func reset_off_track_time():
	off_track_time = 0.0
#endregion
