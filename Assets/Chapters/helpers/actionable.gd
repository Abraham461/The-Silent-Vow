extends Area2D
@export var dialogue_start: String = "start2"
@export var dialogue_resource: DialogueResource
var has_triggered := false
@onready var boss_theme: AudioStreamPlayer = $"../BossTheme"
var stream = preload("res://ThemeSongs/Action 3.ogg")
@onready var main_theme_song: AudioStreamPlayer = $"../../mainThemeSong"

func _ready() -> void:
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		print("Triggering dialogue!")
		# freeze player
		body.is_frozen = true
		main_theme_song.stop()
		stream.loop = true
		boss_theme.stream = stream
		boss_theme.play()
# show dialogue
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)

		# wait until dialogue balloon node disappears
		# wait for fixed duration before unfreezing
		var dialogue_duration = 9 # adjust to match dialogue length
		await get_tree().create_timer(dialogue_duration).timeout

		# unfreeze player
		body.is_frozen = false
