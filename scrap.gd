extends Area2D

signal hit_player

var speed = 350
var direction = Vector2.ZERO

func _process(delta):
	if direction == Vector2.ZERO:
		return
	
	position += direction * speed * delta
	rotation += 3 * delta
	
	if position.length() > 5000:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		hit_player.emit()
		position = Vector2(-2000, -2000)
		queue_free()
