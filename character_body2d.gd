extends CharacterBody2D
class_name King
@export var speed: int = 200
@onready var animation_king: AnimationPlayer = $AnimationPlayer
@onready var camera=$Camera2D
var movable=true


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
