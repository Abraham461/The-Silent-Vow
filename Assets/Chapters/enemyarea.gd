extends Area2D

@onready var text_box = $"../CanvasLayer/TextBox"  # adjust path

func _on_area_entered(body):
	if body.is_in_group("player"):
		text_box.enqueue_message("Hello, traveler! This is a simple textbox.")
