#extends AudioStreamPlayer
#
#
#var level_music = preload("res://ThemeSongs/Epic_War_Drums_-_Music_for_D_D(256k).mp3")
#
#func _play_musi(music: AudioStream, volume = 100.0):
	#if stream == music:
		#return 
	#
	#stream == music
	#volume_db = volume
	#play()
	#
#func _play_music_level():
	#_play_musi(level_music)
	#
#
#func _ready():
	#level_music.loop = true
extends AudioStreamPlayer

var level_music = preload("res://ThemeSongs/Epic_War_Drums_-_Music_for_D_D(256k).mp3")

# volume_db is decibels (0 is normal). Use negative values to reduce volume.
func _play_music(music: AudioStream, volume_db_val: float = 0.0) -> void:
	if stream == music and playing:
		return

	stop()               # stop whatever was playing on this player
	stream = music       # ASSIGN the stream (not ==)
	volume_db = volume_db_val
	play()

func _play_music_level() -> void:
	_play_music(level_music, -15.0)  # example -6 dB

func _ready() -> void:
	autoplay = false  # ensure the inspector autoplay off too
