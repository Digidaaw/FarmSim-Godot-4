extends Node

const SAVE_PATH: String = "user://savegame.btn"
const SAVE_PASS: String = "password"
const NOTIF_SCENE = preload("res://Global/Notification.tscn")

var _persistent_notif: Node = null
var _timed_notif: Node = null
var _plot_count: int = 0  # berapa plot yang sedang diinjak player

func _ready() -> void:	
	# Pre-instantiate sekali agar show_notif tidak perlu instantiate lagi
	_persistent_notif = NOTIF_SCENE.instantiate()
	add_child(_persistent_notif)
	_persistent_notif.hide()

func notif(text) -> void:
	if _timed_notif == null:
		_timed_notif = NOTIF_SCENE.instantiate()
		_timed_notif.get_node("Label").text = str(text)
		add_child(_timed_notif)
		await get_tree().create_timer(0.7).timeout
		if _timed_notif != null:
			_timed_notif.queue_free()
			_timed_notif = null

# Dipanggil saat player masuk area plot
func enter_plot(text: String) -> void:
	_plot_count += 1
	if _plot_count == 1:  # baru masuk plot pertama
		_persistent_notif.get_node("Label").text = text
		_persistent_notif.show()

# Dipanggil saat player keluar area plot
func exit_plot() -> void:
	_plot_count = max(0, _plot_count - 1)
	if _plot_count == 0:  # tidak ada plot yang diinjak lagi
		_persistent_notif.hide()

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
