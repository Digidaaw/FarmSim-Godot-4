extends Node

const SAVE_PATH: String = "user://savegame.btn"
const SAVE_PASS: String = "password"

const NOTIF_SCENE = preload("res://Global/Notification.tscn")

func notif(text):
	if get_child_count() == 0:
		var notif1 = NOTIF_SCENE.instantiate()
		notif1.get_node("Label").text = str(text)
		add_child(notif1)
		await get_tree().create_timer(3).timeout
		notif1.queue_free()

func get_file(is_write: bool) -> FileAccess:
	var password: String = SAVE_PASS
	
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		password = OS.get_unique_id()

	var mode: int
	
	if is_write:
		mode = FileAccess.WRITE	
	else:
		if not FileAccess.file_exists(SAVE_PATH):
			return 
		mode = FileAccess.READ

	var save_game := FileAccess.open_encrypted_with_pass(
		SAVE_PATH,
		mode,
		password
	)

	return save_game


func save_game() -> void:
	var save_game: FileAccess = get_file(true)

	if save_game == null:
		return

	var data: Dictionary = {
		"Plot": Game.Plot,
		"Harvest": Game.Harvest,
	}

	save_game.store_line(JSON.stringify(data))
	save_game.close()

func load_game() -> void:
	var save_game: FileAccess = get_file(false)

	if save_game == null:
		return

	while not save_game.eof_reached():
		var line: String = save_game.get_line()
		var current_line = JSON.parse_string(line)

		if current_line != null:
			var loaded_plot = current_line.get("Plot", [])
			if loaded_plot is Array:
				Game.Plot = loaded_plot
			else:
				Game.Plot = []

			var loaded_harvest = current_line.get("Harvest", [])
			if loaded_harvest is Array:
				Game.Harvest = loaded_harvest
			else:
				Game.Harvest = []
	save_game.close()
