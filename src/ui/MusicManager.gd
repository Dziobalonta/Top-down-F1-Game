extends Node

static var MAIN_MUSIC: String = "res://assets/audio/music/Drive-Fast.wav"

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# created only once
	if not music_player.get_parent():
		add_child(music_player)
		music_player.bus = "Music"
	
	play_menu_track()

func play_menu_track():
	var new_stream = load(MAIN_MUSIC)
	
	# Stop current music
	if music_player.playing:
		music_player.stop()
	
	music_player.stream = new_stream
	music_player.volume_db = -30
	music_player.play(0.0) # Start from begining

func stop_menu_track():
	if music_player.playing:
		music_player.stop()
