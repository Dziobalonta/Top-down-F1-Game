extends Node2D
class_name Track

@onready var SectionsHolder: Node = $SectionsHolder
@onready var CarsHolder: Node = $CarsHolder
@onready var RacingLine: Path2D  = $TrackStroke/RacingLine
var race_controller: RaceController
@onready var game_ui: GameUi = $Ui/GameUi
@onready var track_processor: TrackProcessor = $TrackStroke/RacingLine/TrackProcessor
@onready var waypoints_holder: Node = $WaypointsHolder

var racing_line_curve: Curve2D

func _ready() -> void:
	if has_node("TimeTrialController"):
		race_controller = $TimeTrialController
	elif has_node("RaceController"):
		race_controller = $RaceController
	else:
		push_error("No RaceController, or TimeTrialController!")
		return
		
	await setup()
	
func setup() -> void:
	var cars: Array[Car] = []
	racing_line_curve = RacingLine.curve
	
	track_processor.build_waypoint_data(waypoints_holder)
	await track_processor.build_completed
	#print("track_processor.build_completed")
	
	for car in CarsHolder.get_children():
		if car is Car:
			cars.append(car)
			car.setup(SectionsHolder.get_children().size())
			
		if car is BotCar:
			car.set_next_waypoint(track_processor.first_waypoint)
			
	race_controller.setup(cars, racing_line_curve)
	game_ui.setup(cars, race_controller.total_laps)		
	

func get_direction_to_path(from_pos: Vector2) -> Vector2:
	var closeset_offset: float = racing_line_curve.get_closest_offset(from_pos)
	var nearest_point: Vector2 = racing_line_curve.sample_baked(closeset_offset)
	return from_pos.direction_to(nearest_point)


func _on_start_line_body_entered(body: Node2D) -> void:
	if body is Car:
		body.lap_completed()
