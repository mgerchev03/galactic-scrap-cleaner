extends Control

@onready var list = $ItemList

func _ready():
	list.clear()
	
	# Проверка за връзка със SilentWolf
	var sw_result = await SilentWolf.Scores.get_scores(10, "main").sw_get_scores_complete
	
	if sw_result == null or not sw_result.has("scores"):
		list.add_item("Грешка 403: Провери API ключа в Project Settings!")
		return

	var scores = sw_result.scores
	if scores.size() == 0:
		list.add_item("Няма намерени резултати.")
	else:
		for i in range(scores.size()):
			var entry = scores[i]
			var p_name = str(entry.player_name) if str(entry.player_name) != "" else "Anonymous"
			list.add_item(str(i+1) + ". " + p_name + ": " + str(int(entry.score)))

func _on_button_pressed():
	print("Натиснат е бутон за изход!")
	get_tree().change_scene_to_file("res://game_1_menu.tscn")
