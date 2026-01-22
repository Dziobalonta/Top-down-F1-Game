extends Car
class_name PlayerCar

func _physics_process(delta: float) -> void:
	acceleration = Vector2.ZERO
	get_input()
	super(delta)

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
