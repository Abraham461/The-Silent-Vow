extends Node2D

# Test controller for NightBorne enemy combat system
# This script helps monitor and test the enemy animations and behavior

@onready var player = $Player
@onready var enemies = [$NightBorneEnemy, $NightBorneEnemy2, $NightBorneEnemy3]
@onready var health_display = $UI/HealthDisplay
@onready var enemy_status = $UI/EnemyStatus

func _ready():
	print("NightBorne Combat Test Started")
	print("Available animations: NightBorneIdle, NightBorneRun, NightBorneAtk, NightBorneDeath, NightBorneTakeHit")
	
	# Connect player health signals if available
	if player.has_node("HealthComponent"):
		var health_comp = player.get_node("HealthComponent")
		if health_comp.has_signal("health_changed"):
			health_comp.health_changed.connect(_on_player_health_changed)
		if health_comp.has_signal("health_depleted"):
			health_comp.health_depleted.connect(_on_player_died)
	
	# Monitor enemy states
	set_process(true)

func _process(_delta):
	# Update UI displays
	_update_health_display()
	_update_enemy_status()
	
	# Debug controls
	if Input.is_action_just_pressed("ui_page_up"):
		_spawn_enemy()
	if Input.is_action_just_pressed("ui_page_down"):
		_damage_all_enemies()
	if Input.is_action_just_pressed("ui_home"):
		_reset_test()

func _update_health_display():
	if player and player.has_node("HealthComponent"):
		var health_comp = player.get_node("HealthComponent")
		var current = health_comp.current_health if "current_health" in health_comp else 100
		var max_hp = health_comp.max_health if "max_health" in health_comp else 100
		health_display.text = "Player Health: %d/%d" % [current, max_hp]
		
		# Color code based on health percentage
		var health_percent = float(current) / float(max_hp)
		if health_percent > 0.6:
			health_display.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_display.modulate = Color.YELLOW
		else:
			health_display.modulate = Color.RED

func _update_enemy_status():
	var status_text = "Enemies Status:\n"
	
	for i in range(enemies.size()):
		if is_instance_valid(enemies[i]):
			var enemy = enemies[i]
			var state = _get_enemy_state_name(enemy)
			var health = _get_enemy_health(enemy)
			var animation = _get_current_animation(enemy)
			
			status_text += "Enemy %d: %s (HP: %d) [%s]\n" % [i + 1, state, health, animation]
		else:
			status_text += "Enemy %d: DEFEATED\n" % [i + 1]
	
	enemy_status.text = status_text

func _get_enemy_state_name(enemy) -> String:
	if not "current_state" in enemy:
		return "Unknown"
	
	# Match the EnemyState enum from EnemyCombat.gd
	match enemy.current_state:
		0: return "IDLE"
		1: return "PATROL"
		2: return "CHASE"
		3: return "ATTACK"
		4: return "HURT"
		5: return "DEAD"
		6: return "BOSS_PHASE"
		_: return "Unknown"

func _get_enemy_health(enemy) -> int:
	if enemy.has_node("HealthComponent"):
		var health_comp = enemy.get_node("HealthComponent")
		if "current_health" in health_comp:
			return health_comp.current_health
	if "current_health" in enemy:
		return enemy.current_health
	return 0

func _get_current_animation(enemy) -> String:
	if enemy.has_node("AnimatedSprite2D"):
		var sprite = enemy.get_node("AnimatedSprite2D")
		if sprite and "animation" in sprite:
			return sprite.animation
	return "None"

func _on_player_health_changed(new_health: int):
	print("Player health changed to: ", new_health)

func _on_player_died():
	print("Player defeated!")
	health_display.text = "PLAYER DEFEATED!"
	health_display.modulate = Color.RED

func _spawn_enemy():
	print("Spawning new enemy...")
	var enemy_scene = preload("res://Assets/Combat/NightBorneEnemy.tscn")
	var new_enemy = enemy_scene.instantiate()
	new_enemy.position = Vector2(randf_range(400, 800), 400)
	add_child(new_enemy)
	enemies.append(new_enemy)
	print("New enemy spawned at position: ", new_enemy.position)

func _damage_all_enemies():
	print("Damaging all enemies for testing...")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(25, player, Vector2(200, -100))
			print("Damaged enemy: ", enemy.name)

func _reset_test():
	print("Resetting test scene...")
	get_tree().reload_current_scene()

func _input(event):
	# Additional debug inputs
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("Enemy 1 Animation: ", _get_current_animation(enemies[0]) if is_instance_valid(enemies[0]) else "N/A")
			KEY_2:
				print("Enemy 2 Animation: ", _get_current_animation(enemies[1]) if is_instance_valid(enemies[1]) else "N/A")
			KEY_3:
				print("Enemy 3 Animation: ", _get_current_animation(enemies[2]) if is_instance_valid(enemies[2]) else "N/A")
			KEY_F1:
				_force_enemy_animation(0, "NightBorneIdle")
			KEY_F2:
				_force_enemy_animation(0, "NightBorneRun")
			KEY_F3:
				_force_enemy_animation(0, "NightBorneAtk")
			KEY_F4:
				_force_enemy_animation(0, "NightBorneTakeHit")
			KEY_F5:
				_force_enemy_animation(0, "NightBorneDeath")

func _force_enemy_animation(enemy_index: int, animation_name: String):
	if enemy_index < enemies.size() and is_instance_valid(enemies[enemy_index]):
		var enemy = enemies[enemy_index]
		if enemy.has_node("AnimatedSprite2D"):
			var sprite = enemy.get_node("AnimatedSprite2D")
			sprite.play(animation_name)
			print("Forced animation '%s' on Enemy %d" % [animation_name, enemy_index + 1])