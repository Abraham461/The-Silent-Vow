class_name HurtBox
extends Area2D

signal received_damage(damage: int)

@onready var devilanim: AnimatedSprite2D = $"../AnimatedSprite2D"
#@onready var health: Health = $"../Health"
@onready var health: devilHealth = $"../devilHealth"
@onready var enemydevil: CharacterBody2D = $".."
@onready var health_bar: ProgressBar = $"../ProgressBar"

var _hitboxes_in_contact := {}
var is_hurt: bool = false
var devildeath: bool = false
@onready var hurt_cooldown: Timer = $"../HurtCooldown"

func _ready() -> void:
	# connect area signals
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("area_exited", Callable(self, "_on_area_exited")):
		connect("area_exited", Callable(self, "_on_area_exited"))

	# ensure the 'devilhurt' animation is NOT looping
	if devilanim.sprite_frames and devilanim.sprite_frames.has_animation("devilhurt"):
		devilanim.sprite_frames.set_animation_loop("devilhurt", false)

	# connect AnimatedSprite2D's animation_finished
	if not devilanim.is_connected("animation_finished", Callable(self, "_on_devil_animation_finished")):
		devilanim.connect("animation_finished", Callable(self, "_on_devil_animation_finished"))

	# listen to health depletion → mark as dead
	if not health.health_depleted.is_connected(Callable(self, "_on_health_depleted")):
		health.health_depleted.connect(_on_health_depleted)


func _on_area_entered(area: Area2D) -> void:
	if devildeath or (hurt_cooldown and not hurt_cooldown.is_stopped()):
		return  # ignore hits if dead or iFrame active
	
	if area is HitBox:
		var hb: HitBox = area
		_hitboxes_in_contact[hb.get_instance_id()] = true
		health.set_health(health.get_health() - hb.damage)
		received_damage.emit(hb.damage)
		health_bar.value -= hb.damage
		#devilanim.play("devilhurt")
		is_hurt = true

		# start iFrame timer
		await get_tree().create_timer(0.5).timeout
		is_hurt = false
		_hitboxes_in_contact.erase(hb.get_instance_id())
		print("It's a HitBox! Damage = ", hb.damage)


func _on_devil_animation_finished() -> void:

	is_hurt = false
	# only return to idle if still alive
	if not devildeath:
		devilanim.play("devilidle")
			


func _on_health_depleted() -> void:
	# mark death so HurtBox ignores future hits
	devildeath = true
	is_hurt = false
	devilanim.play("devildeath")
	print("Devil died! HurtBox disabled.")
	enemydevil.queue_free()
	



func _on_area_exited(area: Area2D) -> void:
	if area is HitBox:
		var id := area.get_instance_id()
		if id in _hitboxes_in_contact:
			_hitboxes_in_contact.erase(id)
			print("HitBox exit, cleared from contact set: ", area)
