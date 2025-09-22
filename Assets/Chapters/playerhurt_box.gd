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
	#if playeranim.sprite_frames and playeranim.sprite_frames.has_animation("TakeHit"):
		#playeranim.sprite_frames.set_animation_loop("TakeHit", false)

	# connect AnimatedSprite2D's animation_finished
	#if not playeranim.is_connected("animation_finished", Callable(self, "_on_devil_animation_finished")):
		#playeranim.connect("animation_finished", Callable(self, "_on_devil_animation_finished"))
#
	## listen to health depletion → mark as dead
	#if not health.health_depleted.is_connected(Callable(self, "_on_health_depleteddd")):
		#health.health_depleted.connect(_on_health_depleted)





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
		var hb_id := hb.get_instance_id()        # store the id now
		_hitboxes_in_contact[hb_id] = true
		health.set_health(health.get_health() - hb.damage)
		health_bar.value -= hb.damage
		received_damage.emit(hb.damage)
		playeranim.play("TakeHit")
		is_hurt = true
		#frameFreeze(0.05, 1.0)

		# do not reference `hb` after awaits — use hb_id when you need to remove it
		await get_tree().create_timer(0.3).timeout
		playeranim.play("TakeHit")
		await get_tree().create_timer(1).timeout
		is_hurt = false

		_hitboxes_in_contact.erase(hb_id)
		#print("It's a HitBox! Damage = ", hb.damage)  # only safe if you still reference hb here;
		# if hb might be freed, avoid using hb.* fields after awaits (use stored data instead)
# ensure this is initialized (e.g. in _ready)

var damage_interval := 0.5 # seconds between repeated hits while overlapping
var _hitbox_contacts := {} 
# i-frame / stagger flag


func _on_mino_hitbox_area_entered(area: Area2D) -> void:
	if not area is HitBox:
		return
	var hb: HitBox = area
	var id := hb.get_instance_id()
	if id in _hitbox_contacts:
		return
	# Cache damage and start timer at 0.0
	_hitbox_contacts[id] = {"damage": hb.damage, "timer": 0.0}
	print("HitBox entered:", id)

func _on_mino_hitbox_area_exited(area: Area2D) -> void:
	if not area is HitBox:
		return
	var id := area.get_instance_id()
	if id in _hitbox_contacts:
		_hitbox_contacts.erase(id)
		print("HitBox exited:", id)

func _physics_process(delta: float) -> void:
	# no processing if dead
	if health.get_health() <= 0:
		return

	# Iterate over a copy of keys so the dict can be modified safely
	for id in _hitbox_contacts.keys():
		var data = _hitbox_contacts[id] # this is a copy — remember to write back
		# advance timer
		data.timer += delta
		# if enough time passed, try to apply damage
		if data.timer >= damage_interval:
			data.timer = 0.0
			# only apply if not currently in i-frames / stagger
			if not is_hurt:
				_apply_damage_non_blocking(data.damage)
		# write modified struct back
		_hitbox_contacts[id] = data

func _apply_damage_non_blocking(damage: int) -> void:
	# apply HP change immediately
	var new_hp := health.get_health() - damage
	health.set_health(new_hp)
	health_bar.value = new_hp
	received_damage.emit(damage)

	# start stagger / i-frames without blocking physics (call async function)
	_start_hurt_coroutine()

func _start_hurt_coroutine() -> void:
	if is_hurt:
		return
	is_hurt = true
	playeranim.play("TakeHit")
	# start async coroutine — don't await it here (we don't want to block)
	_hurt_coroutine()

func _hurt_coroutine() -> void:
	# i-frame duration
	await get_tree().create_timer(0.3).timeout
	# extra stagger if you want
	await get_tree().create_timer(1.0).timeout
	is_hurt = false
func frameFreeze(timeScale, duration):
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0
