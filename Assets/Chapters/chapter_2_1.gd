extends Node2D
@onready var player = $CharacterBody2D
@onready var anim: AnimatedSprite2D = $enemy1/AnimatedSprite2D
@onready var animgate: AnimatedSprite2D = $AnimatedSprite2D
@onready var holyaura: AnimatedSprite2D = $holyaura
@onready var smoe: AnimatedSprite2D = $smoe
@onready var crow: AnimatedSprite2D = $crow/AnimatedSprite2D
@onready var devilanim: AnimatedSprite2D = $enemydevil/AnimatedSprite2D
var devildeath := false
# Called when the node enters the scene tree for the first time.
func _ready():
	var spawn_name = GameState.spawn_point_name
	var spawn_position = $SpawnPoints.get_node(spawn_name).global_position
	$CharacterBody2D.global_position = spawn_position
	anim.play("modIdle")
	animgate.play("gate")
	holyaura.play("fire")
	smoe.play("smoke")
	crow.play("crowidle")
	if not devildeath:
		devilanim.play("devilidle")
