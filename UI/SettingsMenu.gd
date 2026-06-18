extends Control

@onready var resolution_btn: OptionButton = $Window/VBox/Scroll/List/ResolutionRow/OptionButton
@onready var fullscreen_btn: CheckButton = $Window/VBox/Scroll/List/FullscreenRow/CheckButton
@onready var keybinds_list: VBoxContainer = $Window/VBox/Scroll/List/KeybindsList
@onready var reset_btn: Button = $Window/VBox/Buttons/ResetBtn
@onready var close_btn: Button = $Window/VBox/Buttons/CloseBtn

const PIXEL_FONT = preload("res://Sprout Lands - UI Pack - Basic pack/Sprout Lands - UI Pack - Basic pack/fonts/pixelFont-7-8x14-sproutLands.ttf")

var action_display_names := {
	"ui_up": "Jalan Ke Atas",
	"ui_down": "Jalan Ke Bawah",
	"ui_left": "Jalan Ke Kiri",
	"ui_right": "Jalan Ke Kanan",
	"Interact": "Interaksi / Bicara (F)",
	"Hoe": "Cangkul / Aksi (P)",
	"Inventory": "Buka Tas (E)",
	"CyclePocket": "Ganti Slot Barang (Q)"
}

var resolutions := [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

var rebinding_action := ""
var rebinding_button: Button = null

func _ready() -> void:
	# Add resolution options
	resolution_btn.clear()
	for res in resolutions:
		resolution_btn.add_item("%d x %d" % [res.x, res.y])
	
	# Select currently configured resolution
	var current_size = DisplayServer.window_get_size()
	var found_idx = 0
	for i in range(resolutions.size()):
		if abs(resolutions[i].x - current_size.x) < 10 and abs(resolutions[i].y - current_size.y) < 10:
			found_idx = i
			break
	resolution_btn.selected = found_idx
	
	# Fullscreen state
	var current_mode = DisplayServer.window_get_mode()
	fullscreen_btn.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Connect video signals
	resolution_btn.item_selected.connect(_on_resolution_selected)
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	
	# Connect buttons
	reset_btn.pressed.connect(_on_reset_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	
	# Populate keybinds
	_build_keybind_list()

func _build_keybind_list() -> void:
	# Clear list
	for child in keybinds_list.get_children():
		child.queue_free()
		
	# Loop controls
	for action in Utils.default_controls.keys():
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		
		var label = Label.new()
		label.text = action_display_names.get(action, action)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_override("font", PIXEL_FONT)
		label.add_theme_font_size_override("font_size", 11)
		row.add_child(label)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 24)
		btn.add_theme_font_override("font", PIXEL_FONT)
		btn.add_theme_font_size_override("font_size", 10)
		btn.text = Utils.get_key_label_for_action(action)
		btn.pressed.connect(func(): _start_rebind(action, btn))
		row.add_child(btn)
		
		keybinds_list.add_child(row)

func _start_rebind(action: String, btn: Button) -> void:
	if rebinding_action != "":
		return
	rebinding_action = action
	rebinding_button = btn
	btn.text = "<Tekan Tombol>"
	btn.release_focus()

func _input(event: InputEvent) -> void:
	if rebinding_action != "":
		if event is InputEventKey and event.pressed:
			var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if key != 0:
				# Double check: is this key already bound to another action?
				var is_duplicate = false
				var conflicting_action = ""
				for action in Utils.default_controls.keys():
					if action == rebinding_action:
						continue
					var other_events = InputMap.action_get_events(action)
					for other_event in other_events:
						if other_event is InputEventKey:
							var other_key = other_event.physical_keycode if other_event.physical_keycode != 0 else other_event.keycode
							if other_key == key:
								is_duplicate = true
								conflicting_action = action
								break
					if is_duplicate:
						break
				
				if is_duplicate:
					var action_name = action_display_names.get(conflicting_action, conflicting_action)
					Utils.notif("Tombol sudah digunakan untuk: " + action_name, true)
					_build_keybind_list()
					rebinding_action = ""
					rebinding_button = null
					get_viewport().set_input_as_handled()
					return
					
				# If not duplicate, bind key
				InputMap.action_erase_events(rebinding_action)
				var new_event = InputEventKey.new()
				new_event.physical_keycode = key
				new_event.keycode = key
				InputMap.action_add_event(rebinding_action, new_event)
				
				Utils.emit_signal("keybinds_changed")
				_build_keybind_list()
				
				rebinding_action = ""
				rebinding_button = null
				get_viewport().set_input_as_handled()

func _on_resolution_selected(index: int) -> void:
	var target_res = resolutions[index]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(target_res)
	fullscreen_btn.button_pressed = false
	
	# Center window
	var screen = DisplayServer.window_get_current_screen()
	var screen_size = DisplayServer.screen_get_size(screen)
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_size / 2 - window_size / 2)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var target_res = resolutions[resolution_btn.selected]
		DisplayServer.window_set_size(target_res)
		
		# Center window
		var screen = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)

func _on_reset_pressed() -> void:
	for action in Utils.default_controls.keys():
		var default_key = Utils.default_controls[action]
		InputMap.action_erase_events(action)
		var new_event = InputEventKey.new()
		new_event.physical_keycode = default_key
		InputMap.action_add_event(action, new_event)
	Utils.emit_signal("keybinds_changed")
	_build_keybind_list()

func _on_close_pressed() -> void:
	Utils.save_settings()
	queue_free()
