extends Area2D
@export var dialogue_start: String = "start2"
@export var dialogue_resource: DialogueResource
var has_triggered := false

func _ready() -> void:
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		print("Triggering dialogue!")
		# freeze player
		body.is_frozen = true
# show dialogue
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)

		# wait until dialogue balloon node disappears
		# wait for fixed duration before unfreezing
		var dialogue_duration = 9 # adjust to match dialogue length
		await get_tree().create_timer(dialogue_duration).timeout

		# unfreeze player
		body.is_frozen = false
