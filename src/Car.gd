extends CharacterBody2D
class_name Car

enum CarState {WAITING, DRIVING}

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


func _physics_process(delta: float) -> void:
	acceleration = Vector2.ZERO
	get_input()
	apply_friction()
	calculate_steering(delta)
	velocity += acceleration * delta
	move_and_slide()
	
func _process(delta: float) -> void:
	lap_time += delta
	
func _ready() -> void:
	EventHub.on_race_start.connect(on_race_start)
	set_physics_process(false)

#region state
func change_state(new_state: CarState) -> void:
	if new_state == state: return
	state = new_state
	
	match new_state:
		CarState.DRIVING:
			set_physics_process(true)

#endregion

#region SteeringPhysics

func apply_friction():
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction
	var drag_force = velocity * velocity.length() * drag
	acceleration += drag_force + friction_force
		
	
func get_input():
	var turn = 0
	if Input.is_action_pressed("Right"):
		turn +=1
	if Input.is_action_pressed("Left"):
		turn -=1
	steer_direction = turn * deg_to_rad(steering_angle)
	
		# Nieliniowa redukcja skrętu
	var speed_ratio = velocity.length() / steering_curve_speed
	var speed_factor = lerp(1.0, min_steering_factor, clamp(speed_ratio, 0.0, 1.0))
	steer_direction = turn * deg_to_rad(steering_angle) * speed_factor
	
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

#region LappingLogic
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
