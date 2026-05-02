extends Control

@onready var list = $ItemList

func _ready():
	list.clear()
	list.add_item("Зареждане...")
	load_leaderboard_data()

func load_leaderboard_data():
	# Пробвай този вариант, ако текущият не работи:
	var sw_result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	
	# Проверка дали изобщо сме получили нещо (за да не крашне пак)
	if sw_result == null or not sw_result.has("scores"):
		list.clear()
		list.add_item("Грешка при връзката със сървъра.")
		return
		
	list.clear()
	
	var scores = sw_result.scores
	if scores.is_empty():
		list.add_item("Все още няма записани резултати.")
	else:
		for score in scores:
			# Превръщаме точките в int, за да махнем ".0"
			var point_value = int(score.score) 
			var text = str(score.player_name) + ": " + str(point_value)
			list.add_item(text)

func _on_button_pressed():
	# Промени това на името на сцената, от която идваш
	get_tree().change_scene_to_file("res://game_1_menu.tscn")
