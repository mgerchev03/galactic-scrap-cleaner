extends Node2D

# 1. Списък с обекти
var possible_scraps = [
	preload("res://Metal_Box.tscn"),
	preload("res://Asteroid.tscn"),
	preload("res://Satellite.tscn")
]

var heart_scene = preload("res://heart_power_up.tscn")

# Експортираме сцената за забавяне, за да я сложиш в Инспектора
@export var slow_motion_powerup: PackedScene

var score = 0
var lives = 5 
var base_scrap_speed = 350
var is_game_over = false
var is_invincible = false 

@onready var heart_nodes = [
	$CanvasLayer/UI/HealthBar/Hearth_1,
	$CanvasLayer/UI/HealthBar/Hearth_2,
	$CanvasLayer/UI/HealthBar/Hearth_3,
	$CanvasLayer/UI/HealthBar/Hearth_4,
	$CanvasLayer/UI/HealthBar/Hearth_5
]

var heart_full = preload("res://Full_Hearth.png")
var heart_empty = preload("res://Empty_Hearth.png")

var can_restart = false
var slow_motion_timer: Timer # Таймерът за спаунване

@onready var timer = $Timer
@onready var player = $Player
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var go_label = $CanvasLayer/GameOverLabel
@onready var name_input = $CanvasLayer/UI/NameInput

var game_time = 0.0
@onready var time_label = $CanvasLayer/TimeLabel # Увери се, че пътят е правилен

func _ready():
	Engine.time_scale = 1.0
	timer.wait_time = 1.0
	timer.start() 
	is_game_over = false
	if go_label: go_label.visible = false
	update_health_ui(lives)
	
	# Инициализираме спаунера за Slow Motion
	setup_slow_motion_spawner()

func _process(delta):
	if is_game_over: return
	
	# Трупаме времето. Делим на time_scale, за да отчитаме реални секунди, 
	# дори когато играта е забавена.
	game_time += delta / Engine.time_scale
	
	# Показваме само целите секунди
	time_label.text = "Time: " + str(int(game_time))

	# Твоят код за рестарт (Enter) си остава тук отдолу...
	if is_game_over and can_restart and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()

func update_health_ui(current_health: int):
	for i in range(heart_nodes.size()):
		if heart_nodes[i] != null:
			if i < current_health:
				heart_nodes[i].texture = heart_full
			else:
				heart_nodes[i].texture = heart_empty

func _on_timer_timeout():
	if is_game_over: return 
	
	if lives < 5 and randf() < 0.1:
		spawn_heart()
	else:
		spawn_scrap()

func spawn_scrap():
	var random_index = randi() % possible_scraps.size()
	var selected_scrap_scene = possible_scraps[random_index]
	var scrap = selected_scrap_scene.instantiate()
	_setup_spawn_position(scrap)
	add_child(scrap)
	scrap.hit_player.connect(_on_player_hit)
	scrap.tree_exited.connect(func(): _on_scrap_dodged(scrap))

func spawn_heart():
	var heart = heart_scene.instantiate()
	_setup_spawn_position(heart)
	add_child(heart)
	heart.recovered_life.connect(_on_player_recovered)

# НОВО: Функции за Slow Motion спаунване
func setup_slow_motion_spawner():
	print("1. Спаунерът се настройва...")
	slow_motion_timer = Timer.new()
	add_child(slow_motion_timer)
	slow_motion_timer.one_shot = true
	slow_motion_timer.timeout.connect(_on_slow_motion_timer_timeout)
	start_random_slow_motion_timer()

func start_random_slow_motion_timer():
	if is_game_over: return
	var r_time = randf_range(20.0, 30.0)
	print("2. Таймерът започна! Нов часовник след: ", int(r_time), " секунди.")
	slow_motion_timer.start(r_time)

func _on_slow_motion_timer_timeout():
	print("3. ТАЙМЕРЪТ ИЗТЕЧЕ! Пускам предмета...")
	spawn_slow_motion_item()
	# ПРЕМАХВАМЕ start_random_slow_motion_timer() оттук! 
	# Таймерът ще се рестартира само когато часовникът изчезне.

func spawn_slow_motion_item():
	if slow_motion_powerup == null:
		print("ГРЕШКА: Празен Инспектор!")
		return
		
	var powerup = slow_motion_powerup.instantiate()
	
	# СВЪРЗВАНЕ: Когато часовникът бъде премахнат (queue_free), пусни таймера за следващия
	powerup.tree_exited.connect(start_random_slow_motion_timer)
	
	var screen_width = get_viewport_rect().size.x
	powerup.position = Vector2(randf_range(50, screen_width - 50), -50)
	add_child(powerup)
	
	print("4. УСПЕХ! Часовникът е в играта.")

func _setup_spawn_position(obj):
	var screen_size = get_viewport_rect().size
	var side = randi() % 4
	var spawn_pos = Vector2.ZERO
	match side:
		0: spawn_pos = Vector2(randf_range(0, screen_size.x), -100)
		1: spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + 100)
		2: spawn_pos = Vector2(-100, randf_range(0, screen_size.y))
		3: spawn_pos = Vector2(screen_size.x + 100, randf_range(0, screen_size.y))
	obj.position = spawn_pos
	if player:
		obj.direction = (player.global_position - spawn_pos).normalized()
		obj.speed = base_scrap_speed if obj.has_signal("hit_player") else 250

func _on_player_hit():
	if is_game_over or is_invincible: return
	is_invincible = true
	lives -= 1
	update_health_ui(lives)
	if lives <= 0:
		game_over()
	else:
		if player:
			player.modulate.a = 0.5 
			await get_tree().create_timer(0.5).timeout
			player.modulate.a = 1.0
		is_invincible = false
		
func _on_player_recovered():
	if lives < 5:
		lives += 1
		update_health_ui(lives)

func _on_scrap_dodged(scrap_node):
	if is_game_over: return
	if scrap_node.get("already_hit") == true: return
	score += 10
	score_label.text = "Score: " + str(score)
	if score % 50 == 0:
		timer.wait_time = max(timer.wait_time - 0.1, 0.4)
		base_scrap_speed += 40
		if player: player.speed += 45

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_game_over:
		get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_name_input_text_submitted(new_text):
	var p_name = new_text if new_text != "" else "Anonymous"
	SilentWolf.Scores.save_score(p_name, score, "main")
	$CanvasLayer/NameInput.visible = false
	go_label.text = "Score saved for " + p_name + "!\nPress ENTER to Restart\nPress ESC for Main Menu"
	await get_tree().create_timer(0.2).timeout
	can_restart = true

func game_over():
	is_game_over = true
	can_restart = false
	timer.stop()
	slow_motion_timer.stop() # Спираме и таймера за бонуси
	Engine.time_scale = 1.0 # Връщаме нормално време, ако е било забавено
	
	if score_label: score_label.visible = false
	if go_label:
		# Добавяме нов ред с изтеклото време, форматирано като цяло число
		go_label.text = "GAME OVER\nScore: " + str(score) + "\nTime: " + str(int(game_time)) + "s\nType your name and press ENTER"
		go_label.visible = true
	
	$CanvasLayer/NameInput.visible = true
	$CanvasLayer/NameInput.grab_focus() 
	if player:
		player.set_process(false)
		player.set_physics_process(false)
	update_health_ui(0)
