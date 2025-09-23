extends Node2D

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

func  _ready():

	video_stream_player.play()
	video_stream_player.finished.connect(on_finished)
	
func on_finished():
	get_tree().change_scene_to_file("res://Main_menu/menu/Main_Menu.tscn")
