extends CharacterBody2D

@export var speed = 400.0
@export var rotation_speed = 10.0

# Променливи за Nuke умението
var nuke_cooldown = 10.0
var nuke_ready = true

# Референция към лентата за прогрес
@onready var nuke_bar = $CanvasLayer/ProgressBar 

func _physics_process(delta: float) -> void:
	# 1. Движение
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		var target_angle = direction.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)
	
	move_and_slide()

	# 2. Активиране на Nuke
	if Input.is_action_just_pressed("ui_select") and nuke_ready:
		activate_nuke()

func activate_nuke():
	nuke_ready = false
	
	# Унищожаване на враговете
	var objects_to_destroy = get_tree().get_nodes_in_group("enemies")
	for obj in objects_to_destroy:
		obj.queue_free()
	
	# Визуално обновяване на лентата (правим я 0)
	nuke_bar.value = 0
	
	# Създаваме Tween за плавно пълнене на лентата за 10 секунди
	var tween = create_tween()
	tween.tween_property(nuke_bar, "value", nuke_cooldown, nuke_cooldown)
	
	# Изчакваме cooldown-а
	await get_tree().create_timer(nuke_cooldown).timeout
	nuke_ready = true
