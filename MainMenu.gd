extends Control

var plottemp = []

func _ready():

	Utils.load_game()
	# 2. Bersihkan tanaman yang sudah dipanen tanpa merusak indeks tanah
	for i in range(Game.Plot.size()):
		var data = Game.Plot[i]
		if data is Dictionary and data.get("Harvested", false) == true:
			Game.Plot[i] = null

	Utils.save_game()

func _on_play_pressed() -> void:
	StageManager.stage_change(StageManager.MainWorld)


func _on_new_game_pressed() -> void:
	Game.reset_game()
	StageManager.stage_change(StageManager.MainWorld)
