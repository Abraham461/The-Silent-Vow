class_name CombatTestController
extends Node2D

# Test controller for combat system demonstration

func _ready():
	print("Combat Test Scene Loaded")
	print("Controls:")
	print("- Arrow keys to move")
	print("- Z to attack")
	print("- X to roll")
	print("- C to pray")
	print("- Space to jump")
	
	# Setup enemy
	if has_node("Enemy"):
		var enemy = get_node("Enemy")
		print("Enemy initialized with combat system")
	
	# Setup player
	if has_node("Player"):
		var player = get_node("Player")
		print("Player initialized with combat system")

func _process(delta):
	# Simple game loop for testing
	pass
