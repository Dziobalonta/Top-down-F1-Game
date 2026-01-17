extends Node2D
class_name Track

@onready var SectionsHolder: Node = $SectionsHolder
@onready var CarsHolder: Node = $CarsHolder

func _ready() -> void:
	for car in CarsHolder.get_children():
		if car is Car:
			car.setup(SectionsHolder.get_children().size())


func _on_start_line_body_entered(body: Node2D) -> void:
	if body is Car:
		body.lap_completed()
