extends Area2D

var _triggered_areas := {}

func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))

func _on_area_entered(area: Area2D) -> void:
	if area in _triggered_areas:
		return
	
	if area.has_method("action"):
		area.action()
		_triggered_areas[area] = true

func _on_area_exited(area: Area2D) -> void:
	if area in _triggered_areas:
		_triggered_areas.erase(area)
