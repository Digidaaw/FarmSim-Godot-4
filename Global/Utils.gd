extends Node

const SAVE_PATH: String = "user://savegame.btn"
const SAVE_PASS: String = "password"
const NOTIF_SCENE = preload("res://Global/Notification.tscn")

var _persistent_notif: Node = null
var _timed_notif: Node = null
var _prompt_count: int = 0

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

func show_interaction_prompt(text: String = "F") -> void:
	_prompt_count += 1
	_persistent_notif.get_node("Label").text = text
	if _prompt_count == 1:
		_persistent_notif.show()

func hide_interaction_prompt() -> void:
	_prompt_count = max(0, _prompt_count - 1)
	if _prompt_count == 0:
		_persistent_notif.hide()

# Alias lama supaya script plot yang sudah ada tetap kompatibel.
func enter_plot(text: String = "F") -> void:
	show_interaction_prompt(text)

func exit_plot() -> void:
	hide_interaction_prompt()

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
		"Money": Game.Money,
		"Seeds": Game.Seeds,
		"ShippingBinItems": Game.ShippingBinItems,
		"GameDay": Game.game_day,
		"GameHour": Game.game_hour,
		"GameMinute": Game.game_minute,
		"LastShippingCollectDay": Game.last_shipping_collect_day,
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

			Game.Money = int(current_line.get("Money", Game.Money))

			var loaded_seeds = current_line.get("Seeds", Game.Seeds)
			if loaded_seeds is Dictionary:
				Game.Seeds = loaded_seeds

			var loaded_shipping_items = current_line.get("ShippingBinItems", [])
			if loaded_shipping_items is Array:
				Game.ShippingBinItems = loaded_shipping_items
			else:
				Game.ShippingBinItems = []

			Game.game_day = int(current_line.get("GameDay", Game.game_day))
			Game.game_hour = int(current_line.get("GameHour", Game.game_hour))
			Game.game_minute = int(current_line.get("GameMinute", Game.game_minute))
			Game.last_shipping_collect_day = int(current_line.get("LastShippingCollectDay", Game.last_shipping_collect_day))
	save_game.close()
