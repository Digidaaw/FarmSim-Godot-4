extends Node

const SAVE_PATH: String = "user://savegame.btn"
const SAVE_PASS: String = "password"
const NOTIF_SCENE = preload("res://Global/Notification.tscn")
const SETTINGS_PATH = "user://settings.cfg"

signal keybinds_changed

var default_controls := {
	"ui_up": KEY_W,
	"ui_down": KEY_S,
	"ui_left": KEY_A,
	"ui_right": KEY_D,
	"Interact": KEY_F,
	"Hoe": KEY_P,
	"Inventory": KEY_E,
	"CyclePocket": KEY_Q
}

var _persistent_notif: Node = null
var _timed_notif: Node = null
var _prompt_count: int = 0

func _ready() -> void:	
	# Pre-instantiate sekali agar show_notif tidak perlu instantiate lagi
	_persistent_notif = NOTIF_SCENE.instantiate()
	add_child(_persistent_notif)
	_persistent_notif.hide()
	
	# Initialize dynamic inputs and load settings
	load_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	
	var window_size = DisplayServer.window_get_size()
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	config.set_value("video", "width", window_size.x)
	config.set_value("video", "height", window_size.y)
	config.set_value("video", "fullscreen", is_fullscreen)
	
	for action in default_controls.keys():
		var events = InputMap.action_get_events(action)
		var keycode = default_controls[action]
		for event in events:
			if event is InputEventKey:
				keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
				break
		config.set_value("controls", action, keycode)
		
	var err = config.save(SETTINGS_PATH)
	if err == OK:
		print("Settings saved successfully to: ", SETTINGS_PATH)
	else:
		print("Error saving settings to: ", SETTINGS_PATH, " Code: ", err)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	# Ensure all actions exist in InputMap
	for action in default_controls.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			
	if err == OK:
		print("Settings loaded successfully from: ", SETTINGS_PATH)
		var width = config.get_value("video", "width", 960)
		var height = config.get_value("video", "height", 540)
		var fullscreen = config.get_value("video", "fullscreen", false)
		
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(width, height))
			
			# Center window
			var screen = DisplayServer.window_get_current_screen()
			var screen_size = DisplayServer.screen_get_size(screen)
			var window_size = DisplayServer.window_get_size()
			DisplayServer.window_set_position(screen_size / 2 - window_size / 2)
			
		for action in default_controls.keys():
			var default_key = default_controls[action]
			var key = config.get_value("controls", action, default_key)
			
			InputMap.action_erase_events(action)
			var new_event = InputEventKey.new()
			new_event.physical_keycode = key
			new_event.keycode = key
			InputMap.action_add_event(action, new_event)
	else:
		print("No settings file found or error loading settings (", err, "). Applying defaults.")
		# Apply default keybinds if no config exists
		for action in default_controls.keys():
			var default_key = default_controls[action]
			InputMap.action_erase_events(action)
			var new_event = InputEventKey.new()
			new_event.physical_keycode = default_key
			new_event.keycode = default_key
			InputMap.action_add_event(action, new_event)
			
		# Center window on first run
		var screen = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)

func get_key_label_for_action(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey:
			var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(keycode)
	return ""

func notif(text, is_error: bool = false) -> void:
	if _timed_notif == null:
		_timed_notif = NOTIF_SCENE.instantiate()
		_timed_notif.get_node("Panel/Label").text = str(text)
		_timed_notif.get_node("Panel").set_meta("is_error", is_error)
		add_child(_timed_notif)
		var duration = 2.0 if is_error else 0.7
		await get_tree().create_timer(duration).timeout
		if _timed_notif != null:
			_timed_notif.queue_free()
			_timed_notif = null

func show_interaction_prompt(text: String = "F") -> void:
	_prompt_count += 1
	_persistent_notif.get_node("Panel/Label").text = text
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
		if line.strip_edges() == "":
			continue
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
