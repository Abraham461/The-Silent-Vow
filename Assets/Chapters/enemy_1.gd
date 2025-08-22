extends CharacterBody2D

@onready var anim: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var player = get_node("./Player")   # adjust path if different

func _ready():
	global_position = Vector2(112, 530)
	anim.play("Idle")

func _process(delta):
	if player == null:
		return   # avoid null crash
	
	var dist = global_position.distance_to(player.global_position)
	if dist < 100:
		anim.play("Atk1")
	else:
		anim.play("Idle")
