# Autoload.gd
extends Node

# Which actions should remain allowed while we block everything else
const ALLOWED_ACTIONS: Array = ["space_only", "ui_accept"]

var enabled: bool = true                   # when true: normal input flow
var _saved_inputmap: Dictionary = {}       # only stores actions we erase: action_name -> Array[InputEvent]

func _ready() -> void:
	set_process_input(true)
	print("[Autoload] ready; enabled =", enabled)

func _input(event: InputEvent) -> void:
	# If input isn't blocked, do nothing
	if enabled:
		return

	# Allow Space even if InputMap entries exist (works across keyboards)
	if event is InputEventKey:
		# unicode 32 is space character
		if event.unicode == 32:
			return

	# Allow any whitelisted actions (use InputMap.event_is_action so it works for mouse/gamepad too)
	for a in ALLOWED_ACTIONS:
		if InputMap.event_is_action(event, a):
			return

	# Block everything else
	get_tree().root.set_input_as_handled()


# --- InputMap-based disabling (disables action polling too) ---

func disable_action_map() -> void:
	# Guard: if we've already saved a snapshot, don't overwrite it
	if not _saved_inputmap.is_empty():
		return
	_saved_inputmap.clear()

	# Only save & erase actions that are NOT in the allowed list
	var actions = InputMap.get_actions()
	for action in actions:
		if action in ALLOWED_ACTIONS:
			continue
		var events: Array = InputMap.action_get_events(action)
		if events.size() > 0:
			_saved_inputmap[action] = events.duplicate(true)
			InputMap.action_erase_events(action)

	print("[Autoload] InputMap cleared for non-whitelisted actions; saved", _saved_inputmap.keys())

func restore_action_map() -> void:
	for action in _saved_inputmap.keys():
		var events: Array = _saved_inputmap[action]
		for ev in events:
			InputMap.action_add_event(action, ev)
	_saved_inputmap.clear()
	print("[Autoload] InputMap restored")

func block_all_except_space() -> void:
	enabled = false
	disable_action_map()

func restore_all_input() -> void:
	restore_action_map()
	enabled = true

		#AutoLoad.block_all_except_space()   # block everything except Space
		#AutoLoad.restore_all_input()
