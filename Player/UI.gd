extends CanvasLayer

@onready var pause_menu = $Root/PauseMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Penting agar input pause bisa diproses saat game berhenti
	if pause_menu:
		pause_menu.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Jangan toggle pause jika sedang di settings menu (child of PauseMenu)
		if pause_menu != null and pause_menu.visible:
			for child in pause_menu.get_children():
				if "SettingsMenu" in child.name:
					return
		toggle_pause()

func toggle_pause() -> void:
	if pause_menu == null:
		return
		
	if pause_menu.visible:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true
