extends Node2D
@onready var boss: AnimatedSprite2D = $CharacterBody2D2/AnimatedSprite2D
#@onready var princess: AnimatedSprite2D = $CharacterBody2D3/AnimatedSprite2D
#@onready var princess: AnimatedSprite2D = $CharacterBody2D3/AnimatedSprite2D
#@onready var princess: AnimatedSprite2D = $Princess/AnimatedSprite2D
@onready var princess: AnimatedSprite2D = $CharacterBody2D3/AnimatedSprite2D



func _ready() -> void:
	#boss.play("FinalbossAtk")
	princess.play("princessidle")
	Chapter3Bosstheme._play_music_level()
