extends Control

# Увери се, че пътят до твоя ItemList или List е правилен
@onready var list = %ItemList

func _ready():
	list.clear()
	list.add_item("Зареждане...") # Дай сигнал на играча, че нещо се случва
	load_leaderboard_data()

func load_leaderboard_data():
	var sw_result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	list.clear() # Изчисти "Зареждане..."
	
	if sw_result == null or not sw_result.has("scores"):
		list.add_item("Грешка при връзката със сървъра.")
		return
	
	# ... останалата част от логиката за добавяне на елементи

	# 4. Проверка дали класацията не е празна
	if sw_result.scores.is_empty():
		list.add_item("Все още няма записани резултати.")
		return

	# 5. ЦИКЪЛЪТ: Вземаме всеки резултат и го изписваме на екрана автоматично
	for score in sw_result.scores:
		# Създаваме текста за всеки ред (напр. "Marian: 1750")
		var player_name = str(score.player_name)
		var player_score = str(int(score.score))
		var display_text = player_name + ": " + player_score
		
		# Добавяме го в списъка на екрана
		list.add_item(display_text)

# Функция за бутона "Close" или "Back"
func _on_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
