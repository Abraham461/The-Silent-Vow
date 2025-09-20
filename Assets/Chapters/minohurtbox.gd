extends Area2D

signal received_damage(damage: int)
@onready var health: minoHealth = $"../minoHealth"
#@onready var health: Health = $"../Health"
@onready var enemy: AnimatedSprite2D = $"../AnimatedSprite2D"
#@onready var enemy: AnimatedSprite2D = $"../Enemy"
#@onready var health_bar: ProgressBar = $"../ProgressBar"
@onready var health_bar: ProgressBar = $"../ProgressBar"

@onready var enemymino: CharacterBody2D = $".."


var _hitboxes_in_contact := {}
var is_hurt: bool = false
var mino: bool = false
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
	if mino or (hurt_cooldown and not hurt_cooldown.is_stopped()):
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


func _on_devil_animation_finished() -> void:
	#if enemy.animation == "NightborneTakeHit":
		is_hurt = false
		# only return to idle if still alive
		if not mino:
			enemy.play("minoidle")
			


func _on_health_depleted() -> void:
	# mark death so HurtBox ignores future hits
	mino = true
	is_hurt = false
	enemy.play("NightborneDeath")
	print("Devil died! HurtBox disabled.")
	enemymino.queue_free()



func _on_area_exited(area: Area2D) -> void:
	if area is HitBox:
		var id := area.get_instance_id()
		if id in _hitboxes_in_contact:
			_hitboxes_in_contact.erase(id)
			print("HitBox exit, cleared from contact set: ", area)
