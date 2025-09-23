#extends AudioStreamPlayer
#
#
#var level_music = preload("res://ThemeSongs/Epic_Slavic_Music_-_Gods_Awaken(256k).mp3")
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
#func _play_FX(stream: AudioStream, volume = 0.0):
	#var fx_player = AudioStreamPlayer.new()
	#fx_player.stream = stream
	#fx_player.name = "FX_PLAYER"
	#fx_player.volume_db = volume
	#add_child(fx_player)
	#fx_player.play()
	#
	#await fx_player.finished
	#fx_player.queue_free()
	
extends AudioStreamPlayer

var level_music = preload("res://ThemeSongs/Epic_Slavic_Music_-_Gods_Awaken(256k).mp3")

# volume_db is decibels (0 is normal). Use negative values to reduce volume.
func _play_music(music: AudioStream, volume_db_val: float = 0.0) -> void:
	if stream == music and playing:
		return

	stop()               # stop whatever was playing on this player
	stream = music       # ASSIGN the stream (not ==)
	volume_db = volume_db_val
	play()

func _play_music_level() -> void:
	_play_music(level_music, -9.0)  # example -6 dB

func _ready() -> void:
	autoplay = false  # ensure the inspector autoplay off too
