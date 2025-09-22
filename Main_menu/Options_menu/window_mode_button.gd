extends Control

@onready var option_button: OptionButton = $HBoxContainer/OptionButton 

const WINDOW_MODE_ARRAY : Array[String] = [
	"Full-Screen",
	"Window Mode",
	"Borderless Window",
	"Borderless Full-Screen"
]

func _ready():
	add_window_mode_items()
	option_button.item_selected.connect(on_window_mode_selected)
	
func add_window_mode_items() -> void:
	for window_items in WINDOW_MODE_ARRAY:
		option_button.add_item(window_items)

func on_window_mode_selected(index : int) -> void:
	match index:
		0: #FullScreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: #windowMode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: #borderlessWindow
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		3: #borelessFullScreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
