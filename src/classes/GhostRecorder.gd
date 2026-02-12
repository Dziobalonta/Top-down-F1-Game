extends Node
class_name GhostRecorder

signal on_best_lap_beaten(new_ghost_data: GhostData)

@export var recording_fps: int = 60

var _current_recording: GhostData
var _best_recording: GhostData
var _accumulated_time: float = 0.0
var _record_interval: float = 0.0
var _is_recording: bool = false
var _target_car: Node2D

func setup(target: Node2D) -> void:
	_target_car = target
	_record_interval = 1.0 / float(recording_fps)
	
	_current_recording = GhostData.new()
	_current_recording.recording_frequency = recording_fps

func start_new_lap() -> void:
	# Creating new object for every lap
	_current_recording = GhostData.new()
	_current_recording.recording_frequency = recording_fps
	
	_accumulated_time = 0.0
	_is_recording = true
	
	# Capture the starting frame
	_record_frame()

func stop_recording() -> void:
	_is_recording = false

func finish_lap(lap_time: float) -> void:
	_is_recording = false
	_current_recording.total_time = lap_time
	
	# check if this is the best lap
	if _best_recording == null or lap_time < _best_recording.total_time:
		print("NEW GHOST RECORDED! Time: %.3f" % lap_time)
		print("Frames recorded: %d" % _current_recording.positions.size())
		
		_best_recording = _current_recording
		
		emit_signal("on_best_lap_beaten", _best_recording)
	
	# Prepare for next lap
	start_new_lap()

func get_best_ghost() -> GhostData:
	return _best_recording

func _physics_process(delta: float) -> void:
	if not _is_recording or not _target_car:
		return
		
	_accumulated_time += delta
	
	# to catch up if frame rate drops
	while _accumulated_time >= _record_interval:
		_accumulated_time -= _record_interval
		_record_frame()

func _record_frame() -> void:
	if _target_car:
		_current_recording.add_frame(_target_car.global_position, _target_car.global_rotation)
		#print("Recorded pos: %s and rot: %s" % [_target_car.global_position, _target_car.global_rotation])
