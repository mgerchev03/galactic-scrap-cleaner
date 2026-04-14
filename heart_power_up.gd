extends Area2D

signal recovered_life

var speed = 250
var direction = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta

# ТОВА Е ФУНКЦИЯТА, КОЯТО СВЪРЗА
func _on_body_entered(body):
	# Проверяваме дали името на играча съвпада
	if body.name == "Player":
		recovered_life.emit() # Праща сигнал към main.gd
		queue_free()          # Сърцето изчезва
