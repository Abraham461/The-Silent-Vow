extends Node2D
@onready var player = $CharacterBody2D
@onready var anim: AnimatedSprite2D = $enemy1/AnimatedSprite2D
@onready var animgate: AnimatedSprite2D = $AnimatedSprite2D
@onready var holyaura: AnimatedSprite2D = $holyaura
@onready var smoe: AnimatedSprite2D = $smoe
@onready var crow: AnimatedSprite2D = $crow/AnimatedSprite2D
@onready var devilanim: AnimatedSprite2D = $enemydevil/AnimatedSprite2D
@onready var enemy: AnimatedSprite2D = $Enemy/Enemy
@onready var enemyNB: CharacterBody2D = $Enemy

@onready var lightning_aura: AnimatedSprite2D = $Enemy/lightningAura
@onready var gate2: AnimatedSprite2D = $AnimatedSprite2D3
@onready var gate3: AnimatedSprite2D = $AnimatedSprite2D
@onready var holyaura_2: AnimatedSprite2D = $holyaura2
@onready var holyaura_3: AnimatedSprite2D = $holyaura3
@onready var smoe_2: AnimatedSprite2D = $smoe2
@onready var smoe_3: AnimatedSprite2D = $smoe3
@onready var scene_change_tp: AnimatedSprite2D = $SceneChangeTP
@onready var scenechange_area: Area2D = $SceneChangeTP/ScenechangeArea
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2

#@onready var main_theme_song: AudioStreamPlayer2D = $mainThemeSong
@onready var main_theme_song: AudioStreamPlayer = $mainThemeSong


var nightborne: bool = false
var devildeath := false
# Called when the node enters the scene tree for the first time.
func _ready():
	var spawn_name = GameState.spawn_point_name
	var spawn_position = $SpawnPoints.get_node(spawn_name).global_position
	$CharacterBody2D.global_position = spawn_position
	main_theme_song.play()
	anim.play("modIdle")
	animgate.play("gate")
	gate2.play("gate")
	gate3.play("gate")
	holyaura.play("fire")
	holyaura_2.play("fire")
	holyaura_3.play("fire")
	smoe.play("smoke")
	smoe_3.play("smoke")
	smoe_2.play("smoke")
	crow.play("crowidle")
	enemy.play("NightborneIdle")
	lightning_aura.play("aura")
	scene_change_tp.play("ch3scene")
	animated_sprite_2d_2.play("gate")
	if not devildeath:
		devilanim.play("devilidle")
		# If the enemy is valid (exists), disable the scene-change trigger.
	if is_instance_valid(enemyNB):
		scene_change_tp.visible = false
		scenechange_area.monitoring = false
	else:
		# No enemy -> enable scene-change right away
		scene_change_tp.visible = true
		scenechange_area.monitoring = true


func _on_enemy_tree_exited() -> void:
	scene_change_tp.visible = true
	scenechange_area.monitoring = true
