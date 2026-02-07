extends Node2D
class_name Waypoint

@onready var right_collision: RayCast2D = $RightCollision
@onready var left_collision: RayCast2D = $LeftCollision
@onready var label: Label = $Label

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
	
func _to_string() -> String:
	return "%d next: %d prev %d" % [number, next_waypoint.number, previous_waypoint.number]
	
