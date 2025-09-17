extends Area2D

signal received_damage(damage: int)

@onready var health: playerHealth = $"../playerHealth"


@onready var playeranim: AnimatedSprite2D = $"../AnimatedSprite2D"

var _hitboxes_in_contact := {}
var is_hurt: bool = false
var player: bool = false

@onready var health_bar: ProgressBar = $"../../../CanvasLayer2/UHD/HealthBar"

@onready var hurt_cooldown: Timer = $"../HurtTimer"
@onready var hurt_box: Area2D = $"."

func _ready() -> void:
	# connect area signals
	if not is_connected("area_entered", Callable(self, "_on_hit_box_area_entered")):
		connect("area_entered", Callable(self, "_on_hit_box_area_entered"))
	if not is_connected("area_exited", Callable(self, "_on_area_exited")):
		connect("area_exited", Callable(self, "_on_area_exited"))

	# ensure the 'TakeHit' animation is NOT looping
	if playeranim.sprite_frames and playeranim.sprite_frames.has_animation("TakeHit"):
		playeranim.sprite_frames.set_animation_loop("TakeHit", false)

	# connect AnimatedSprite2D's animation_finished
	if not playeranim.is_connected("animation_finished", Callable(self, "_on_devil_animation_finished")):
		playeranim.connect("animation_finished", Callable(self, "_on_devil_animation_finished"))

	# listen to health depletion → mark as dead
	if not health.health_depleted.is_connected(Callable(self, "_on_health_depleted")):
		health.health_depleted.connect(_on_health_depleted)





func _on_devil_animation_finished() -> void:
	if playeranim.animation == "Death":
		is_hurt = false
		# only return to idle if still alive
		if not player:
			playeranim.play("Idle")
			


func _on_health_depleted() -> void:
	# mark death so HurtBox ignores future hits
	player = true
	is_hurt = false
	playeranim.play("Death")
	await playeranim.animation_finished
	print("player died! HurtBox disabled.")



#func _on_area_exited(area: Area2D) -> void:

func _on_hit_box_area_exited(area: Area2D) -> void:
	if area is HitBox:
		var id := area.get_instance_id()
		if id in _hitboxes_in_contact:
			_hitboxes_in_contact.erase(id)
			print("HitBox exit, cleared from contact set: ", area)

func _on_hit_box_area_entered(area: Area2D) -> void:
	if player or (hurt_cooldown and not hurt_cooldown.is_stopped()):
		return  # ignore hits if dead or iFrame active
	
	if area is HitBox:
		var hb: HitBox = area
		_hitboxes_in_contact[hb.get_instance_id()] = true
		health.set_health(health.get_health() - hb.damage)
		health_bar.value -= hb.damage
		received_damage.emit(hb.damage)
		playeranim.play("TakeHit")
		is_hurt = true
		# start iFrame timer
		await get_tree().create_timer(0.3).timeout
		playeranim.play("TakeHit")
		await get_tree().create_timer(1).timeout
		is_hurt = false
		_hitboxes_in_contact.erase(hb.get_instance_id())
		print("It's a HitBox! Damage = ", hb.damage)
