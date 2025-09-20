extends Area2D

signal received_damage(damage: int)

@onready var health: Health = $"../Health"
@onready var enemy: AnimatedSprite2D = $"../Enemy"
@onready var health_bar: ProgressBar = $"../ProgressBar"
@onready var enemyNightborne: CharacterBody2D = $".."

@onready var death_n_banim: AnimatedSprite2D = $"../deathNBanim"

var _hitboxes_in_contact := {}
var is_hurt: bool = false
var nightborne: bool = false
@onready var hurt_cooldown: Timer = $"../HurtCooldown"

func _ready() -> void:
	
	# connect area signals
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("area_exited", Callable(self, "_on_area_exited")):
		connect("area_exited", Callable(self, "_on_area_exited"))

	# ensure the 'NightborneTakeHit' animation is NOT looping
	#if enemy.sprite_frames and enemy.sprite_frames.has_animation("NightborneTakeHit"):
		#enemy.sprite_frames.set_animation_loop("NightborneTakeHit", false)

	# connect AnimatedSprite2D's animation_finished
	if not enemy.is_connected("animation_finished", Callable(self, "_on_devil_animation_finished")):
		enemy.connect("animation_finished", Callable(self, "_on_devil_animation_finished"))

	# listen to health depletion → mark as dead
	if not health.health_depleted.is_connected(Callable(self, "_on_health_depleted")):
		health.health_depleted.connect(_on_health_depleted)


func _on_area_entered(area: Area2D) -> void:
	if nightborne or (hurt_cooldown and not hurt_cooldown.is_stopped()):
		return  # ignore hits if dead or iFrame active
	
	if area is HitBox:
		var hb: HitBox = area
		_hitboxes_in_contact[hb.get_instance_id()] = true
		health.set_health(health.get_health() - hb.damage)
		health_bar.value -= hb.damage
		received_damage.emit(hb.damage)
		#enemy.play("NightborneTakeHit")
		is_hurt = true

		# start iFrame timer
		await get_tree().create_timer(2).timeout
		is_hurt = false
		_hitboxes_in_contact.erase(hb.get_instance_id())
		print("It's a HitBox! Damage = ", hb.damage)


#func _on_devil_animation_finished() -> void:
	#if enemy.animation == "NightborneTakeHit":
		#is_hurt = false
		## only return to idle if still alive
		#if not nightborne:
			#enemy.play("NightborneIdle")
			


func _on_health_depleted() -> void:
	# mark death so HurtBox ignores future hits
	nightborne = true
	is_hurt = false
	#enemy.play("NightborneDeath")
	#print("Devil died! HurtBox disabled.")
	#enemyNightborne.queue_free()
	if death_n_banim is AnimatedSprite2D:
		death_n_banim.sprite_frames.set_animation_loop("deathNB", false)
	freeze_node(enemyNightborne)
	death_n_banim.play("deathNB")
	await get_tree().create_timer(1.2).timeout
	enemyNightborne.queue_free()








func _on_area_exited(area: Area2D) -> void:
	if area is HitBox:
		var id := area.get_instance_id()
		if id in _hitboxes_in_contact:
			_hitboxes_in_contact.erase(id)
			print("HitBox exit, cleared from contact set: ", area)

func freeze_node(node: Node) -> void:
	# stop processing on the node itself
	if node.has_method("set_physics_process"):
		node.set_physics_process(false)
	if node.has_method("set_process"):
		node.set_process(false)

	# if CharacterBody2D, zero its velocity
	if node is CharacterBody2D:
		node.velocity = Vector2.ZERO

	# stop animations (AnimationPlayer or AnimatedSprite2D)
	_stop_animations(node)

	# disable collision shapes / layers / area monitoring
	_disable_collisions(node)

	# stop children processing so nothing else runs (AI, timers, etc.)
	for child in node.get_children():
		if child is Node:
			if child.has_method("set_physics_process"):
				child.set_physics_process(false)
			if child.has_method("set_process"):
				child.set_process(false)


func unfreeze_node(node: Node) -> void:
	# re-enable processing for node and children (note: re-enable carefully)
	if node.has_method("set_physics_process"):
		node.set_physics_process(true)
	if node.has_method("set_process"):
		node.set_process(true)

	# re-enable collisions & areas
	_enable_collisions(node)

	# children: re-enable (only if you want them to resume)
	for child in node.get_children():
		if child is Node:
			if child.has_method("set_physics_process"):
				child.set_physics_process(true)
			if child.has_method("set_process"):
				child.set_process(true)


# ---------- helpers ----------

func _stop_animations(node: Node) -> void:
	if node is AnimationPlayer:
		node.stop()
	elif node is AnimatedSprite2D:
		node.stop()
	for child in node.get_children():
		_stop_animations(child)


func _disable_collisions(node: Node) -> void:
	# CollisionShape2D has `disabled` property
	if node is CollisionShape2D:
		node.disabled = true

	# CollisionObject2D (PhysicsBody2D, Area2D, etc.) -> clear layers/masks
	if node is CollisionObject2D:
		# store previous values if you need to restore later (optional)
		# node._saved_collision_layer = node.collision_layer
		# node._saved_collision_mask = node.collision_mask
		node.collision_layer = 0
		node.collision_mask = 0

	# Area2D: disable monitoring so it stops firing enters/exits
	if node is Area2D:
		# Area2D has 'monitoring' in typical API
		node.monitoring = false

	for child in node.get_children():
		_disable_collisions(child)


func _enable_collisions(node: Node) -> void:
	# re-enable collisions — this is basic and assumes default values;
	# if you preserved original layer/mask, restore them instead.
	if node is CollisionShape2D:
		node.disabled = false

	if node is CollisionObject2D:
		# set sensible defaults (change as needed)
		node.collision_layer = 1
		node.collision_mask = 1

	if node is Area2D:
		node.monitoring = true

	for child in node.get_children():
		_enable_collisions(child)
