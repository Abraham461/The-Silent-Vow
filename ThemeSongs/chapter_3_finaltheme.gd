extends AudioStreamPlayer

var level_music = preload("res://ThemeSongs/Broken_Hearts_Sad_Violin__Original_Composition_(256k).mp3")

# volume_db is decibels (0 is normal). Use negative values to reduce volume.
func _play_music(music: AudioStream, volume_db_val: float = 0.0) -> void:
	if stream == music and playing:
		return

	stop()               # stop whatever was playing on this player
	stream = music       # ASSIGN the stream (not ==)
	volume_db = volume_db_val
	play()

func _play_music_level() -> void:
	_play_music(level_music, -6.0)  # example -6 dB

func _ready() -> void:
	autoplay = false  # ensure the inspector autoplay off too
