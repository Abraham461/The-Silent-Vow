
extends Area2D

@export var value: int = 1

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":  #check it's the player
		print(value)
		hide()  # Hide instead of deleting
