extends VBoxContainer
class_name CarUi

@export var LabelAlignment: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT

@onready var name_label: Label = $NameLabel
@onready var lap_label: Label = $LapLabel
@onready var last_lap_label: Label = $LastLapLabel

func _ready() -> void:
	name_label.horizontal_alignment = LabelAlignment
	lap_label.horizontal_alignment = LabelAlignment
	last_lap_label.horizontal_alignment = LabelAlignment

func update_values(car: Car, lap_count: int, total_laps: int, lap_time: float) -> void:
	name_label.text = "%s (%02d)" % [car.car_name, car.car_number]
	lap_label.text = "Laps %d/%d" % [lap_count, total_laps]
	last_lap_label.text = "Last: %.2fs" % lap_time
