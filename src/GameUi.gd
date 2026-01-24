extends Control
class_name GameUi

@onready var margin_container: MarginContainer = $MarginContainer
@onready var race_over_label: Label = $RaceoverTable/RaceOverLabel
@onready var raceover_table: PanelContainer = $RaceoverTable
@onready var off_track_canvas: CanvasLayer = $OffTrackCanvas
@onready var red_rect_flashing: ColorRect = $OffTrackCanvas/RedFlashing
@onready var timer_label: Label = $OffTrackCanvas/TimerLabel
@onready var text_label: Label = $OffTrackCanvas/TextLabel
@onready var beep: AudioStreamPlayer = $OffTrackCanvas/Beep

var _car_ui_dict: Dictionary[Car, CarUi] = {}
var _pulse_tween: Tween
var _player_car: Car = null
var _beep_timer: float = 0.0  # Timer for playing beeps every second

@export var max_off_track_time: float = 10.0  # Should match RaceController's max_total_off_track_time

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.change_to_main()

func _enter_tree() -> void:
	EventHub.on_lap_update.connect(on_lap_update)
	EventHub.on_race_over.connect(on_race_over)
	
	EventHub.on_wheels_left_track.connect(_on_wheels_left_track)
	EventHub.on_wheels_returned_to_track.connect(_on_wheels_returned_to_track)

func _ready() -> void:
	timer_label.hide()
	text_label.hide()

func _process(delta: float) -> void:
	# Update timer based on player car's off-track time
	if _player_car and not _player_car.is_on_track:
		var remaining_time = max(0.0, max_off_track_time - _player_car.off_track_time)
		update_timer_label(remaining_time)
		
		# Increment beep timer and play beep every full second
		_beep_timer += delta
		if _beep_timer >= 1.0:
			_beep_timer -= 1.0  # Keep the remainder for accuracy
			if remaining_time > 0:  # Only beep if time remaining
				beep.play()
				#print("Beep! Remaining time: ", remaining_time)
	else:
		# Reset beep timer when not off track
		_beep_timer = 0.0
	
func on_race_over(data: Array[CarRaceData]) -> void:
	race_over_label.text = "%10s %6s %6s %5s" % [
		"Car", "Time", "Best", "Laps"
	]
	
	for d in data:
		print(d)
		race_over_label.text += "\n%s" % d
	
	raceover_table.show()
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
		
		# Find the player car
		if car.is_in_group("player"):
			_player_car = car
		
func on_lap_update(car: Car, lap_count: int, total_laps: int, lap_time: float) -> void:
	if car in _car_ui_dict:
		_car_ui_dict[car].update_values(car, lap_count, total_laps, lap_time)
	
#region Exceeding Track Limits
func _on_wheels_left_track(car: Car) -> void:
	if car.is_in_group("player"):
		_beep_timer = 0.0  # Reset beep timer - first beep will be after 1 second
		_start_off_track_animation()
		_start_off_track_timer()

func _on_wheels_returned_to_track(car: Car) -> void:
	if car.is_in_group("player"):
		_beep_timer = 0.0  # Reset beep timer
		_stop_off_track_animation()
		_stop_off_track_timer()
		
func _start_off_track_animation() -> void:
	# Kill any existing tweens
	if _pulse_tween:
		_pulse_tween.kill()
	
	# Show the canvas and start fade in
	red_rect_flashing.modulate.a = 0.0
	red_rect_flashing.show()
	
	# Create a new tween
	_pulse_tween = create_tween()
	
	# Fade in from 0.0 to 0.85 alpha over 0.3 seconds
	_pulse_tween.tween_property(red_rect_flashing, "modulate:a", 0.85, 0.3)
	
	# looping pulse effect
	_pulse_tween.tween_callback(_create_pulse_loop)

func _create_pulse_loop() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	
	_pulse_tween = create_tween()
	_pulse_tween.set_loops() # Infinite loop
	
	# Pulse between 0.4 and 0.85 alpha
	_pulse_tween.tween_property(red_rect_flashing, "modulate:a", 0.85, 0.45)
	_pulse_tween.tween_property(red_rect_flashing, "modulate:a", 0.4, 0.45)

func _stop_off_track_animation() -> void:
	# Kill the pulsing tween
	if _pulse_tween:
		_pulse_tween.kill()
	
	# Create fade out tween
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(red_rect_flashing, "modulate:a", 0.0, 0.3)
	
	# Hide the canvas after fade out completes
	fade_out_tween.tween_callback(func(): red_rect_flashing.hide())

# Timer logic - synced with player car's off_track_time
func _start_off_track_timer() -> void:
	if _player_car:
		var remaining_time = max_off_track_time - _player_car.off_track_time
		update_timer_label(remaining_time)
	timer_label.show()
	text_label.show()
	beep.play()  # Play first beep immediately when leaving track

func _stop_off_track_timer() -> void:
	timer_label.hide()
	text_label.hide()

func update_timer_label(remaining_time: float) -> void:
	# Display remaining time with 1 decimal place
	timer_label.text = "%.1f" % max(0.0, remaining_time)
	
#endregion
