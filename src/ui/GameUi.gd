extends Control
class_name GameUi

@onready var margin_container: MarginContainer = $MarginContainer
@onready var results_grid: GridContainer = $RaceoverTable/ResultsGrid
@onready var raceover_table: PanelContainer = $RaceoverTable
@onready var off_track_canvas: CanvasLayer = $OffTrackCanvas
@onready var red_rect_flashing: ColorRect = $OffTrackCanvas/RedFlashing
@onready var timer_label: Label = $OffTrackCanvas/TimerLabel
@onready var text_label: Label = $OffTrackCanvas/TextLabel
@onready var beep: AudioStreamPlayer = $OffTrackCanvas/Beep
@onready var penalty_label: Label = $PenaltyLabel

# Lap timer labels
@onready var current_lap_timer_label: Label = $CurrentLapTimer
@onready var delta_time_label: Label = $CurrentLapTimer/DeltaTimeLabel

@onready var pause_menu_container: CanvasLayer = $EscCanvas
@onready var resume_button: Button = $EscCanvas/VBoxContainer/MarginContainer/GridContainer2/ResumeButton
@onready var restart_button: Button = $EscCanvas/VBoxContainer/MarginContainer/GridContainer2/RestartButton
@onready var quit_button: Button = $EscCanvas/VBoxContainer/MarginContainer/GridContainer2/QuitButton

@export var table_font: Font = preload("res://assets/fonts/F1-Font-Family/Formula1-Regular-1.ttf")
@export var table_font_size: int = 24
@export var delta_display_duration: float = 3.0  # How long to show delta

var _car_ui_dict: Dictionary[Car, CarUi] = {}
var _pulse_tween: Tween
var _penalty_tween: Tween
var _player_car: Car = null
var _beep_timer: float = 0.0

var _current_lap_time: float = 0.0 

var _race_started: bool = false
var _penalty_display_timer: float = 0.0

# Sector delta tracking
var _delta_display_timer: float = 0.0
var _delta_visible: bool = false
var _current_sector_times: Array[float] = []  # Times at each sector for current lap
var _last_lap_sector_times: Array[float] = []  # Times from previous lap
var _sector_count: int = 0  # How many sectors in the track

@export var max_off_track_time: float = 10.0

# delta colors
const DELTA_FASTER_COLOR: Color = Color(0.0, 1.0, 0.0)  # Green
const DELTA_SLOWER_COLOR: Color = Color(1.0, 0.0, 0.0)  # Red
const DELTA_NEUTRAL_COLOR: Color = Color(1.0, 1.0, 1.0)  # White

func _enter_tree() -> void:
	EventHub.on_lap_update.connect(on_lap_update)
	EventHub.on_race_over.connect(on_race_over)
	EventHub.on_race_start.connect(_on_race_start)
	
	EventHub.on_wheels_left_track.connect(_on_wheels_left_track)
	EventHub.on_wheels_returned_to_track.connect(_on_wheels_returned_to_track)
	
	EventHub.penalty_applied.connect(_on_penalty_applied)
	EventHub.set_max_off_track_time.connect(_on_set_max_off_track_time)
	
	if EventHub.has_signal("on_sector_crossed"):
		EventHub.on_sector_crossed.connect(_on_sector_crossed)

