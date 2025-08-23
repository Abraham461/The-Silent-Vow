extends CanvasLayer

const CHAR_READ_RATE = 0.05

@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/end
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var tween = get_tree().create_tween()

enum State { READY, READING, FINISHED }
var current_state = State.READY
var text_queue: Array[String] = []  # <-- initialized with your message

func _ready():
	hide_textbox()
	if text_queue.size() > 0:
		display_text()

# Call this from collision trigger
func enqueue_message(text: String):
	text_queue.append(text)
	if current_state == State.READY:
		display_text()

func _process(_delta):
	match current_state:
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				tween.kill()
				label.visible_characters = -1
				end_symbol.text = "<-"
				change_state(State.FINISHED)

		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				hide_textbox()
				change_state(State.READY)
				if text_queue.size() > 0:
					display_text()

# --- Helpers ---
func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	textbox_container.hide()

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	var next_text = text_queue.pop_front()
	label.text = next_text
	show_textbox()
	change_state(State.READING)

	# Animate text
	tween = get_tree().create_tween()
	tween.tween_property(
		label,
		"visible_characters",
		next_text.length(),
		next_text.length() * CHAR_READ_RATE
	).from(0)
	tween.connect("finished", Callable(self, "_on_tween_finished"))
	end_symbol.text = "..."

func _on_tween_finished():
	end_symbol.text = "<-"
	change_state(State.FINISHED)

func change_state(new_state):
	current_state = new_state
