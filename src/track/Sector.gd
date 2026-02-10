extends Area2D

@export var sector_index: int = 0  # manually set index of the sector

func _on_body_entered(body: Node2D) -> void:
	if body is Car:
		body.hit_verfication(sector_index)
