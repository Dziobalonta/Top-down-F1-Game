extends Area2D

@export var sector_index: int = 0  # manually set index of the sector

func _on_body_entered(body: Node2D) -> void:
	if body is Car:
		body.hit_verification(sector_index)
		
		# Emit sector crossing event for delta time tracking
		if sector_index > 0:
			EventHub.emit_on_sector_crossed(body, sector_index)
