extends Area2D


var entered = false
@onready var label = $CanvasLayer/Door1Label

func _on_body_entered(body: PhysicsBody2D):
	if body.name == "CharacterBody2D":
		entered = true
		label.text = "Press Enter to Exit the Cabin"


func _on_body_exited(body: PhysicsBody2D):
	if body.name == "CharacterBody2D":
		entered = false
		label.text = ""


func _physics_process(_delta):
	if entered == true:
		if Input.is_action_just_pressed("ui_accept"):
			GameState.spawn_point_name = "House01"
			get_tree().change_scene_to_file("res://Assets/Chapters/chapter_2_1.tscn")
