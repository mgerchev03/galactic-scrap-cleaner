extends Area2D

signal hit_player

var textures = [
	preload("res://Metal_Box.png"),
	preload("res://Satellite.png"),
	preload("res://Asteroid.png"),
]

@onready var sprite = $Sprite2D
@export var explosion_radius: float = 150.0
@export var chain_delay: float = 0.1

var speed = 350
var direction = Vector2.ZERO
var already_hit = false
var is_exploding: bool = false

func _ready():
	# Избор на случайна текстура
	if textures.size() > 0:
		sprite.texture = textures[randi() % textures.size()]
	
	rotation = randf_range(0, TAU)
	add_to_group("enemies")
	
	# Свързваме сигналите програмно, за да сме сигурни, че работят
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += direction * speed * delta
	
	# Махане при излизане от екрана
	var screen_size = get_viewport_rect().size
	if position.x < -200 or position.x > screen_size.x + 200 or \
	   position.y < -200 or position.y > screen_size.y + 200:
		queue_free()

# Сблъсък с друг Area2D (друг враг/астероид)
func _on_area_entered(area: Area2D):
	if area.is_in_group("enemies") and not is_exploding:
		print("ВЕРИЖНА РЕАКЦИЯ!")
		explode()

# Сблъсък с тяло (Играча)
func _on_body_entered(body):
	if body.name == "Player" and not already_hit and not is_exploding:
		already_hit = true 
		hit_player.emit()
		explode() # Или queue_free(), ако искаш само да изчезне без верига

func explode():
	if is_exploding: return
	is_exploding = true
	
	speed = 0
	# Смени името с новата картинка, която свалиш
	sprite.texture = preload("res://explosion.png") 
	
	# Намаляваме размера значително, защото 1200px е много за твоя екран
	sprite.scale = Vector2(0.15, 0.15) 
	
	# Уверяваме се, че Region е изключен, за да не реже новата картинка
	sprite.region_enabled = false
	
	# Махаме специалните материали, защото новата картинка ще е прозрачна сама по себе си
	sprite.material = null
	sprite.self_modulate = Color(1, 1, 1, 1)

	# Верижната реакция (както преди)
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy) and enemy != self:
			if enemy.get("is_exploding") == false:
				var dist = global_position.distance_to(enemy.global_position)
				if dist <= explosion_radius:
					get_tree().create_timer(chain_delay).timeout.connect(
						func(): if is_instance_valid(enemy): enemy.explode()
					)

	# ПЛАВНО ИЗЧЕЗВАНЕ
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
