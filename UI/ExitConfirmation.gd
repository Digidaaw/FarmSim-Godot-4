extends Control

signal confirmed
signal canceled

@onready var yes_btn: Button = $Window/VBox/HBox/YesBtn
@onready var no_btn: Button = $Window/VBox/HBox/NoBtn

func _ready() -> void:
	# Tetap jalan walau game sedang di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	yes_btn.pressed.connect(_on_yes_pressed)
	no_btn.pressed.connect(_on_no_pressed)
	
	# Set focus ke tombol Tidak untuk keamanan
	no_btn.grab_focus()

func _on_yes_pressed() -> void:
	confirmed.emit()
	queue_free()

func _on_no_pressed() -> void:
	canceled.emit()
	queue_free()
