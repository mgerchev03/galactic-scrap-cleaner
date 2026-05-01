extends Node2D

# 1. Списък с всички твои нови сцени
var possible_scraps = [
	preload("res://Metal_Box.tscn"),
	preload("res://Asteroid.tscn"),
	preload("res://Satellite.tscn")
]

# НОВО: Зареждаме сцената на сърцето
var heart_scene = preload("res://heart_power_up.tscn")

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

var can_restart = false # В началото не може да се рестартира

@onready var timer = $Timer
@onready var player = $Player
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var go_label = $CanvasLayer/GameOverLabel
@onready var name_input = $CanvasLayer/UI/NameInput

func _ready():
	Engine.time_scale = 1
	timer.wait_time = 1.0
	timer.start() 
	is_game_over = false
	if go_label: go_label.visible = false
	update_health_ui(lives)

func _process(_delta):
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
	
	# ШАНС ЗА СЪРЦЕ: 10% шанс да се появи сърце, само ако ни липсва живот
	if lives < 5 and randf() < 0.1:
		spawn_heart()
	else:
		spawn_scrap()

# Функция за създаване на препятствия (Scrap)
func spawn_scrap():
	var random_index = randi() % possible_scraps.size()
	var selected_scrap_scene = possible_scraps[random_index]
	var scrap = selected_scrap_scene.instantiate()
	
	_setup_spawn_position(scrap)
	add_child(scrap)
	
	scrap.hit_player.connect(_on_player_hit)
	scrap.tree_exited.connect(func(): _on_scrap_dodged(scrap))

# НОВО: Функция за създаване на сърце-бонус
func spawn_heart():
	var heart = heart_scene.instantiate()
	_setup_spawn_position(heart)
	add_child(heart)
	
	# Свързваме сигнала на сърцето към функцията за лекуване
	heart.recovered_life.connect(_on_player_recovered)

# Помощна функция за определяне на позицията (за да не пишем кода два пъти)
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
		# Сърцето може да е малко по-бавно, ако искаш
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
		print("Върнат живот! Текущи животи: ", lives)

func _on_scrap_dodged(scrap_node):
	if is_game_over: return
	if scrap_node.get("already_hit") == true: return
	
	score += 10
	score_label.text = "Score: " + str(score)
	
	if score % 50 == 0:
		timer.wait_time = max(timer.wait_time - 0.1, 0.4)
		base_scrap_speed += 40
		if player:
			player.speed += 45

func _on_player_died(): # Или както се казва твоята функция за край на играта
	$UI/NameInput.show() # Това прави полето видимо
	$GameOverLabel.show()
	# Тук може да добавиш и спиране на времето или други неща

func _input(event):
	# Проверява дали е натиснат клавиша Escape
	if event.is_action_pressed("ui_cancel"): 
		# Проверяваме дали играта е приключила (is_game_over трябва да е true)
		if is_game_over:
			get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_name_input_text_submitted(new_text):
	var p_name = new_text
	if p_name == "": p_name = "Anonymous"
	
	# Изпращаме точките
	SilentWolf.Scores.save_score(p_name, score, "main")
	
	# Вече използваме променливата, която дефинирахме горе
	%NameInput.visible = false
	
	go_label.text = "Score saved for " + p_name + "!\nPress ENTER to Restart\nPress ESC for Main Menu"
	
	await get_tree().create_timer(0.2).timeout
	can_restart = true

func game_over():
	is_game_over = true
	can_restart = false # НОВО: Забраняваме рестарта веднага
	timer.stop()
	
	if score_label:
		score_label.visible = false
		
	if go_label:
		go_label.text = "GAME OVER\nScore: " + str(score) + "\nType your name and press ENTER"
		go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		go_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		go_label.visible = true
		
	$CanvasLayer/NameInput.visible = true
	$CanvasLayer/NameInput.grab_focus() 
	
	if player:
		player.set_process(false)
		player.set_physics_process(false)

	update_health_ui(0)
