#extends "res://Assets/Combat/CombatHitBox.gd"
#
## This script now extends CombatHitBox which provides enhanced functionality
## You can override or extend any methods here for custom behavior
#
#func _ready():
	#super._ready()
	## Any additional initialization for this hitbox
class_name HitBox
extends Area2D



@export var damage: int = 1 : set = set_damage, get = get_damage

func set_damage(value: int):
	damage = value
	
	
func get_damage() -> int:
	return damage
