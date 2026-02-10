extends Car
class_name PlayerCar

@export var start_acceleration_time: float = 1.25
var _race_start_time: float = 0.0
var _speed_multiplier: float = 0.0  # Start at 0

func _ready():
	super()

func _physics_process(delta: float) -> void:
	super(delta)  # IMPORTANT: Call parent physics first!
	
	# Gradual acceleration at race start
	if state == CarState.WAITING:
		_race_start_time = 0.0
		_speed_multiplier = 0.0
	elif _race_start_time < start_acceleration_time:
		_race_start_time += delta
		_speed_multiplier = clamp(_race_start_time / start_acceleration_time, 0.0, 1.0)
	else:
		_speed_multiplier = 1.0

func get_input():
	var turn = 0
	if Input.is_action_pressed("Right"):
		turn += 1
	if Input.is_action_pressed("Left"):
		turn -= 1
	
	# Calculate steering angle based on speed (less steering at high speed)
	if steering_curve_speed > 0:
		var speed_ratio = linear_velocity.length() / steering_curve_speed
		var speed_factor = lerp(1.0, min_steering_factor, clamp(speed_ratio, 0.0, 1.0))
		steer_direction = turn * deg_to_rad(steering_angle) * speed_factor
	else:
		steer_direction = turn * deg_to_rad(steering_angle)
	
	# Throttle Logic with speed multiplier
	is_accelerating = false
	acceleration_input = 0.0
	
	if Input.is_action_pressed("Throttle"):
		acceleration_input = engine_power * _speed_multiplier  # Apply multiplier
		is_accelerating = true
		
	if Input.is_action_pressed("Brake"):
		acceleration_input = braking # Braking is negative power
