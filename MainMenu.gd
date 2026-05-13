extends Node2D

func _ready():
	Utils.load_game()
	Game.Plot += [{
		"Seed": 0,
		"Time": 0,
	}]
	print(Game.Plot)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://World.tscn")
	
