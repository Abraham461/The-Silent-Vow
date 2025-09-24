extends Control

@export var credits_file: String = "res://credits.json"
@export var scroll_speed: float = 50.0   # pixels per second
@export var autodismiss_scene: String = "res://Main_menu/menu/Main_Menu.tscn"   # optional: scene to go to when finished
@onready var rt: RichTextLabel = $credits_label

var scroll_pos: float
var base_speed: float

func _ready() -> void:
	base_speed = scroll_speed

	var data = _load_credits_json(credits_file)
	if data == null:
		push_error("Credits: failed to load file: %s" % credits_file)
		return

	# Build BBCode text
	var lines := []
	for section in data:
		lines.append("[center][b]" + section.get("title", "") + "[/b][/center]")
		for item in section.get("items", []):
			lines.append(item)
		lines.append("") # blank line between sections

	rt.bbcode_enabled = true
	rt.bbcode_text = "\n".join(lines)

	# Start the label just below the visible viewport
	var viewport_h = get_viewport_rect().size.y
	scroll_pos = viewport_h
	rt.position = Vector2(rt.position.x, scroll_pos)

	# Warn if label is inside a Container
	if _is_inside_container(rt):
		push_warning("'CreditsLabel' is inside a Container. Container may override manual position.")

	set_process(true)

func _process(delta: float) -> void:
	# Move up
	scroll_pos -= scroll_speed * delta
	rt.position = Vector2(rt.position.x, scroll_pos)

	# Finish when text fully scrolled past the top
	var content_h = rt.get_combined_minimum_size().y
	if scroll_pos + content_h < 0:
		_finish()

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			scroll_speed = base_speed * 3.0
		elif event.keycode == KEY_ESCAPE:
			_finish()
	if event is InputEventKey and not event.pressed:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			scroll_speed = base_speed

func _finish() -> void:
	set_process(false)
	if autodismiss_scene != "":
		var err = get_tree().change_scene_to_file(autodismiss_scene)
		if err != OK:
			push_error("Credits: failed to change scene to '%s'" % autodismiss_scene)
	else:
		print("Credits finished.")
	Chapter3Finaltheme.stop()
func _load_credits_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var content = FileAccess.get_file_as_string(path)
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		push_error("JSON parse error: %s" % err)
		return null
	return json.data

func _is_inside_container(n: Node) -> bool:
	var parent = n.get_parent()
	while parent:
		if parent is Container:
			return true
		parent = parent.get_parent()
	return false
