extends Control
class_name GameUi

@onready var margin_container: MarginContainer = $MarginContainer
@onready var race_over_label: Label = $PanelContainer/RaceOverLabel
@onready var panel_container: PanelContainer = $PanelContainer
var _car_ui_dict: Dictionary[Car, CarUi] = {}

func _enter_tree() -> void:
	EventHub.on_lap_update.connect(on_lap_update)
	EventHub.on_race_over.connect(on_race_over)
	
func on_race_over(data: Array[CarRaceData]) -> void:
	race_over_label.text = "%10s %6s %6s %5s" % [
		"Car", "Time", "Best", "Laps"
	]
	
	for d in data:
		print(d)
		race_over_label.text += "\n%s" % d
	
	panel_container.show()
	get_tree().paused = true

func setup(cars: Array[Car], total_laps: int) -> void:
	var ui_nodes : Array[Node] = margin_container.get_children()
	for i in range(ui_nodes.size()):
		if i >= cars.size(): break
		var ui: CarUi = ui_nodes[i]
		var car: Car = cars[i]
		ui.update_values(car, 0, total_laps, 0.0)
		ui.show()
		_car_ui_dict[car] = ui
		
func on_lap_update(car: Car, lap_count: int, total_laps: int, lap_time: float) -> void:
	if car in _car_ui_dict:
		_car_ui_dict[car].update_values(car,lap_count, total_laps, lap_time)
