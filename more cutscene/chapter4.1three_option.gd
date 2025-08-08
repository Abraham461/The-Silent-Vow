extends CanvasLayer

const CHAR_READ_RATE = 0.05

enum State {
	SHOW_CUTSCENE,
	AWAIT_INPUT,
	SHOW_CHOICES
}

@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/end
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var image_rect = $CutsceneImage
@onready var options_container = $TextboxContainer/MarginContainer/HBoxContainer2/OptionsContainer
@onready var option_a = $TextboxContainer/MarginContainer/HBoxContainer2/OptionsContainer/OptionA
@onready var option_b = $TextboxContainer/MarginContainer/HBoxContainer2/OptionsContainer/OptionB
@onready var option_c = $TextboxContainer/MarginContainer/HBoxContainer2/OptionsContainer/OptionC
@onready var bgm_player = $BGMPlayer
@onready var sfx_player = $SFXPlayer
@onready var sfx_timer = $SFXTimer
@onready var hbox_container = $TextboxContainer/MarginContainer/HBoxContainer

var current_state = State.SHOW_CUTSCENE
var image_queue = []
var text_queue = []
var tween = null

# Preload scene images
var textures = [
	preload("res://more cutscene/image/peacefulkingdom.jpg"),

]

func _ready():
	bgm_player.stop()
	hide_textbox()
	enqueue_cutscenes()

func enqueue_cutscenes():
	# Add text and image pairs in order
	queue_pair("Choose Elira path:", textures[0])

func queue_pair(text: String, img: Texture) -> void:
	text_queue.append(text)
	image_queue.append(img)
func _process(_delta):
	match current_state:
		State.SHOW_CUTSCENE:
			if text_queue.size() > 0:
				display_text()
			elif text_queue.empty():
				show_choices()

		State.AWAIT_INPUT:
			if Input.is_action_just_pressed("ui_accept"):
				tween.kill()
				label.visible_characters = -1
				end_symbol.text = "<-"
				current_state = State.SHOW_CHOICES
				show_choices()    # ← call immediately, so buttons appear right after you press Accept

		State.SHOW_CHOICES:
			# waiting for button presses
			pass

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	var next_text = text_queue.pop_front()
	var next_img = image_queue.pop_front()
	image_rect.texture = next_img
	label.text = next_text
	show_textbox()
	current_state = State.AWAIT_INPUT
	tween = get_tree().create_tween()
	tween.tween_property(label, "visible_characters", next_text.length(), next_text.length() * CHAR_READ_RATE).from(0)
	tween.connect("finished", Callable(self, "_on_text_finished"))
	end_symbol.text = "..."

func _on_text_finished():
	end_symbol.text = "<-"
	
func show_choices():

	show_textbox()

# 1) Hide & ignore the old text row so it no longer blocks clicks
	var old_row = $TextboxContainer/MarginContainer/HBoxContainer
	old_row.visible = false
	old_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
# 2) Allow clicks to pass through the textbox container and its margin
	textbox_container.mouse_filter = Control.MOUSE_FILTER_PASS
	$TextboxContainer/MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS

# 3) Prompt text
	start_symbol.text = "*"
	end_symbol.text = ""
	label.text = "Choose your path:"

# 4) Show & raise the options container so it’s on top
	options_container.show()
	options_container.z_index = 1

	options_container.z_as_relative = false
	var parent = options_container.get_parent()
	parent.move_child(options_container, parent.get_child_count() - 1)
	options_container.mouse_filter = Control.MOUSE_FILTER_PASS

# 5) Let the background image pass clicks through
	image_rect.mouse_filter = Control.MOUSE_FILTER_PASS

# 6) Configure each button to catch its own clicks
	for btn in [ option_a, option_b, option_c ]:
	
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.disabled = false
		btn.focus_mode = Control.FOCUS_ALL
	
		var cb = Callable(self, "_on_%s_pressed" % btn.name)
		if not btn.is_connected("pressed", cb):
			btn.connect("pressed", cb)

		current_state = State.SHOW_CHOICES


func _on_OptionA_pressed():
	get_tree().change_scene_to_file("res://more cutscene/OptionA.tscn" )

func _on_OptionB_pressed():
	get_tree().change_scene_to_file("res://more cutscene/OptionB.tscn")

func _on_OptionC_pressed():
	get_tree().change_scene_to_file("res://more cutscene/OptionC.tscn")

func hide_textbox():
	if textbox_container:
		textbox_container.hide()
	if options_container:
		options_container.hide()
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	image_rect.texture = null
