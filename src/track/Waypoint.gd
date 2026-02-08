extends Node2D
class_name Waypoint

const MAX_RADIUS: float = 8000.0

@onready var right_collision: RayCast2D = $RightCollision
@onready var left_collision: RayCast2D = $LeftCollision
@onready var label: Label = $Label

var _left_collision_distance: float = 0.0
var _right_collision_distance: float = 0.0
var _left_collision_dir: Vector2 = Vector2.ZERO
var _right_collision_dir: Vector2 = Vector2.ZERO
var _max_path_deviation: float

var radius: float = MAX_RADIUS:
	get: return radius
	
var radius_factor: float = 0.0:
	get: return radius_factor

var number: int = 0:
	get: return number
	
var next_waypoint: Waypoint:
	get:
		if !next_waypoint: printerr("WP %d no next_waypoint" % number)
		return next_waypoint

var previous_waypoint: Waypoint:
	get:
		if !previous_waypoint: printerr("WP %d no next_waypoint" % number)
		return previous_waypoint
		
func setup(next_wp: Waypoint, prev_wp: Waypoint, num:int) -> void:
	next_waypoint = next_wp
	previous_waypoint = prev_wp
	number = num
	label.text = "%d" % num

func calc_turn_radius() -> void:
	var a: float = previous_waypoint.global_position.distance_to(global_position)
	var b: float = global_position.distance_to(next_waypoint.global_position)
	var c: float = next_waypoint.global_position.distance_to(previous_waypoint.global_position)
	var s: float = (a + b + c) / 2.0
	
	var area: float  = sqrt(max(s * (s-a) * (s-b) * (s-c), 0.0))
	
	if !is_zero_approx(area):
		radius = (a * b * c) / (4.0 * area)

func set_radius_factor(min_radius: float, radius_curve: Curve) -> void:
	var adj: float = clampf(radius, min_radius, MAX_RADIUS)
	var t: float
	# Avoid division by zero
	if is_equal_approx(MAX_RADIUS, min_radius):
		t = 1.0
	else:
		t = (adj - min_radius) / (MAX_RADIUS - min_radius)
		
	radius_factor = radius_curve.sample(t)
	
func set_collider_data(max_path_deviation: float) -> void:
	_max_path_deviation = max_path_deviation
	
	_left_collision_distance = left_collision.target_position.length()
	_right_collision_distance = right_collision.target_position.length()
	
	if left_collision.is_colliding():
		var colp: Vector2 = left_collision.get_collision_point()
		_left_collision_distance = global_position.distance_to(colp)
		
	if right_collision.is_colliding():
		var colp: Vector2 = right_collision.get_collision_point()
		_right_collision_distance = global_position.distance_to(colp)
		
	_left_collision_dir =  Vector2.LEFT.rotated(rotation)
	_right_collision_dir =  Vector2.RIGHT.rotated(rotation)
	
func get_target_adjusted(weight: float) -> Vector2:
	if is_zero_approx(weight): 
		return global_position
	
	var deviation: float
	var direction: Vector2
	
	if weight > 0.0:
		deviation = weight * _right_collision_distance
		direction = _right_collision_dir
	else:
		deviation = abs(weight) * _left_collision_distance
		direction = _left_collision_dir
	
	deviation = clampf(deviation, 0.0, _max_path_deviation)
	
	# DEBUG
	print("WP %d: weight=%.2f, raw_dev=%.2f, clamped=%.2f, collision_dist=%.2f" % [
		number, weight, 
		abs(weight) * (_left_collision_distance if weight < 0 else _right_collision_distance),
		deviation,
		_left_collision_distance if weight < 0 else _right_collision_distance
	])
	
	return global_position + direction * deviation

	
func _to_string() -> String:
	return "%d next: %d prev: %d rad: %.2f factor: %.2f lcd: %.2f rcd: %.2f" % [
		number, next_waypoint.number, previous_waypoint.number,
		radius, radius_factor, 
		_left_collision_distance,_right_collision_distance
	]
	
