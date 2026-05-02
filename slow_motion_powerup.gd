extends Area2D

@export var speed: float = 250.0
var is_active = false

func _process(delta):
	# Движим го надолу само ако още не е взет
	if not is_active:
		position.y += (speed * delta) / Engine.time_scale
	
	# Ако излезе от екрана без да е взет
	if position.y > 1100:
		queue_free() # Това автоматично ще пусне таймера в Main

func _on_body_entered(body):
	# Използваме is_active, за да не се задейства два пъти
	if not is_active and (body.name == "Player" or body.has_method("is_player")):
		activate_slow_motion()

func activate_slow_motion():
	is_active = true
	print("Слоу моушън активиран за 10 секунди!")
	
	Engine.time_scale = 0.5
	
	# Скриваме часовника и изключваме сблъсъка
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Чакаме точно 10 секунди реално време
	# Тъй като Engine.time_scale е 0.5, трябва да чакаме 5.0 игрови секунди
	await get_tree().create_timer(5.0).timeout 
	
	Engine.time_scale = 1.0
	print("Ефектът приключи. Почивка 20-30 сек.")
	
	# Премахваме обекта - това задейства сигнала в Main за новия таймер
	queue_free()
