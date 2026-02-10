extends Car
class_name BotCar

@export_category("Bot Settings")
@export_range(0.0, 1.0, 0.1) var skill_level: float = 0.5  # 0 - noob 1 - expert
@export var max_speed: float = 5000.0  # Maximum speed tbot can reach
@export var min_speed: float = 3000.0  # Minimum speed in corners
@export var start_acceleration_time: float = 2.0  # Seconds to reach full speed

@export_category("Collision Avoidance")
@export var slowdown_factor: float = 0.2  # Slow down to 20% when car detected
@export var detection_distance: float = 400.0  # How far ahead to look

var _race_start_time: float = 0.0
var _speed_multiplier: float = 0.0
var _collision_slowdown: float = 1.0  # 1.0 = full speed, 0.2 = slowed down

@export var debug: bool = true

@onready var target_marker: Sprite2D = $Target
@onready var deviation_timer: Timer = $DeviationTimer
@onready var raycast_forward: RayCast2D = $RayCastForward

var _next_waypoint: Waypoint
var _target_position: Vector2 = Vector2.ZERO
var _racing_line: float = 0.0  # -1 to 1, changes over time
var _racing_line_step: float = 0.1  # How much racing line can change per timer
var _inverted_skill: float = 0.0  # Cached 1.0 - skill

func _ready() -> void:
	# Calculate inverted skill (0=expert, 1=beginner)
	_inverted_skill = 1.0 - skill_level
	
	# Initialize racing line randomly
	_racing_line = randf_range(-1.0, 1.0)
	
	# Racing line step: skilled drivers have smaller, more consistent changes
	# Beginners (low skill) have bigger, more erratic line changes
	_racing_line_step = lerp(0.5, 0.8, _inverted_skill)
	
	# Hide target marker unless debugging
	if target_marker:
		target_marker.visible = debug
	
	# Setup raycast for collision detection
	if raycast_forward:
		raycast_forward.enabled = true
		raycast_forward.target_position = Vector2(detection_distance, 0)
		raycast_forward.collision_mask = 9  # Detect cars on layers 8 and 9
		raycast_forward.collide_with_areas = false
		raycast_forward.collide_with_bodies = true
	
	$SectorPassed.volume_db = -80
	$StartLinePassed.volume_db = -80
	$EngineIdle.volume_db = -20
	$EngineHighRPM.volume_db = -30
	
	super()

func _physics_process(delta: float) -> void:
	if not is_on_track:
		off_track_time += delta
	
	# Check for cars ahead
	_check_collision_avoidance()

func _check_collision_avoidance() -> void:
	if not raycast_forward:
		_collision_slowdown = 1.0
		return
	
	# Force raycast update
	raycast_forward.force_raycast_update()
	
	if raycast_forward.is_colliding():
		var collider = raycast_forward.get_collider()
		
		# Check if we hit a car (RigidBody2D)
		if collider is RigidBody2D and collider != self:
			_collision_slowdown = slowdown_factor
			
			if debug:
				print("[Bot %s] Car detected ahead! Slowing to %d%%" % [car_name, slowdown_factor * 100])
		else:
			_collision_slowdown = 1.0
	else:
		_collision_slowdown = 1.0

func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	# Don't move if waiting or no waypoint
	if state == CarState.WAITING or !_next_waypoint:
		physics_state.linear_velocity = physics_state.linear_velocity.lerp(Vector2.ZERO, 0.1)
		physics_state.angular_velocity = 0.0
		_race_start_time = 0.0
		_speed_multiplier = 0.0
		return
	
	# Gradual acceleration at race start
	if _race_start_time < start_acceleration_time:
		_race_start_time += physics_state.step
		_speed_multiplier = clamp(_race_start_time / start_acceleration_time, 0.0, 1.0)
	else:
		_speed_multiplier = 1.0
	
	# Update waypoint if close enough
	if global_position.distance_to(_target_position) < 150.0:
		set_next_waypoint(_next_waypoint.next_waypoint)
	
	# Calculate direction to target
	var direction = (_target_position - global_position).normalized()
	
	# ROTATION - Skill affects turn speed (based on skill)
	var current_angle = rotation
	var target_angle = direction.angle()
	var turn_speed = lerp(3.0, 8.0, skill_level)
	var new_angle = lerp_angle(current_angle, target_angle, turn_speed * physics_state.step)
	
	physics_state.transform = Transform2D(new_angle, global_position)
	physics_state.angular_velocity = 0.0
	
	# SPEED - Use waypoint factor AND corner angle
	var angle_diff = abs(angle_difference(current_angle, target_angle))
	var corner_penalty = angle_diff * lerp(0.8, 0.3, skill_level)
	var speed_factor = clamp(1.0 - corner_penalty, 0.3, 1.0)

	# Get waypoint radius_factor (0.01 = tight corner, 1.0 = straight)
	var waypoint_factor = 1.0
	if _next_waypoint:
		waypoint_factor = _next_waypoint.radius_factor

	# Combine both factors
	var final_speed_factor = speed_factor * waypoint_factor

	# Apply all multipliers INCLUDING collision avoidance
	var desired_speed = lerp(min_speed, max_speed, final_speed_factor) * _speed_multiplier * _collision_slowdown
	var desired_velocity = direction * desired_speed

	var responsiveness = lerp(0.1, 0.3, skill_level)
	physics_state.linear_velocity = physics_state.linear_velocity.lerp(desired_velocity, responsiveness)

func set_next_waypoint(wp: Waypoint) -> void:
	if !wp:
		return
	
	_next_waypoint = wp
	
	# Calculate racing line offset to prevent bunching
	var offset = Vector2.ZERO
	if wp.next_waypoint:
		var track_dir = (wp.next_waypoint.global_position - wp.global_position).normalized()
		var perpendicular = Vector2(-track_dir.y, track_dir.x)
		offset = perpendicular * _racing_line * 200.0
	
	# Add small random variance (less for skilled bots)
	var variance = lerp(20.0, 5.0, skill_level)
	var random_offset = Vector2(randf_range(-variance, variance), randf_range(-variance, variance))
	
	_target_position = wp.global_position + offset + random_offset
	
	if target_marker:
		target_marker.global_position = _target_position

func _on_deviation_timer_timeout() -> void:
	# Random step in racing line
	_racing_line += randf_range(-_racing_line_step, _racing_line_step)
	# Keep within bounds
	_racing_line = clampf(_racing_line, -1.0, 1.0)
	
	# RECALCULATE target position with new racing line
	if _next_waypoint:
		var offset = Vector2.ZERO
		if _next_waypoint.next_waypoint:
			var track_dir = (_next_waypoint.next_waypoint.global_position - _next_waypoint.global_position).normalized()
			var perpendicular = Vector2(-track_dir.y, track_dir.x)
			offset = perpendicular * _racing_line * 150.0
		
		var variance = lerp(40.0, 10.0, skill_level)
		var random_offset = Vector2(randf_range(-variance, variance), randf_range(-variance, variance))
		
		_target_position = _next_waypoint.global_position + offset + random_offset
		
		if target_marker:
			target_marker.global_position = _target_position
	
	if debug:
		print("[Bot %s] Racing line adjusted to: %.2f" % [car_name, _racing_line])

func get_input() -> void:
	pass  # Bots don't use input
