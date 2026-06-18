extends Control

@onready var resume_btn: Button = $Window/VBox/ResumeBtn
@onready var settings_btn: Button = $Window/VBox/SettingsBtn
@onready var exit_btn: Button = $Window/VBox/ExitBtn

const SETTINGS_MENU_SCENE = preload("res://UI/SettingsMenu.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Tetap jalan walau game sedang di-pause
	
	resume_btn.pressed.connect(_on_resume_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func _on_resume_pressed() -> void:
	var node = self
	while node != null:
		if node.has_method("toggle_pause"):
			node.toggle_pause()
			break
		node = node.get_parent()

func _on_settings_pressed() -> void:
	var sm = SETTINGS_MENU_SCENE.instantiate()
	add_child(sm)

func _on_exit_pressed() -> void:
	get_tree().paused = false
	Utils.save_game()
	StageManager.stage_change("res://MainMenu.tscn")
