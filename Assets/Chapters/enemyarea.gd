extends Area2D

@export var dialogue_start: String = "start5"
@export var dialogue_resource: DialogueResource
var has_triggered := false


var stream = preload("res://ThemeSongs/Action 3.ogg")



# internal
var _triggering_player: Node = null
var _dm = null
@onready var running: AudioStreamPlayer = $"../../CharacterBody2D/running"

func _ready() -> void:
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	_dm = _find_dialogue_manager()
func _find_dialogue_manager():
	# Try to get the DialogueManager singleton, fall back to root lookup
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	if get_tree().get_root().has_node("DialogueManager"):
		return get_tree().get_root().get_node("DialogueManager")
	return null

func _on_body_entered(body: Node) -> void:

	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		_triggering_player = body
		print("Triggering dialogue!")

		# freeze player
		_triggering_player.is_frozen = true

		# connect to dialogue end (avoid double connect)
		if _dm:
			if not _dm.is_connected("dialogue_ended", Callable(self, "_on_dialogue_ended")):
				_dm.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

		# show dialogue balloon
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)

		# if no dialogue resource was provided, clean up immediately
		if not dialogue_resource:
			_cleanup_after_dialogue()

func _on_dialogue_ended(resource: DialogueResource) -> void:
	# Only act if the ended dialogue is the one we started
	if resource != dialogue_resource:
		return

	_cleanup_after_dialogue()

func _cleanup_after_dialogue() -> void:
	# Unfreeze player
	if _triggering_player:
		_triggering_player.is_frozen = false
		_triggering_player = null

	# Stop boss music and resume main theme
	#if boss_theme and boss_theme.playing:
		#boss_theme.stop()
	## optional: fade-out with a Tween instead of instant stop (uncomment to use)
	## var t = get_tree().create_tween()
	## t.tween_property(boss_theme, "volume_db", -80, 1.0).as_async()
	## await t.finished
#
	#if main_theme_song:
		## restart main theme if you want it to continue
		#if not main_theme_song.playing:
			#main_theme_song.play()

	# disconnect signal so next trigger works cleanly
	if _dm and _dm.is_connected("dialogue_ended", Callable(self, "_on_dialogue_ended")):
		_dm.disconnect("dialogue_ended", Callable(self, "_on_dialogue_ended"))
