extends Node2D

var scrap_scene = preload("res://scrap.tscn")
var score = 0
var lives = 3
var base_scrap_speed = 350

@onready var timer = $Timer
@onready var player = $Player
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var lives_label = $CanvasLayer/LivesLabel

func _ready():
	# ГАРАНТИРАМЕ, ЧЕ ИГРАТА ТРЪГВА
	Engine.time_scale = 1
	timer.wait_time = 1.0
	timer.start() # Пускаме таймера ръчно за всеки случай

func _on_timer_timeout():
	var scrap = scrap_scene.instantiate()
	var screen_size = get_viewport_rect().size
	
	# Избор на страна
	var side = randi() % 4
	var spawn_pos = Vector2.ZERO
	match side:
		0: spawn_pos = Vector2(randf_range(0, screen_size.x), -100)
		1: spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + 100)
		2: spawn_pos = Vector2(-100, randf_range(0, screen_size.y))
		3: spawn_pos = Vector2(screen_size.x + 100, randf_range(0, screen_size.y))
	
	scrap.position = spawn_pos
	add_child(scrap)
	
	# Задаваме посоката веднага след добавяне
	if player:
		scrap.direction = (player.global_position - spawn_pos).normalized()
		scrap.speed = base_scrap_speed
	
	scrap.hit_player.connect(_on_player_hit)
	scrap.tree_exited.connect(func(): _on_scrap_dodged(scrap))

func _on_player_hit():
	lives -= 1
	lives_label.text = "Lives: " + str(lives)
	if lives <= 0:
		game_over()

func _on_scrap_dodged(scrap_node):
	if is_instance_valid(scrap_node) and scrap_node.position.x > -1000:
		score += 10
		score_label.text = "Score: " + str(score)
		if score % 50 == 0:
			timer.wait_time = max(timer.wait_time - 0.1, 0.2)
			base_scrap_speed += 30

func game_over():
	Engine.time_scale = 0
	var go_label = find_child("GameOverLabel", true, false)
	if go_label: go_label.visible = true
