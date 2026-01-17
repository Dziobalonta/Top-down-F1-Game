extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Car:
		body.hit_verfication(get_instance_id())
