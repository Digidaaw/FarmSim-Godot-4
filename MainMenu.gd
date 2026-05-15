extends Node2D

func _ready():
	#Utils.save_game()
	Utils.load_game()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://World.tscn")
	
