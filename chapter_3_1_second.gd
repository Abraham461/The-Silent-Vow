extends Node2D
@onready var boss: AnimatedSprite2D = $CharacterBody2D2/AnimatedSprite2D
#@onready var princess: AnimatedSprite2D = $CharacterBody2D3/AnimatedSprite2D
#@onready var princess: AnimatedSprite2D = $CharacterBody2D3/AnimatedSprite2D
@onready var princess: AnimatedSprite2D = $Princess/AnimatedSprite2D
@onready var barrier: AnimatedSprite2D = $barrier
@onready var holyaura: AnimatedSprite2D = $holyaura



func _ready() -> void:
	#boss.play("FinalbossAtk")
	princess.play("cover")
	barrier.play("default")
	holyaura.play("default")
	Chapter3Bosstheme._play_music_level()
