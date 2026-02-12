extends RaceController
class_name TimeTrialController

@export var ghost_car_scene: PackedScene

var ghost_recorder: GhostRecorder
var ghost_car_instance: GhostCar
var player_car: Car

func setup(cars: Array[Car], p_track_curve: Curve2D) -> void:
	super.setup(cars, p_track_curve)
	
	# find player car
	for c in cars:
		if c.is_in_group("player"):
			player_car = c
			break
			
	if player_car:
		# setup recorder
		ghost_recorder = GhostRecorder.new()
		add_child(ghost_recorder)
		ghost_recorder.setup(player_car)
		ghost_recorder.on_best_lap_beaten.connect(_on_new_best_ghost)
		
		#  setup ghost car
		if ghost_car_scene:
			ghost_car_instance = ghost_car_scene.instantiate()
			add_child(ghost_car_instance)
			ghost_car_instance.setup_visuals()
			ghost_car_instance.hide() 

func on_lap_completed(info: LapCompleteData) -> void:
	super.on_lap_completed(info)
	
	if info.car == player_car:
		ghost_recorder.finish_lap(info.lap_time)
		var best_ghost = ghost_recorder.get_best_ghost()
		
		if ghost_car_instance == null:
			print(" Ghost Car Instance missing!")
		elif best_ghost == null:
			print("No ghost data found!")
		else:
			print("Starting ghost replay!")
			ghost_car_instance.show()
			ghost_car_instance.start_replay(best_ghost)

func on_race_start() -> void:
	super.on_race_start()
	
	# start recording
	if ghost_recorder:
		ghost_recorder.start_new_lap()

func _on_new_best_ghost(_data: GhostData) -> void:
	pass
