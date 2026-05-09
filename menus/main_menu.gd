extends Control

func _on_play_button_pressed() -> void:
	musicmanager.play()
	get_tree().change_scene_to_file("res://gameplay/gameplay_scene.tscn")
	##$Music.play()
