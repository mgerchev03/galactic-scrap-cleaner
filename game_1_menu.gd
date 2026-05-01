extends Control

func _on_game_one_button_pressed():
	# Пренасочваме към новото меню с Play/Leaderboard/Back
	get_tree().change_scene_to_file("res://game_1_menu.tscn")

func _on_leaderboard_button_pressed():
	# Сега вече бутонът ще отваря истинската класация
	get_tree().change_scene_to_file("res://leaderboard.tscn")

func _on_back_button_pressed():
	# Връща те към главното меню (Play/Credits/Quit)
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_play_button_pressed():
	print("Стартиране на играта...") # Това ще ти каже в конзолата дали кликът се засича
	get_tree().change_scene_to_file("res://main.tscn")
