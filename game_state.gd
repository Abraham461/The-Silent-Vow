extends Node

# Global performance/optimization manager
var frame_smoothing := true
var max_fps := 60
var vsync_enabled := true

func _ready():
	# Apply global framerate/VSYNC settings
	Engine.max_fps = max_fps
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	if frame_smoothing:
		Engine.physics_ticks_per_second = 60
		Engine.time_scale = 1.0
	else:
		Engine.physics_ticks_per_second = 120


# Called when the node enters the scene tree for the first time.
var spawn_point_name: String = "Start"
