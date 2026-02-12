extends Resource

class_name GhostData

@export var positions: Array[Vector2] = []
@export var rotations: Array[float] = []
@export var recording_frequency: int = 24
@export var total_time: float = 0.0

func clear() -> void:
	positions.clear()
	rotations.clear()
	total_time = 0.0

func add_frame(pos: Vector2, rot: float) -> void:
	positions.append(pos)
	rotations.append(rot)

func is_valid() -> bool:
	return positions.size() > 0
