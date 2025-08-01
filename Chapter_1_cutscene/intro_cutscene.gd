extends CanvasLayer
const CHAR_READ_RATE = 0.05

@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/end
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var image_rect = $CutsceneImage
@onready var bgm_player = $BGMPlayer
@onready var sfx_player = $SeffPlayer
@onready var sfx_timer = $SFXTimer
@onready var tween = get_tree().create_tween()
enum State {
	READY,
	READING,
	FINISHED
}

var current_state = State.READY
var image_queue = []
var text_queue = []

# Preload all images
var textures = [
	preload("res://Chapter_1_cutscene/image/peacefulkingdom.jpg"),
	preload("res://Chapter_1_cutscene/image/peacfulkingdomshattered.png"),
	preload("res://Chapter_1_cutscene/image/darkcastlelightning.png"),
	preload("res://Chapter_1_cutscene/image/villageburningimg.png"),
	preload("res://Chapter_1_cutscene/image/princesstakenaway.jpg"),
	preload("res://Chapter_1_cutscene/image/guardsdeath.png"),
	preload("res://Chapter_1_cutscene/image/king'ssummon.png")
]

# Optional sound effect map
var sfx_map = {
	1: preload("res://Chapter_1_cutscene/soundeff/glass_break_sound_effect(256k) 00_00_00-00_00_01.ogg"),
	2: preload("res://Chapter_1_cutscene/soundeff/lightning_sound_effect(256k).ogg"),
	3: preload("res://Chapter_1_cutscene/soundeff/House_Fire_Burning_Sound_Effect_-_Fire_Sound_Effect(256k).ogg"),
	4: preload("res://Chapter_1_cutscene/soundeff/nosoundeff.ogg")
}

func _ready():
	bgm_player.play()
	hide_textbox()
	enqueue_cutscenes()

func enqueue_cutscenes():
	# Add text and image pairs in order
	queue_pair("In the peaceful kingdom of Eirenwald, lush valleys and golden cites lived under calm skies. For decades, its people flourished under King Solomon the Wise, a ruler known for justce and peace. ", textures[0])
	queue_pair("But peace, like glass, shaters silently.", textures[1])
	queue_pair("One cool autumn morning, dark clouds gathered above the castle. Lightning cracked the sky though no storm had been forecast. The wind screamed like a warning. ", textures[2])
	queue_pair("From deep in the wildlands, strange monsters appeared—beasts with horns, flying creatures, and walking shadows. They atacked outer villages, destroying everything in their path. ", textures[3])
	queue_pair("Then, On the third night, they reached the capital. In the chaos, Princess Elira—the king’s only daughter—was taken from her tower while everyone slept. ", textures[4])
	queue_pair(" Her guards were found dead, their eyes frozen in fear.", textures[5])
	queue_pair(" In the throne room of Castle Liora, the aging King Solomon summoned his most trusted knight: Sir Zakcoff, a young but batle-scarred warrior raised in the royal court.", textures[6])

func _process(_delta):
	match current_state:
		State.READY:
			if text_queue.size() > 0 and image_queue.size() > 0:
				display_text()
			elif text_queue.is_empty() and image_queue.is_empty():
				# Finished all entries → go to scene1.tscn
				get_tree().change_scene_to_file("res://scene1.tscn")
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



# Helper to queue both text & image
func queue_pair(text: String, img: Texture) -> void:
	text_queue.append(text)
	image_queue.append(img)

func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	label.text = ""
	textbox_container.hide()
	image_rect.texture = null

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()

func display_text():
	# Pop next items
	var next_text = text_queue.pop_front()
	var next_img = image_queue.pop_front()
	# Set visuals
	image_rect.texture = next_img
	label.text = next_text
	show_textbox()
	change_state(State.READING)
	var idx = textures.find(next_img)
	if sfx_map.has(idx):
		sfx_player.stream = sfx_map[idx]
		sfx_player.play()
	# Animate text
	tween = get_tree().create_tween()
	tween.tween_property(
		label,
		"visible_characters",
		next_text.length(),
		next_text.length() * CHAR_READ_RATE
		).from(0)
	tween.connect("finished", Callable(self, "on_tween_finished"))
	end_symbol.text = "..."

func _on_tween_finished():
	end_symbol.text = "<-"
	change_state(State.FINISHED)

func _on_SFXTimer_timeout():
	sfx_player.stop()

func change_state(new_state):
	current_state = new_state
