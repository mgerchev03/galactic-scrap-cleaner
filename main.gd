extends Node2D

var scrap_scene = preload("res://scrap.tscn")
var score = 0
var lives = 5 
var base_scrap_speed = 350
var is_game_over = false

@onready var heart_nodes = [
	$CanvasLayer/UI/HealthBar/Hearth_1,
	$CanvasLayer/UI/HealthBar/Hearth_2,
	$CanvasLayer/UI/HealthBar/Hearth_3,
	$CanvasLayer/UI/HealthBar/Hearth_4,
	$CanvasLayer/UI/HealthBar/Hearth_5
]

var heart_full = preload("res://Full_Hearth.png")
var heart_empty = preload("res://Empty_Hearth.png")

@onready var timer = $Timer
@onready var player = $Player
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var go_label = $CanvasLayer/GameOverLabel

func _ready():
	# Уверяваме се, че всичко е активно в началото
	Engine.time_scale = 1
	timer.wait_time = 1.0
	timer.start() 
	is_game_over = false
	if go_label: go_label.visible = false
	update_health_ui(lives)

func _process(_delta):
	# Рестартът винаги работи, защото не замразяваме Engine.time_scale
	if is_game_over and Input.is_action_just_pressed("ui_accept"):
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
	
	var scrap = scrap_scene.instantiate()
	var screen_size = get_viewport_rect().size
	
	var side = randi() % 4
	var spawn_pos = Vector2.ZERO
	match side:
		0: spawn_pos = Vector2(randf_range(0, screen_size.x), -100)
		1: spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + 100)
		2: spawn_pos = Vector2(-100, randf_range(0, screen_size.y))
		3: spawn_pos = Vector2(screen_size.x + 100, randf_range(0, screen_size.y))
	
	scrap.position = spawn_pos
	add_child(scrap)
	
	if player:
		scrap.direction = (player.global_position - spawn_pos).normalized()
		scrap.speed = base_scrap_speed
	
	scrap.hit_player.connect(_on_player_hit)
	# В main.gd вътре в _on_timer_timeout
	scrap.tree_exited.connect(func(): _on_scrap_dodged(scrap))

# В най-горната част на main.gd при другите променливи
var is_invincible = false 

func _on_player_hit():
	# Сега main.gd знае какво е is_game_over и lives, защото те са тук!
	if is_game_over or is_invincible: return
	
	is_invincible = true
	lives -= 1
	update_health_ui(lives)
	
	if lives <= 0:
		game_over()
	else:
		# Тъй като сме в main.gd, ползваме @onready променливата player
		if player:
			player.modulate.a = 0.5 
			await get_tree().create_timer(0.5).timeout
			player.modulate.a = 1.0
		is_invincible = false

func _on_scrap_dodged(scrap_node):
	if is_game_over: return
	if scrap_node.already_hit == true: return
	
	score += 10
	score_label.text = "Score: " + str(score)
	
	if score % 50 == 0: # 1 Tab
		timer.wait_time = max(timer.wait_time - 0.1, 0.4) # 2 Tabs
		base_scrap_speed += 40 # 2 Tabs
		if player: # 2 Tabs
			player.speed += 25 # 3 Tabs
		
		# НОВО: Забързваме и играча, за да може да избяга!
		if player:
			player.speed += 20 # Можеш да промениш числото за по-добър баланс

func game_over():
	is_game_over = true
	timer.stop() # Спираме таймера за нови боклуци
	
	if go_label:
		go_label.text = "GAME OVER\nPress SPACE to Restart"
		# ТОВА Е КЛЮЧЪТ: Центрираме текста в средата на екрана
		go_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		go_label.visible = true
	
	# Спираме движението на играча
	if player:
		player.set_process(false)
		player.set_physics_process(false)

	# Правим всички сърца празни (вече с Hearth_1)
	update_health_ui(0)
