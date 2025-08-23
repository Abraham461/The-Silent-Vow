extends Node2D
@onready var player = $CharacterBody2D
@onready var anim: AnimatedSprite2D = $enemy1/AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var spawn_name = GameState.spawn_point_name
	var spawn_position = $SpawnPoints.get_node(spawn_name).global_position
	$CharacterBody2D.global_position = spawn_position
	anim.play("modIdle")
