extends CharacterBody2D

@export var speed: float = 60.0
@export var chase_speed: float = 100.0
@export var patrol_range: float = 100.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var aggro_zone: Area2D = $AggroZone

var start_pos: Vector2
var dir: float = 1.0
var chasing: bool = false
var player: Node2D = null

func _ready() -> void:
	start_pos = global_position
	if anim and anim.sprite_frames.has_animation("minowalk"):
		anim.play("minowalk")

	aggro_zone.body_entered.connect(_on_body_entered)
	aggro_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	print("Entered:", body.name)
	if body.is_in_group("Player"):
		player = body
		chasing = true

func _on_body_exited(body: Node) -> void:
	if body == player:
		player = null
		chasing = false

func _physics_process(delta: float) -> void:
	if chasing and player:
		var to_player: Vector2 = (player.global_position - global_position).normalized()
		velocity = to_player * chase_speed
	else:
		velocity.x = speed * dir
		velocity.y = 0
		var offset: float = global_position.x - start_pos.x
		if offset >= patrol_range:
			dir = -1.0
		elif offset <= -patrol_range:
			dir = 1.0

	move_and_slide()

	if anim:
		anim.flip_h = velocity.x < 0
