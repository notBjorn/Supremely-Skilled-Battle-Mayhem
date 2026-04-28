extends Control

@onready var winner_label: Label = $CenterContainer/VBoxContainer/WinnerLabel

func _ready() -> void:
	winner_label.text = "Player %d Wins!" % GameState.winner

func _on_replay_button_pressed() -> void:
	GameState.winner = 0
	get_tree().change_scene_to_file("res://scenes/GameplayScene.tscn")

func _on_menu_button_pressed() -> void:
	GameState.winner = 0
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
