extends ColorRect

@export var default_darkness: float = 0.7
@export var dim_time: float = 0.15
@export var hold_time: float = 1.0
@export var expand_time: float = 1.2
@export var initial_spot_radius_px: float = 48.0
@export var spot_feather_px: float = 60.0

func _ready() -> void:
	visible = false
	# Make this node process while the tree is paused
	self.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Duplicate material so we modify an instance (avoid changing resource in Inspector)
	if material and material is ShaderMaterial:
		material = material.duplicate()
	else:
		push_error("Dimmer._ready: Please assign a ShaderMaterial (with the correct shader) to this ColorRect.")
	if material and material is ShaderMaterial:
		material.set_shader_parameter("u_darkness", 0.0)
		material.set_shader_parameter("u_radius_uv", 0.0)
		material.set_shader_parameter("u_spot_enabled", 0)
		material.set_shader_parameter("u_feather_uv", _px_to_uv_radius(spot_feather_px))
	mouse_filter = Control.MOUSE_FILTER_STOP

func _world_to_uv(world_pos: Vector2) -> Vector2:
	var rect := get_viewport().get_visible_rect()
	var view_size: Vector2 = rect.size
	if view_size.x == 0 or view_size.y == 0:
		return Vector2(0.5, 0.5)
	var cam := get_viewport().get_camera_2d()
	if cam:
		var screen_center := view_size * 0.5
		var screen_pos := (world_pos - cam.global_position) * cam.zoom + screen_center
		return Vector2(screen_pos.x / view_size.x, screen_pos.y / view_size.y)
	else:
		var screen_pos := world_pos - rect.position
		return Vector2(screen_pos.x / view_size.x, screen_pos.y / view_size.y)

func _px_to_uv_radius(px: float) -> float:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var max_dim: float = max(view_size.x, view_size.y)
	if max_dim == 0.0:
		return 0.0
	return px / max_dim

# DEBUG helper: print shader parameters (useful to check values)
func _print_params(tag: String = "") -> void:
	if material and material is ShaderMaterial:
		print("Dimmer PARAMS", tag, "u_darkness=", material.get_shader_parameter("u_darkness"),
			  " u_radius_uv=", material.get_shader_parameter("u_radius_uv"),
			  " u_center_uv=", material.get_shader_parameter("u_center_uv"))

func freeze_dim_spot_sequence(target: Node2D, darkness: float = -1.0) -> void:
	if darkness < 0.0:
		darkness = default_darkness

	# ensure material present
	if not (material and material is ShaderMaterial):
		push_error("Dimmer.freeze_dim_spot_sequence: no ShaderMaterial on Dimmer. Aborting and unpausing.")
		get_tree().paused = false
		visible = false
		return

	# Pause the game (this node will still process because WHEN_PAUSED)
	print("Dimmer: sequence START - pausing tree")
	get_tree().paused = true

	visible = true
	material.set_shader_parameter("u_spot_enabled", 0)
	material.set_shader_parameter("u_radius_uv", 0.0)
	material.set_shader_parameter("u_darkness", 0.0)
	_print_params("after reset")

	# 1) quick dim
	print("Dimmer: tween -> dim to", darkness)
	var tw := create_tween()
	tw.tween_property(material, "shader_param/u_darkness", darkness, dim_time)
	await tw.finished
	print("Dimmer: dim finished")
	_print_params("after dim")

	# 2) hold using tween_interval (works while WHEN_PAUSED)
	print("Dimmer: hold for", hold_time, "seconds (tween_interval)")
	var tw_hold := create_tween()
	tw_hold.tween_interval(hold_time)
	await tw_hold.finished
	print("Dimmer: hold finished")

	# 3) prepare spotlight
	if not is_instance_valid(target):
		push_error("Dimmer: target invalid. Unpausing and aborting.")
		visible = false
		get_tree().paused = false
		return

	var center_uv: Vector2 = _world_to_uv(target.global_position)
	material.set_shader_parameter("u_center_uv", center_uv)
	material.set_shader_parameter("u_spot_enabled", 1)
	var start_radius_uv: float = _px_to_uv_radius(initial_spot_radius_px)
	var feather_uv: float = _px_to_uv_radius(spot_feather_px)
	material.set_shader_parameter("u_radius_uv", start_radius_uv)
	material.set_shader_parameter("u_feather_uv", feather_uv)
	print("Dimmer: spotlight prepared center_uv=", center_uv, "start_radius_uv=", start_radius_uv)
	_print_params("before expand")

	# 4) expand and fade darkness to 0
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var max_diag_px: float = max(view_size.x, view_size.y) * 1.6
	var max_radius_uv: float = _px_to_uv_radius(max_diag_px)
	var tw2 := create_tween()
	tw2.tween_property(material, "shader_param/u_radius_uv", max_radius_uv, expand_time)
	tw2.tween_property(material, "shader_param/u_darkness", 0.0, expand_time)
	print("Dimmer: expanding to", max_radius_uv, "over", expand_time, "s")
	await tw2.finished

	print("Dimmer: expand finished, unpausing tree")
	visible = false
	get_tree().paused = false
