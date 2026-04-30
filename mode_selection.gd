extends Control

func _on_game_one_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_game_two_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
