extends PanelContainer
class_name TrackSelector

const DEFAULT_COLOR: Color = Color("540000c8")
const HIGHLIGHT_COLOR: Color = Color("7e0000c8")

@export var track_info: TrackInfo

@onready var highlight: ColorRect = $Highlight
@onready var track_label: Label = $MC/TrackLabel
@onready var bg_img: TextureRect = $BgImg
@onready var track_preview_img: TextureRect = $MC/TrackPreviewImg


func _ready() -> void:
	highlight.color = DEFAULT_COLOR
	bg_img.texture = track_info.bg_image
	track_preview_img.texture = track_info.track_preview
	track_label.text = track_info.track_name


func _on_mouse_entered() -> void:
	highlight.color = HIGHLIGHT_COLOR


func _on_mouse_exited() -> void:
	highlight.color = DEFAULT_COLOR


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Select"):
		GameManager.change_to_track(track_info)
