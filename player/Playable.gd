extends Node2D

@onready var player = $Player

var scene_changed := false
#const NEXT_SCENE := "res://more cutscene/cuts_second.tscn"
var dialogue_active: bool = false

func _ready():
	# connect the ExitRight Area2D if present
	if has_node("ExitRight"):
		var exit_area: Area2D = $ExitRight
		exit_area.connect("body_entered", Callable(self, "_on_exit_area_body_entered"))
	else:
		push_warning("ExitRight Area2D not found. Add an Area2D named 'ExitRight' as a child of this node.")

	# hook DialogueManager signals (DM3)
	if Engine.has_singleton("DialogueManager"):
		var dm = DialogueManager
		if dm.has_signal("dialogue_started"):
			dm.dialogue_started.connect(Callable(self, "_on_dialogue_started"))
		# DM3 uses either 'dialogue_finished' or 'dialogue_ended' depending on version
		if dm.has_signal("dialogue_finished"):
			dm.dialogue_finished.connect(Callable(self, "_on_dialogue_finished"))
		if dm.has_signal("dialogue_ended"):
			dm.dialogue_ended.connect(Callable(self, "_on_dialogue_finished"))
	else:
		push_warning("DialogueManager singleton not found. Enable the plugin/autoload.")

func _on_exit_area_body_entered(body: Node):
	if scene_changed:
		return

	# block scene change while dialogue is active
	if dialogue_active:
		print("Scene change blocked: dialogue still active.")
		return

	# Prefer group check. Add the Player node to the 'player' group in the editor.
	#if body.is_in_group("player") or body.name == "Player":
		#scene_changed = true
		#get_tree().change_scene_to_file(NEXT_SCENE)

# === Dialogue signal handlers ===
func _on_dialogue_started(_res: Variant) -> void:
	dialogue_active = true
	# optional: freeze only the player while dialogue runs
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.set_process_input(false)

func _on_dialogue_finished(_res: Variant) -> void:
	dialogue_active = false
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process_input(true)
