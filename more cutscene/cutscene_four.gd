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
	preload("res://more cutscene/image_cutscene_four/clearsky].jpg"),
	preload("res://more cutscene/image_cutscene_four/backtoEirenwald.jpg"),
	preload("res://more cutscene/image_cutscene_four/silent_room.png"),
	preload("res://more cutscene/image_cutscene_four/kingdeathONe.png"),
	preload("res://more cutscene/image_cutscene_four/princess_only.png"),
	preload("res://more cutscene//image_cutscene_four/kingdeath_princesspov.png"),
	preload("res://more cutscene/image_cutscene_four/marble_knight_statue.png")
]
  
# Optional sound effect map
var sfx_map = {
	1: preload("res://more cutscene/soundeff/nosoundeff.ogg"),
	2: preload("res://more cutscene/soundeff/lightning_sound_effect(256k).ogg"),
	3: preload("res://more cutscene/soundeff/House_Fire_Burning_Sound_Effect_-_Fire_Sound_Effect(256k).ogg"),
	4: preload("res://more cutscene/soundeff/nosoundeff.ogg")
}

func _ready():
	bgm_player.stop() #stop and play
	hide_textbox()
	enqueue_cutscenes()

func enqueue_cutscenes():
	# Add text and image pairs in order
	queue_pair("The Hollow Star has fallen. The monsters that once darkened the skies are gone. The silence has comes at a cost — and someone must carry the memory of it. ", textures[0])
	queue_pair("Elira returns to Eirenwald, bearing not only Zakcoff’s sword, but the weight of his sacrifice. Yet not all wounds heal with victory. In the court, in her heart, and in the people's eyes — she must decide who she will become.", textures[1])
	queue_pair("Elira rides through gates once lined with cheering villagers — now silent in mourning. The castle is darker, lonelier.", textures[2])
	queue_pair("King Solomon lies in bed, aged beyond his years. He opens his eyes as Elira enters. King Solomon: 'You… survived. The knight?'", textures[3])
	queue_pair("Elira: 'He kept his vow. Until the end.' ", textures[4])
	queue_pair(" King Solomon: 'Then he was a better man than I.' She says nothing. The king dies that night.", textures[5])
	queue_pair("A marble statue of Sir Zakcoff is placed in the royal garden, facing east — toward where the sun rises over the mountains. Only Elira and a handful of knights atend. She places his pendant and sword at the statue’s base.", textures[6])

func _process(_delta):
	match current_state:
		State.READY:
			if text_queue.size() > 0 and image_queue.size() > 0:
				display_text()
			elif text_queue.is_empty() and image_queue.is_empty():
				# Finished all entries → go to scene1.tscn
				get_tree().change_scene_to_file("res://more cutscene/chapter4.1three_option.tscn")
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
