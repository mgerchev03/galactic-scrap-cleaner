extends Control

@onready var credits_panel = %Panel 
@onready var main_buttons = $VBoxContainer

func _ready():
	credits_panel.hide()

func _on_credits_button_pressed():
	credits_panel.show()
	main_buttons.hide()

func _on_close_credits_button_pressed():
	credits_panel.hide()
	main_buttons.show()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://mode_selection.tscn")
