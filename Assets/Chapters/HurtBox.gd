class_name HurtBox
extends Area2D



signal recieved_damage(damage: int)



@export var health: Health = null

func _ready():
	connect("area_entered", _on_area_entered)

func _extract_damage(from_area: Area2D) -> int:
	# Accept either a HitBox script or any Area2D exposing a damage value/getter
	var dmg: int = 1
	if from_area == null:
		return dmg
	# Priority 1: custom HitBox class with get_damage
	if from_area.has_method("get_damage"):
		var maybe: Variant = from_area.get_damage()
		if typeof(maybe) == TYPE_INT:
			dmg = int(maybe)
		return dmg
	# Priority 2: direct property named "damage"
	if from_area.has_variable("damage"):
		var v: Variant = from_area.get("damage")
		if typeof(v) == TYPE_INT:
			dmg = int(v)
	return dmg

func _on_area_entered(hitbox: Area2D) -> void:
	if health == null:
		return
	if hitbox != null:
		var dmg := _extract_damage(hitbox)
		health.health -= dmg
		recieved_damage.emit(dmg)
