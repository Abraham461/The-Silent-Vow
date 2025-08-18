extends Area2D


@export var item_name: String = "Key"
@export var item_icon: Texture
@export var item_id: String = "scroll_01"

var player_near = false


func _physics_process(_delta):
	if player_near and Input.is_action_just_pressed("interact"):
		print("Picked up:", item_name)
		Inventory.items.append({
			"name": item_name,
			"icon": item_icon
		})
		Inventory.picked_up_ids.append(item_id)
		print("Current Inventory:", Inventory.items)
		queue_free()

func _on_body_entered(body: PhysicsBody2D) -> void:
	if body.name == "CharacterBody2D":
		player_near = true
		print("Player is near the item")

func _on_body_exited(body: PhysicsBody2D) -> void:
	if body.name == "CharacterBody2D":
		player_near = false
		print("Player left the item")
		
func _ready():
	if item_id in Inventory.picked_up_ids:
		queue_free()
