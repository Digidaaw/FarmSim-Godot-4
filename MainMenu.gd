extends Control

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
	Utils.save_game()

func _on_play_pressed() -> void:
	StageManager.stage_change(StageManager.MainWorld)
