extends Node2D
class_name GhostCar

@onready var car_body: Sprite2D = $CarBody
@onready var right_rear_wheel: Sprite2D = $RightRearWheel
@onready var left_rear_wheel: Sprite2D = $LeftRearWheel
@onready var right_front_wheel: Sprite2D = $RightFrontWheel
@onready var left_front_wheel: Sprite2D = $LeftFrontWheel
@onready var rear_wing: Sprite2D = $RearWing

var ghost_data: GhostData
var is_playing: bool = false
var _current_lap_time: float = 0.0
var _debug_timer: int = 0

func setup_visuals() -> void:
	var ghost_material = CanvasItemMaterial.new()
	ghost_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var ghost_color = Color(0.605, 0.905, 1.0, 0.75)
	var parts = [
		car_body, 
		rear_wing, 
		right_rear_wheel, 
		left_rear_wheel, 
		right_front_wheel, 
		left_front_wheel
	]
	
	for part in parts:
		if part:
			part.material = ghost_material
			part.modulate = ghost_color
			
func start_replay(data: GhostData) -> void:
	ghost_data = data
	if ghost_data and ghost_data.is_valid():
		print("Ghost - Starting Replay")
		is_playing = true
		_current_lap_time = 0.0
		show()
		set_process(true) # Force process on
	else:
		print("Ghost error - Invalid data in start_replay")
		stop_replay()

func stop_replay() -> void:
	is_playing = false
	hide()

func _physics_process(delta: float) -> void:
	if not is_playing or not ghost_data:
		return
		
	_current_lap_time += delta
	
	_debug_timer += 1
	if _debug_timer % 60 == 0:
		print("Ghost time: %.2f pos: %s" % [_current_lap_time, global_position])
	
	var exact_frame = _current_lap_time * ghost_data.recording_frequency
	var frame_idx = floor(exact_frame)
	var next_frame_idx = frame_idx + 1
	
	if next_frame_idx >= ghost_data.positions.size():
		if frame_idx < ghost_data.positions.size():
			global_position = ghost_data.positions[frame_idx]
			rotation = ghost_data.rotations[frame_idx]
		return

	var t = exact_frame - frame_idx
	
	var pos_a = ghost_data.positions[frame_idx]
	var pos_b = ghost_data.positions[next_frame_idx]
	
	# Move the ghost
	global_position = pos_a.lerp(pos_b, t)
	
	var rot_a = ghost_data.rotations[frame_idx]
	var rot_b = ghost_data.rotations[next_frame_idx]
	rotation = lerp_angle(rot_a, rot_b, t)
