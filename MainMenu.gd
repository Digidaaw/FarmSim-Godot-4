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
	if Game.saved_scene_path != "" and ResourceLoader.exists(Game.saved_scene_path):
		if Game.saved_player_position != Vector2.ZERO:
			StageManager.stage_change(Game.saved_scene_path, Game.saved_player_position)
		else:
			StageManager.stage_change(Game.saved_scene_path)
	else:
		StageManager.stage_change(StageManager.MainWorld)


func _on_new_game_pressed() -> void:
	Game.reset_game()
	StageManager.stage_change(StageManager.MainWorld)

const SETTINGS_MENU_SCENE = preload("res://UI/SettingsMenu.tscn")

func _on_settings_pressed() -> void:
	var sm = SETTINGS_MENU_SCENE.instantiate()
	add_child(sm)
