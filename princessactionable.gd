extends Area2D

@export var dialogue_start: String = "start3"
@export var dialogue_resource: DialogueResource
var has_triggered := false
var _triggering_player: Node = null
var _dm = null
@onready var running: AudioStreamPlayer = $"../../CharacterBody2D/running"

var stream = preload("res://ThemeSongs/Action 3.ogg")
#@onready var boss_theme: AudioStreamPlayer = $"../../AudioStreamPlayer"
@onready var tween = get_tree().create_tween()

func _ready() -> void:
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	_dm = _find_dialogue_manager()

func _find_dialogue_manager():
	# DialogueManager registers itself as a singleton in its _ready.
	# Try Engine.get_singleton first, then fallback to /root node lookup.
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	# fallback: maybe it's an autoload named DialogueManager
	if get_tree().get_root().has_node("DialogueManager"):
		return get_tree().get_root().get_node("DialogueManager")
	return null

func _on_body_entered(body: Node) -> void:
	running.stop()
	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		_triggering_player = body
		print("Triggering dialogue!")
		# freeze player
		_triggering_player.is_frozen = true

		# start boss music

		# connect to dialogue end
		if _dm:
			# make sure we don't connect twice
			if not _dm.is_connected("dialogue_ended", Callable(self, "_on_dialogue_ended")):
				_dm.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

		# show dialogue balloon
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)

		# if there's no dialogue resource, change immediately (optional)
		if not dialogue_resource:
			_cleanup_and_change_scene()

func _on_dialogue_ended(resource: DialogueResource) -> void:
	# verify it's the dialogue we started (useful if multiple conversations exist)
	if resource != dialogue_resource:
		return

	_cleanup_and_change_scene()

func _cleanup_and_change_scene() -> void:
	# unfreeze player
	if _triggering_player:
		_triggering_player.is_frozen = false
		_triggering_player = null

	# stop boss music if desired or fade it with tween
	#if boss_theme.playing:
		# instant stop:
		#boss_theme.stop()
		# or fade out: uncomment and tune
		 #tween.tween_property(boss_theme, "volume_db", -80, 1.0)

	# disconnect signal to avoid duplicates next time
	if _dm and _dm.is_connected("dialogue_ended", Callable(self, "_on_dialogue_ended")):
		_dm.disconnect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

	# change scene
	get_tree().change_scene_to_file("res://chapter_3_1Second.tscn")
