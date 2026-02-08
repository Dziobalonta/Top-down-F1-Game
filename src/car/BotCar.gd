extends Car
class_name BotCar

const STEER_REACTION_MAX: float = 9.0
@export var debug: bool = true
@export var waypoint_distance: float = 100.0
@export var max_top_speed_limit: float = 5500.0
@export var min_top_speed_limit: float = 2500.0

@export var max_bottom_speed_limit: float = 1750.0
@export var min_bottom_speed_limit: float = 1000.0
@export var speed_reaction: float = 3.5

@onready var target: Sprite2D = $Target

var _adjusted_waypoint_target: Vector2 = Vector2.ZERO
var _target_speed: float = 3500.0
var _next_waypoint: Waypoint

func _ready() -> void:
	target.visible = debug
	#_target_speed = randf_range(min_top_speed_limit, max_top_speed_limit)

	
	
	sector_passed_sound.volume_db = -200
	start_line_passed.volume_db = -200
	super()

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
		_target_speed = lerp(max_bottom_speed_limit, max_top_speed_limit, _next_waypoint.next_waypoint.radius_factor)
		#print(_target_speed)

func set_next_waypoint(wp: Waypoint) -> void:
	_next_waypoint = wp
	#_adjusted_waypoint_target = wp.global_position
	_adjusted_waypoint_target = wp.get_target_adjusted(-0.9)
	target.global_position = _adjusted_waypoint_target
	
	
	#if debug:
		#print("New target waypoint: %d at %v" % [wp.number, wp.global_position])
