extends Area2D


var entered = false

func _on_body_entered(body: PhysicsBody2D):
	entered = true


func _on_body_exited(body: PhysicsBody2D):
	entered = false

func _physics_process(delta):
	if entered == true:
		if Input.is_action_just_pressed("ui_accept"):
			GameState.spawn_point_name = "Start"
			get_tree().change_scene_to_file("res://Assets/Chapters/house_1.tscn")
