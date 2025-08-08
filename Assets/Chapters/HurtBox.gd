class_name HurtBox
extends Area2D



signal recieved_damage(damage: int)



@export var health: Health = null

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox != null:
		health.health -= hitbox.damage
		recieved_damage.emit(hitbox.damage)
