extends Node2D

func _ready():
	Utils.load_game()

	var i = 0
	
	while i < Game.Plot.size():
		
		var data = Game.Plot[i]
		
		if data is Dictionary and data.get("Harvested", false):
			Game.Plot.pop_at(i)
		else:
			i += 1
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://World.tscn")
	
