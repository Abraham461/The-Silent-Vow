extends Area2D


var entered = false
@onready var label = $CanvasLayer/DoorLabel

func _on_body_entered(body: PhysicsBody2D):
	if body.name == "CharacterBody2D":
		entered = true
		label.text = "Press Enter to Explore The Cabin"


func _on_body_exited(body: PhysicsBody2D):
	if body.name == "CharacterBody2D":
		entered = false
		label.text = ""
 
func _physics_process(_delta):
	if entered == true:
		if entered and Input.is_action_just_pressed("ui_accept"):
			GameState.spawn_point_name = "Start"
			get_tree().change_scene_to_file("res://Assets/Chapters/house_1.tscn")
