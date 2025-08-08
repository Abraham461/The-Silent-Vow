extends CanvasLayer

const CHAR_READ_RATE = 0.05

@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/HBoxContainer/start
@onready var end_symbol = $TextboxContainer/MarginContainer/HBoxContainer/end
@onready var label = $TextboxContainer/MarginContainer/HBoxContainer/Label2
@onready var image_rect = $CutsceneImage 
#@onready var bgm_player = $BGMPlayer
@onready var sfx_player = $SeffPlayer
@onready var sfx_timer = $SFXTimer
@onready var tween = get_tree().create_tween()



enum  State {
	READY,
	READING,
	FINISHED
}

var current_state = State.READY
var image_queue = []
var text_queue = []


# preload all six images (make sure the paths match your project)
var textures = [
	preload("res://more cutscene/image/a_land_proteceted_by_magic.jpg"),
	preload("res://more cutscene/image/darkforest.png"),
	preload("res://more cutscene/image/knight_entering.png")
]

var sfx_map = {
	1: preload("res://more cutscene/soundeff/nosoundeff.ogg")
}

func _ready():
	print("Starting state: State.READY")
	if has_node("BGMPlayer"):
		$BGMPlayer.stop()
	#bgm_player.play()  
	hide_textbox()
	queue_text("Beyond the last watchtower of Eirenwald lies Fyrwood, a land once protected by ancient magic.")
	queue_image(textures[0])
	queue_text("The trees are blackened, the air is thick, and sunlight almost never reaches the ground. People now call it the Forest of the Forsaken. No one who enters ever returns. ")
	queue_image(textures[1])
	queue_text("But if Zakcoff is to reach Blackreach Keep, he must pass through it. ")
	queue_image(textures[2])

	
func _process(_delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("ui_accept"):
				tween.kill()
				label.visible_characters = -1
				end_symbol.text = "<-"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				hide_textbox()

func queue_text (next_text):
	text_queue.push_back(next_text)
func queue_image(tex: Texture) -> void:
	image_queue.append(tex)


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
	var next_img = image_queue.pop_front()
	var next_text = text_queue.pop_front()
	sfx_player.play() 
	image_rect.texture = next_img
	 # Determine which texture this is by checking how many are left
	var current_index = textures.size() - image_queue.size() - 1
	if sfx_map.has(current_index):
		sfx_player.stream = sfx_map[current_index]
		sfx_player.play()
		if current_index == 1:
			sfx_player.volume_db = -12
	tween = get_tree().create_tween()
	label.text = next_text
	change_state(State.READING)
	show_textbox()
	tween.tween_property(
		label,
		"visible_characters",
		next_text.length(),
		next_text.length() * CHAR_READ_RATE
		).from(0)
	tween.connect("finished", Callable(self, "on_tween_finished"))
	end_symbol.text = "..."

func _on_SFXTimer_timeout():
	sfx_player.stop()
	
func on_tween_finished():
	end_symbol.text = "<-"
	change_state(State.FINISHED)
func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			print("Changing state to: State.READY")
		State.READING:
			print("Changing state to: State.READING")
		State.FINISHED:
			print("Changing state to: State.FINISHED")
			
