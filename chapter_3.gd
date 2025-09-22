extends Node2D
@onready var portal: AnimatedSprite2D = $AnimatedSprite2D



func _ready():
	portal.play("default")
	
