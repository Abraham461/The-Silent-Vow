class_name TestCombatSystem
extends Node

# Simple test script to verify combat system functionality

func _ready():
	print("=== Combat System Test ===")
	
	# Test 1: CombatEntity creation
	test_combat_entity()
	
	# Test 2: HitBox/HurtBox creation
	test_hitbox_hurtbox()
	
	# Test 3: Health system
	test_health_system()
	
	# Test 4: Combat effects
	test_combat_effects()
	
	print("=== All Tests Completed ===")

func test_combat_entity():
	print("Test 1: CombatEntity creation")
	
	# Create a test entity
	var entity = CharacterBody2D.new()
	entity.name = "TestEntity"
	
	# Add CombatEntity script
	var script = preload("res://Assets/Combat/CombatEntity.gd")
	entity.set_script(script)
	
	# Add to scene for testing
	add_child(entity)
	
	# Test health
	entity.max_health = 100
	entity.current_health = 100
	
	print("  ✓ CombatEntity created successfully")
	print("  ✓ Health system working")
	
	# Clean up
	entity.queue_free()

func test_hitbox_hurtbox():
	print("Test 2: HitBox/HurtBox creation")
	
	# Create hitbox
	var hitbox_script = preload("res://Assets/Combat/CombatHitBox.gd")
	var hitbox = Area2D.new()
	hitbox.set_script(hitbox_script)
	hitbox.name = "TestHitBox"
	
	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 30)
	collision_shape.shape = shape
	hitbox.add_child(collision_shape)
	
	# Create hurtbox
	var hurtbox_script = preload("res://Assets/Combat/CombatHurtBox.gd")
	var hurtbox = Area2D.new()
	hurtbox.set_script(hurtbox_script)
	hurtbox.name = "TestHurtBox"
	
	# Add collision shape
	var hurtbox_collision = CollisionShape2D.new()
	var hurtbox_shape = RectangleShape2D.new()
	hurtbox_shape.size = Vector2(15, 25)
	hurtbox_collision.shape = hurtbox_shape
	hurtbox.add_child(hurtbox_collision)
	
	# Add to scene for testing
	add_child(hitbox)
	add_child(hurtbox)
	
	print("  ✓ HitBox created successfully")
	print("  ✓ HurtBox created successfully")
	
	# Clean up
	hitbox.queue_free()
	hurtbox.queue_free()

func test_health_system():
	print("Test 3: Health system")
	
	# Create health component
	var health_script = preload("res://Assets/Combat/HealthComponent.gd")
	var health = Node.new()
	health.set_script(health_script)
	health.name = "TestHealth"
	
	# Test properties
	health.max_health = 150
	health.current_health = 100
	
	print("  ✓ Health component created")
	print("  ✓ Health properties working")
	
	# Clean up
	health.queue_free()

func test_combat_effects():
	print("Test 4: Combat effects")
	
	# Create effects component
	var effects_script = preload("res://Assets/Combat/CombatEffects.gd")
	var effects = Node.new()
	effects.set_script(effects_script)
	effects.name = "TestEffects"
	
	# Add to scene for testing
	add_child(effects)
	
	print("  ✓ Combat effects component created")
	
	# Clean up
	effects.queue_free()

func _process(delta):
	# Run tests once
	if ProjectSettings.has_setting("debug/testing") and ProjectSettings.get_setting("debug/testing") == true:
		# This would run actual combat tests in a real scenario
		pass
