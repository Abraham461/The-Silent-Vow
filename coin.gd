extends AnimatedSprite2D
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.coins += 1
		#print("Coin collected!")
		$retro_coin.play()
		await get_tree().create_timer(0.2).timeout
		queue_free()
