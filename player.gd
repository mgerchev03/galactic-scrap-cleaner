extends CharacterBody2D

@export var speed = 400.0  # Скорост на движение
@export var rotation_speed = 10.0  # Колко бързо се обръща (за плавност)

func _physics_process(delta):
	# 1. Взимаме входните данни (WASD или стрелките)
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 2. Движение
	if direction != Vector2.ZERO:
		velocity = direction * speed
		
		# 3. Обръщане към посоката на движение
		# Използваме lerp_angle за плавно завъртане
		var target_angle = direction.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	else:
		# Плавно спиране (триене), ако не се натиска нищо
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

	# 4. Прилагане на физиката
	move_and_slide()
