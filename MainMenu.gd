extends Node2D

var plottemp = []

func _ready():
	Utils.load_game()

	var size = Game.Plot.size()
	var i = 0

	while i < size:
		var data = Game.Plot[i]

		if data is Dictionary:
			match data.get("Harvested", false):
				true:
					pass
				false:
					plottemp.append(data)
		i += 1

	Game.Plot = plottemp

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://World.tscn")
