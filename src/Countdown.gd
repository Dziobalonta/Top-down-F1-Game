extends Control
class_name Countdown

@export var wait_time: float = 1.0

@onready var label: Label = $Label
@onready var timer: Timer = $Timer
@onready var beep: AudioStreamPlayer = $Beep

var started: bool = false
var count: int = 3

func _ready() -> void:
	hide()
	update_label()
	timer.wait_time = wait_time
	start_race()

func update_label() -> void: label.text = "%d" % count
	
func start_race() -> void:
	beep.play()
	show()
	started = true
	timer.start()

func _on_timer_timeout() -> void:
	count -= 1
	if count == 0:
		EventHub.emit_on_race_start() # actual race start
		queue_free() # Deletes the timer
	else:
		beep.play()
		update_label()
		
