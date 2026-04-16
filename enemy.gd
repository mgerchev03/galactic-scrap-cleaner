extends Area2D

@export var explosion_radius: float = 150.0
@export var chain_delay: float = 0.1
var is_exploding: bool = false

@onready var sprite = $Sprite2D # Увери се, че имаш Sprite2D като дете

func _on_area_entered(area: Area2D):
	if area.is_in_group("enemies") and not is_exploding:
		explode()

func explode():
	if is_exploding: return
	is_exploding = true
	
	# 1. Сменяме текстурата
	sprite.texture = preload("res://explosion.png")
	
	# 2. МАХАМЕ ЧЕРНОТО: Създаваме материал чрез код
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	
	# 3. Настройваме размера (пробвай 0.4, ако 0.3 е твърде малко)
	sprite.scale = Vector2(0.4, 0.4)
	sprite.rotation = 0 # Изправяме я
	
	# Верижната реакция
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy) and enemy != self:
			if enemy.get("is_exploding") == false:
				var dist = global_position.distance_to(enemy.global_position)
				if dist <= explosion_radius:
					get_tree().create_timer(chain_delay).timeout.connect(
						func(): if is_instance_valid(enemy): enemy.explode()
					)

	# Плавно изчезване
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
