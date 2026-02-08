extends Car
class_name BotCar

const STEER_REACTION_MAX: float = 12.0
const STEER_REACTION_MIN: float = 8

const DEVIATION_STEP_MAX: float = 0.4
const DEVIATION_STEP_MIN: float = 0.1

const DEVIATION_LIMIT_MAX: float = 1.0
const DEVIATION_LIMIT_MIN: float = 0.1


@export var debug: bool = true
@export var waypoint_distance: float = 100.0
@export var max_top_speed_limit: float = 5500.0
@export var min_top_speed_limit: float = 2500.0
@export_range(0,1) var skill: float = 1.0
@export var max_bottom_speed_limit: float = 1750.0
@export var min_bottom_speed_limit: float = 1000.0
@export var speed_reaction: float = 3.5

@onready var target: Sprite2D = $Target

var _adjusted_waypoint_target: Vector2 = Vector2.ZERO
var _steer_reaction: float = STEER_REACTION_MAX
var _target_speed: float = 3500.0
var _next_waypoint: Waypoint
var _deviation_step: float = 0.0
var _deviation_limit: float = 0.0
var _deviation_weight: float = 0.0
var _inverted_skill: float = 1.0
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
	_steer_reaction = lerp(STEER_REACTION_MIN, STEER_REACTION_MAX, skill)
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
	
	# Apply skill-based steering responsiveness
	# Higher steer_reaction = more precise/skilled steering
	var skill_factor = clamp(STEER_REACTION_MAX / 10.0, 0.1, 1.0)  # Normalize to 0.1-1.0
	var adjusted_angle = lerp(0.0, angle_to_target, skill_factor)
	
	# Set steering direction (clamped to max steering angle)
	steer_direction = clamp(adjusted_angle, deg_to_rad(-steering_angle), deg_to_rad(steering_angle))
	
	# Accelerate if below target speed
	if velocity.length() < _target_speed:
		acceleration = transform.x * engine_power
		is_accelerating = true
	else:
		acceleration = Vector2.ZERO
		is_accelerating = false

func _physics_process(delta: float) -> void:
	if state != CarState.DRIVING or !_next_waypoint: 
		return
	
	update_waypoint()
	super._physics_process(delta)  # calls get_input(), apply_friction(), calculate_steering(), etc.
	
	# Smoothly adjust velocity magnitude toward target speed
	var current_speed = velocity.length()
	var new_speed = lerp(current_speed, _target_speed, speed_reaction * acceleration * delta)
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * new_speed

func update_waypoint() -> void:
	if !_next_waypoint:
		return
		
	var distance = global_position.distance_to(_adjusted_waypoint_target)
	
	#if debug:
		#print("Distance to waypoint %d: %f" % [_next_waypoint.number, distance])
	
	if distance < waypoint_distance:
		set_next_waypoint(_next_waypoint.next_waypoint)
		_target_speed = lerp(_allowed_min_speed, _allowed_max_speed, _next_waypoint.next_waypoint.radius_factor)
		#print(_target_speed)

func set_next_waypoint(wp: Waypoint) -> void:
	_next_waypoint = wp
	
	_deviation_weight += randf_range(-_deviation_step, _deviation_step)
	_deviation_weight = clampf(_deviation_weight, -_deviation_limit, _deviation_limit)
	
	if debug:
		print("%d %.2f" %[
			car_number, _deviation_weight
		])
	
	_adjusted_waypoint_target = wp.get_target_adjusted(_deviation_weight)
	target.global_position = _adjusted_waypoint_target
	
	
	#if debug:
		#print("New target waypoint: %d at %v" % [wp.number, wp.global_position])


func _on_deviation_timer_timeout() -> void:
	if randf() < _inverted_skill:
		_deviation_weight = -_deviation_weight
		
		if debug:
			print("Dev. Adj. --> %d %.2f" %[
				car_number, _deviation_weight
			])
