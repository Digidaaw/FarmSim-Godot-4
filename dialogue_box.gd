extends CanvasLayer

signal dialogue_finished

@export var typing_speed: float = 0.03 # Waktu jeda antar karakter (detik)

# Jalur langsung ke nama node (karena script nempel di CanvasLayer)
@onready var portrait: TextureRect = $TextureRect
@onready var background_panel: Panel = $BackgroundPanel
@onready var name_panel: Panel = $NamePanel
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var continue_label: Label = $Label

# Mencari Label nama di dalam NamePanel secara dinamis
var name_label: Label = null
var dialog_lines: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var current_text: String = ""
var visible_characters_count: float = 0.0

func _ready() -> void:
	# Atur agar CanvasLayer memproses input bahkan saat game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cari NameLabel di dalam NamePanel
	if name_panel != null:
		if name_panel.has_node("NameLabel"):
			name_label = name_panel.get_node("NameLabel")
		elif name_panel.has_node("Label"):
			name_label = name_panel.get_node("Label")
		else:
			# Cari anak bertipe Label pertama di NamePanel
			for child in name_panel.get_children():
				if child is Label:
					name_label = child
					break

func start_dialogue(char_name: String, lines: Array, portrait_tex: Texture2D = null) -> void:
	dialog_lines = lines
	current_line_index = 0
	
	# Tampilkan nama karakter
	if name_label != null:
		name_label.text = char_name
	name_panel.visible = (char_name != "")
	
	# Atur portrait karakter
	if portrait_tex != null:
		portrait.texture = portrait_tex
		portrait.show() # TextureRect punya show() karena turunan Control
		# Geser batas kiri RichTextLabel ke kanan agar tidak menabrak wajah
		dialogue_text.offset_left = 320.0
	else:
		portrait.hide()
		# Kembalikan batas kiri RichTextLabel ke kiri agar teks memanfaatkan seluruh ruang
		dialogue_text.offset_left = 40.0
		
	# Pause game agar player tidak bisa bergerak saat dialog berlangsung
	get_tree().paused = true
	
	# PERBAIKAN: Gunakan properti visible untuk CanvasLayer, bukan show()
	visible = true
	
	# Mulai baris teks pertama
	_show_line()

func _show_line() -> void:
	if current_line_index >= dialog_lines.size():
		_end_dialogue()
		return
		
	current_text = dialog_lines[current_line_index]
	dialogue_text.text = current_text
	dialogue_text.visible_characters = 0
	is_typing = true
	visible_characters_count = 0.0
	continue_label.hide()

func _physics_process(delta: float) -> void:
	if not visible:
		return
		
	if is_typing:
		visible_characters_count += delta / typing_speed
		dialogue_text.visible_characters = int(visible_characters_count)
		
		# Jika sudah selesai mengetik seluruh baris
		if dialogue_text.visible_characters >= current_text.length():
			dialogue_text.visible_characters = -1
			is_typing = false
			continue_label.show()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Deteksi tombol lanjut (F, Enter, Space, atau klik kiri mouse)
	var should_advance = false
	if event.is_action_pressed("Interact") or event.is_action_pressed("ui_accept"):
		should_advance = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		should_advance = true
		
	if should_advance:
		get_viewport().set_input_as_handled()
		_on_input_pressed()

func _on_input_pressed() -> void:
	if is_typing:
		# Lewati efek ketik (langsung tampilkan semua teks)
		dialogue_text.visible_characters = -1
		is_typing = false
		continue_label.show()
	else:
		# Lanjut ke baris berikutnya
		current_line_index += 1
		_show_line()

func _end_dialogue() -> void:
	get_tree().paused = false
	# PERBAIKAN: Gunakan properti visible untuk CanvasLayer, bukan hide()
	visible = false
	dialogue_finished.emit()
