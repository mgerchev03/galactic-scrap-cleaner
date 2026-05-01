extends Control

func _on_game_one_button_pressed():
	# ТРЯБВА ДА Е ТАКА:
	get_tree().change_scene_to_file("res://game_1_menu.tscn") 
	# АКО Е "res://main.tscn", ще пуска играта веднага!

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
