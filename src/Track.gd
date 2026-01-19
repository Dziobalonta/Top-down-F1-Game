extends Node2D
class_name Track

@onready var SectionsHolder: Node = $SectionsHolder
@onready var CarsHolder: Node = $CarsHolder
@onready var RacingLine: Path2D  = $TrackStroke/RacingLine
@onready var race_controller: RaceController = $RaceController
@onready var game_ui: GameUi = $Ui/GameUi

var racing_line_curve: Curve2D

func _ready() -> void:
	var cars: Array[Car] = []
	racing_line_curve = RacingLine.curve
	
	for car in CarsHolder.get_children():
		cars.append(car)
		if car is Car:
			car.setup(SectionsHolder.get_children().size())
		
	race_controller.setup(cars, racing_line_curve)
	game_ui.setup(cars, race_controller.total_laps)

func get_direction_to_path(from_pos: Vector2) -> Vector2:
	var closeset_offset: float = racing_line_curve.get_closest_offset(from_pos)
	var nearest_point: Vector2 = racing_line_curve.sample_baked(closeset_offset)
	return from_pos.direction_to(nearest_point)


func _on_start_line_body_entered(body: Node2D) -> void:
	if body is Car:
		body.lap_completed()
