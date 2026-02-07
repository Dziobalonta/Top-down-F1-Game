extends PanelContainer
class_name TrackSelector

const DEFAULT_COLOR: Color = Color("540000c8")
const HIGHLIGHT_COLOR: Color = Color("7e0000c8")

@export var track_info: TrackInfo

@onready var highlight: ColorRect = $Highlight
@onready var track_label: Label = $MC/TrackLabel
@onready var bg_img: TextureRect = $BgImg
@onready var track_preview_img: TextureRect = $MC/TrackPreviewImg
@onready var best_lap_label: Label = $MC/BestLapLabel


func _ready() -> void:
	highlight.color = DEFAULT_COLOR
	bg_img.texture = track_info.bg_image
	track_preview_img.texture = track_info.track_preview
	track_label.text = track_info.track_name
	
	var best_lap: float =GameManager.get_best_lap(track_info.track_name)
	if best_lap == CarRaceData.DEFAULT_LAPTIME:
		best_lap_label.text = "No best lap"
	else:
		best_lap_label.text = "Best %s" % format_time(best_lap)
		
func format_time(time_seconds: float) -> String:
	@warning_ignore("integer_division")
	var minutes: int = int(time_seconds) / 60
	var seconds: int = int(time_seconds) % 60
	var milliseconds: int = int((time_seconds - int(time_seconds)) * 100)
	
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]


func _on_mouse_entered() -> void:
	highlight.color = HIGHLIGHT_COLOR


func _on_mouse_exited() -> void:
	highlight.color = DEFAULT_COLOR


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Select"):
		GameManager.change_to_track(track_info)
