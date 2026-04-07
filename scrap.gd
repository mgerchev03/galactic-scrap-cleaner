extends Area2D

signal hit_player

var speed = 350
var direction = Vector2.ZERO
var already_hit = false # Флаг, който спира двойното отчитане

# В scrap.gd вътре в _process
func _process(delta):
	# ... движението ти ...
	position += direction * speed * delta
	
	# Проверяваме дали е излязъл от границите на екрана (с малко буфер от 200 пиксела)
	var screen_size = get_viewport_rect().size
	if position.x < -200 or position.x > screen_size.x + 200 or \
	   position.y < -200 or position.y > screen_size.y + 200:
		queue_free() # Веднага щом излезе, се трие и дава точки!

func _on_body_entered(body):
	# Проверяваме дали удряме играча и дали вече не сме го ударили
	if body.name == "Player" and not already_hit:
		already_hit = true 
		hit_player.emit() # Пращаме сигнал на main.gd да вземе живот
		queue_free() # Изтриваме боклука веднага
