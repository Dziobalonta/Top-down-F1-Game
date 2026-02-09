extends Car
class_name BotCar

const DEVIATION_STEP_MAX: float = 0.4
const DEVIATION_STEP_MIN: float = 0.1

const DEVIATION_LIMIT_MAX: float = 1.0
const DEVIATION_LIMIT_MIN: float = 0.1


@export var debug: bool = true
@export var base_waypoint_distance: float = 100.0
@export var max_top_speed_limit: float = 5500.0
@export var min_top_speed_limit: float = 2500.0
@export_range(0,1) var skill: float = 1.0
@export var max_bottom_speed_limit: float = 1750.0
@export var min_bottom_speed_limit: float = 1000.0
@export var waypoint_lookahead: int = 5  # How many waypoints ahead to check for nearest
@onready var avoidance_ray: RayCast2D = $RayCast2D # scan for other cars

@onready var target: Sprite2D = $Target

var _adjusted_waypoint_target: Vector2 = Vector2.ZERO
var _target_speed: float = 3500.0
var _next_waypoint: Waypoint
var _deviation_step: float = 0.0
var _deviation_limit: float = 0.0
var _deviation_weight: float = 0.0
var _inverted_skill: float = 0.0
var _allowed_max_speed: float = 0.0
var _allowed_min_speed: float = 0.0

func _ready() -> void:
	target.visible = debug
	sector_passed_sound.volume_db = -200
	start_line_passed.volume_db = -200
	super()
	
	_inverted_skill = 1.0 - skill
	_deviation_step = lerp(DEVIATION_STEP_MIN, DEVIATION_STEP_MAX, _inverted_skill)
	_deviation_limit = lerp(DEVIATION_LIMIT_MIN, DEVIATION_LIMIT_MAX, _inverted_skill)
	_deviation_weight = randf_range(-_deviation_limit, _deviation_limit)
	update_speeds()
	
func update_speeds() -> void:
	_allowed_max_speed = randf_range(min_top_speed_limit, max_top_speed_limit)
	_allowed_min_speed = randf_range(min_bottom_speed_limit, max_bottom_speed_limit)

func get_input() -> void:
	if !_next_waypoint: 
		return
	
	# Calculate the angle we need to steer
	var direction_to_target = (_adjusted_waypoint_target - global_position).normalized()
	var angle_to_target = transform.x.angle_to(direction_to_target)
	
	# Apply skill-based steering smoothness (removed distance damping)
	var steering_responsiveness = clamp(skill, 0.2, 1.0)
	var adjusted_angle = lerp(0.0, angle_to_target, steering_responsiveness)
	
	# Set steering direction (clamped to max steering angle)
	steer_direction = clamp(adjusted_angle, deg_to_rad(-steering_angle), deg_to_rad(steering_angle))
	
	# Simple acceleration - let friction/drag handle the rest naturally
	if velocity.length() < _target_speed:
		acceleration = transform.x * engine_power
		is_accelerating = true
	else:
		# Don't brake, just stop accelerating - let drag slow us down naturally
		acceleration = Vector2.ZERO
		is_accelerating = false
		
	# SIMPLE BRAKING LOGIC
	var car_ahead = false
	if avoidance_ray.is_colliding():
		var collider = avoidance_ray.get_collider()
		if collider is Car:
			car_ahead = true
			
	if velocity.length() < _target_speed and not car_ahead:
		acceleration = transform.x * engine_power
		is_accelerating = true
	else:
		# If car ahead or over speed -> Coast/Brake
		acceleration = Vector2.ZERO 
		is_accelerating = false
		if car_ahead:
			# Optional: Active braking to prevent rear-ending
			acceleration = -transform.x * engine_power * 0.5

func _physics_process(delta: float) -> void:
	if state != CarState.DRIVING or !_next_waypoint: 
		return
	
	update_waypoint()
	super._physics_process(delta)

func update_waypoint() -> void:
	if !_next_waypoint:
		return
	
	var distance = global_position.distance_to(_adjusted_waypoint_target)
	
	# Dynamic waypoint distance based on speed
	var current_speed = velocity.length()
	var dynamic_waypoint_distance = base_waypoint_distance + (current_speed / 40.0)
	
	# Check if we've passed the current waypoint
	var direction_to_waypoint = (_adjusted_waypoint_target - global_position).normalized()
	var movement_direction = velocity.normalized() if velocity.length() > 10 else transform.x
	var dot_product = direction_to_waypoint.dot(movement_direction)
	
	# Switch waypoint if within distance OR if we've clearly passed it
	if distance < dynamic_waypoint_distance or (distance < 400.0 and dot_product < -0.2):
		advance_to_next_waypoint()
		return
	
	# Recovery: If we're far from current waypoint, check if a future waypoint is closer
	# This handles collision pushes
	if distance > 500.0:
		check_and_skip_to_nearest_waypoint()

func advance_to_next_waypoint() -> void:
	var next_wp = _next_waypoint.next_waypoint
	set_next_waypoint(next_wp)
	_target_speed = lerp(_allowed_min_speed, _allowed_max_speed, next_wp.radius_factor)
	
	#if debug:
		#print("Car %d -> WP %d, speed: %.0f" % [car_number, next_wp.number, _target_speed])

func check_and_skip_to_nearest_waypoint() -> void:
	"""Find and jump to the nearest waypoint ahead if we got pushed off course"""
	var current_wp = _next_waypoint
	var nearest_wp = current_wp
	var nearest_distance = global_position.distance_to(_adjusted_waypoint_target)
	
	# Check next few waypoints to find the nearest one
	var check_wp = current_wp
	for i in range(waypoint_lookahead):
		check_wp = check_wp.next_waypoint
		var check_distance = global_position.distance_to(check_wp.global_position)
		
		if check_distance < nearest_distance:
			nearest_distance = check_distance
			nearest_wp = check_wp
	
	# If we found a closer waypoint ahead, skip to it
	if nearest_wp != current_wp:
		#if debug:
			#print("Car %d RECOVERY: skipping from WP %d to WP %d (%.0f -> %.0f)" % [
				#car_number, current_wp.number, nearest_wp.number, 
				#global_position.distance_to(_adjusted_waypoint_target), nearest_distance
			#])
		
		set_next_waypoint(nearest_wp)
		_target_speed = lerp(_allowed_min_speed, _allowed_max_speed, nearest_wp.radius_factor)

func set_next_waypoint(wp: Waypoint) -> void:
	_next_waypoint = wp
	
	# Update deviation weight for this waypoint
	_deviation_weight += randf_range(-_deviation_step, _deviation_step)
	_deviation_weight = clampf(_deviation_weight, -_deviation_limit, _deviation_limit)
	
	# Calculate adjusted target position based on deviation
	_adjusted_waypoint_target = wp.get_target_adjusted(_deviation_weight)
	target.global_position = _adjusted_waypoint_target

func _on_deviation_timer_timeout() -> void:
	if randf() < _inverted_skill:
		_deviation_weight = -_deviation_weight
		
		#if debug:
			#print("Car %d deviation adjusted: %.2f" % [car_number, _deviation_weight])