func _ready() -> void:
	timer_label.hide()
	text_label.hide()
	
	# Setup lap timer labels
	if current_lap_timer_label:
		current_lap_timer_label.text = "0.00s"
	
	if delta_time_label:
		delta_time_label.text = ""
		delta_time_label.hide()
		
	if penalty_label:
		penalty_label.text = ""
		penalty_label.hide()
	
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	# Update real-time lap timer for player
	if _race_started and _player_car and _player_car.get("state") != Car.CarState.RACEOVER:
		
		# Only add time if not paused
		if not get_tree().paused:
			_current_lap_time += delta
		
		# Update current lap timer
		if current_lap_timer_label:
			current_lap_timer_label.text = "%.2fs" % _current_lap_time
	
	# Handle delta display timer (hide after 3 seconds)
	if _delta_visible:
		if not get_tree().paused:
			_delta_display_timer -= delta
			
		if _delta_display_timer <= 0.0:
			_hide_delta()
	
	# Update off-track timer
	if _player_car and not _player_car.is_on_track:
		var remaining_time = max(0.0, max_off_track_time - _player_car.off_track_time)
		update_timer_label(remaining_time)
		
		if not get_tree().paused:
			_beep_timer += delta
			if _beep_timer >= 1.0:
				_beep_timer -= 1.0
				if remaining_time > 0:
					beep.play()
	else:
		_beep_timer = 0.0
		
	# Penalty fade-out
	if _penalty_display_timer > 0:
		if not get_tree().paused:
			_penalty_display_timer -= delta
			
		if _penalty_display_timer <= 0:
			if _penalty_tween:
				_penalty_tween.kill()
			
			_penalty_tween = create_tween()
			_penalty_tween.tween_property(penalty_label, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_penalty_tween.tween_callback(penalty_label.hide)

func _on_penalty_applied(car: Car, penalty_time: float, _violation_count: int) -> void:
	# Only show if player car and penalty time is bigger
	if penalty_time > 0:
		if car == _player_car:
			
			if _penalty_tween:
				_penalty_tween.kill()
			
			penalty_label.text = "+ %.1f s PENALTY" % penalty_time
			penalty_label.modulate.a = 0.0 # Start invisible
			penalty_label.show()
			
			_penalty_tween = create_tween()
			# Fade in over 0.25 seconds
			_penalty_tween.tween_property(penalty_label, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
			_penalty_display_timer = 3.0  # Show for 3 seconds

# Called when player crosses a sector
func _on_sector_crossed(car: Car, sector_index: int) -> void:
	# Only track players sectors
	if car != _player_car:
		return
	
	# Don't show delta on finish line (sector 0 is usually finish)
	if sector_index == 0:
		return
	
	# Make sure sector index is valid
	if sector_index < 1 or sector_index > _sector_count:
		return
	
	var current_time = _current_lap_time
	
	# Store sector time (sector_index is 1-based, array is 0-based)
	var array_index = sector_index - 1
	if array_index < _current_sector_times.size():
		_current_sector_times[array_index] = current_time
	
	# Calculate and show delta if we have reference data
	if _last_lap_sector_times.size() > array_index and _last_lap_sector_times[array_index] > 0.0:
		var last_sector_time = _last_lap_sector_times[array_index]
		var delta = current_time - last_sector_time
		_show_delta(delta)

func _show_delta(delta: float) -> void:
	if not delta_time_label:
		return
	
	# Format delta with + or - sign
	var delta_text = ""
	if delta >= 0.0:
		delta_text = "+%.2fs" % delta
		delta_time_label.modulate = DELTA_SLOWER_COLOR  # Red when slower
	else:
		delta_text = "%.2fs" % delta  # Negative sign included
		delta_time_label.modulate = DELTA_FASTER_COLOR  # Green when faster
	
	delta_time_label.text = delta_text
	delta_time_label.show()
	
	# Reset timer to hide after 3 seconds
	_delta_display_timer = delta_display_duration
	_delta_visible = true

func _hide_delta() -> void:
	if delta_time_label:
		delta_time_label.hide()
	_delta_visible = false

func _on_race_start() -> void:
	_race_started = true
	_current_lap_time = 0.0
	
	# Initialize sector arrays
	for i in range(_sector_count):
		if i < _current_sector_times.size():
			_current_sector_times[i] = 0.0
		if i < _last_lap_sector_times.size():
			_last_lap_sector_times[i] = 0.0
	
	_hide_delta()

#region Building Table

func on_race_over(data: Array[CarRaceData]) -> void:
	_race_started = false
	_hide_delta()
	
	for child in results_grid.get_children():
		child.queue_free()

	var headers = ["Pos", "Driver", "Best Lap", "Laps", "Pen", "Gap"]
	for h in headers:
		_add_cell(h, true)

	var winner_time: float = 0.0
	if data.size() > 0:
		if data[0].race_completed or data[0].total_time > 0:
			winner_time = data[0].total_time

	for i in range(data.size()):
		var d = data[i]
		
		_add_cell(str(i + 1) + ".")
		_add_cell(d.car_name)
		
		if d.best_lap != CarRaceData.DEFAULT_LAPTIME:
			_add_cell("%.2fs" % d.best_lap)
		else:
			_add_cell("--")
			
		_add_cell(str(d.completed_laps))
		
		# Penalty Column
		var pen_time = 0.0
		if d.has_meta("penalty_time"):
			pen_time = d.get_meta("penalty_time")
		
		if pen_time > 0:
			var p_label = Label.new()
			p_label.text = "+%.1fs" % pen_time
			p_label.modulate = Color.YELLOW
			if table_font:
				p_label.add_theme_font_override("font", table_font)
			p_label.add_theme_font_size_override("font_size", table_font_size)
			p_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			p_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			results_grid.add_child(p_label)
		else:
			_add_cell("-")
		
		var time_str = ""
		
		if d.race_completed or d.total_time > 0:
			if i == 0:
				time_str = "%.2fs" % (d.total_time / 1000.0)
			else:
				if winner_time > 0:
					var gap = d.total_time - winner_time
					time_str = "+%.2fs" % (gap / 1000.0)
				else:
					time_str = "%.2fs" % (d.total_time / 1000.0)
			
			if not d.race_completed: 
				time_str = "DNF"
		
		_add_cell(time_str)

	raceover_table.show()
	get_tree().paused = true

func _add_cell(text: String, is_header: bool = false) -> void:
	var label = Label.new()
	label.text = text
	
	if table_font:
		label.add_theme_font_override("font", table_font)
	else:
		# Add a print statement to see if the font is failing to load on map 2
		print("WARNING: table_font is NULL in GameUi!") 
	
	var font_size = table_font_size
	if is_header:
		font_size += 8
		label.modulate = Color(0.7, 0.7, 0.7)
	
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	results_grid.add_child(label)

#endregion

func setup(cars: Array[Car], total_laps: int, sector_count: int = 3) -> void:
	var ui_nodes : Array[Node] = margin_container.get_children()
	for i in range(ui_nodes.size()):
		if i >= cars.size(): break
		var ui: CarUi = ui_nodes[i]
		var car: Car = cars[i]
		ui.update_values(car, 0, total_laps, 0.0, 0.0)
		ui.show()
		_car_ui_dict[car] = ui
		
		if car.is_in_group("player"):
			_player_car = car
	
	# Initialize sector arrays based on track sectors
	_sector_count = sector_count
	_current_sector_times.resize(sector_count)
	_last_lap_sector_times.resize(sector_count)
	for i in range(sector_count):
		_current_sector_times[i] = 0.0
		_last_lap_sector_times[i] = 0.0

func on_lap_update(car: Car, lap_count: int, total_laps: int, last_lap_time: float, best_lap_time: float) -> void:
	if car in _car_ui_dict:
		_car_ui_dict[car].update_values(car, lap_count, total_laps, last_lap_time, best_lap_time)
	
	# When player completes a lap, save sector times for next lap comparison
	if car == _player_car:
		# Copy current sector times to last lap reference
		for i in range(min(_current_sector_times.size(), _last_lap_sector_times.size())):
			_last_lap_sector_times[i] = _current_sector_times[i]
		
		# Reset current sector times for new lap
		for i in range(_current_sector_times.size()):
			_current_sector_times[i] = 0.0
		
		_current_lap_time = 0.0
		
func _on_set_max_off_track_time(max_time: float) -> void:
	max_off_track_time = max_time
	# Optional: Update the label immediately if needed
	if timer_label:
		timer_label.text = "%.1f" % max_off_track_time
		
#region Exceeding Track Limits
func _on_wheels_left_track(car: Car) -> void:
	if car.is_in_group("player"):
		_beep_timer = 0.0
		_start_off_track_animation()
		_start_off_track_timer()

func _on_wheels_returned_to_track(car: Car) -> void:
	if car.is_in_group("player"):
		_beep_timer = 0.0
		_stop_off_track_animation()
		_stop_off_track_timer()
		
func _start_off_track_animation() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	
	red_rect_flashing.modulate.a = 0.0
	red_rect_flashing.show()
	
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(red_rect_flashing, "modulate:a", 0.85, 0.3)
	_pulse_tween.tween_callback(_create_pulse_loop)

func _create_pulse_loop() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(red_rect_flashing, "modulate:a", 0.85, 0.45)
	_pulse_tween.tween_property(red_rect_flashing, "modulate:a", 0.4, 0.45)

func _stop_off_track_animation() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(red_rect_flashing, "modulate:a", 0.0, 0.3)
	fade_out_tween.tween_callback(func(): red_rect_flashing.hide())

func _start_off_track_timer() -> void:
	if _player_car:
		var remaining_time = max_off_track_time - _player_car.off_track_time
		update_timer_label(remaining_time)
	timer_label.show()
	text_label.show()
	beep.play()

func _stop_off_track_timer() -> void:
	timer_label.hide()
	text_label.hide()

func update_timer_label(remaining_time: float) -> void:
	timer_label.text = "%.1f" % max(0.0, remaining_time)
	
#endregion

#region Buttons

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused and not pause_menu_container.visible and not raceover_table.visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if raceover_table.visible:
			get_tree().paused = false
			GameManager.change_to_main()
		else:
			_toggle_pause()
		
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()

func _toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		pause_menu_container.show()
	else:
		pause_menu_container.hide()

func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_restart_pressed() -> void:
	_toggle_pause()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	_toggle_pause()
	GameManager.change_to_main()
#endregion
