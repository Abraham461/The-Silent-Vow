extends Area2D


@export var message_text: String = "The Forest of the Forsaken"
@export var display_time: float = 5.0  # seconds the label stays
var triggered = false
@onready var label = get_node("CanvasLayer/WelcomeSign")

func _on_body_entered(body: PhysicsBody2D):
	if body.name == "CharacterBody2D" and not triggered:
		triggered = true
		label.text = message_text
		label.visible = true
		# Start timer to hide it
		var timer = Timer.new()
		timer.wait_time = display_time
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_hide_label"))
		add_child(timer)
		timer.start()

func _hide_label():
	label.visible = false
