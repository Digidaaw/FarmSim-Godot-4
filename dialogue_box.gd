extends CanvasLayer

signal dialogue_finished

@export var typing_speed: float = 0.03 # Waktu jeda antar karakter (detik)

# Jalur langsung ke nama node di editor
@onready var portrait: TextureRect = $TextureRect
@onready var background_panel: Panel = $BackgroundPanel
@onready var name_panel: Panel = $NamePanel
@onready var dialogue_text: RichTextLabel = $RichTextLabel
@onready var name_label: Label = $Label

var continue_label: Label = null
var dialog_lines: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var current_text: String = ""
var visible_characters_count: float = 0.0

func _ready() -> void:
	# Atur agar CanvasLayer memproses input bahkan saat game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pastikan CanvasLayer berada di layer terdepan
	layer = 100
	
	# Ambil content scale factor (stretch scale) dari viewport (misal 3.1)
	var stretch_scale = get_viewport().content_scale_factor
	
	# Kita gunakan skala target 2.0x terhadap resolusi fisik (bukan 1.0x kecil dan bukan 3.1x raksasa)
	var target_scale = 2.0
	scale = Vector2(target_scale / stretch_scale, target_scale / stretch_scale)
	
	# Ukuran layar dalam koordinat CanvasLayer yang sudah di-scale
	var screen_size = get_viewport().get_visible_rect().size / scale
	
	# Ambil ukuran dialogue box
	var bp_width = background_panel.size.x
	var bp_height = background_panel.size.y
	
	# Posisikan dialogue box di tengah bawah logical screen
	var target_x = (screen_size.x - bp_width) / 2
	var target_y = screen_size.y - bp_height - 10 # 10 pixel padding dari bawah
	
	# Hitung offset pergeseran dari posisi editor
	var offset = Vector2(target_x, target_y) - background_panel.position
	
	# Geser semua node anak dengan offset yang sama agar tata letak relatif terjaga
	background_panel.position += offset
	
	if portrait != null:
		portrait.position += offset
	if name_panel != null:
		name_panel.position += offset
	if dialogue_text != null:
		dialogue_text.position += offset
	if name_label != null:
		name_label.position += offset

func start_dialogue(char_name: String, lines: Array, portrait_tex: Texture2D = null) -> void:
	dialog_lines = lines
	current_line_index = 0
	
	# Tampilkan nama karakter
	if name_label != null:
		name_label.text = char_name
	if name_panel != null:
		name_panel.visible = (char_name != "")
	
	# Atur portrait karakter (gunakan gambar jika ada)
	if portrait != null:
		if portrait_tex != null:
			portrait.texture = portrait_tex
			portrait.show()
		else:
			portrait.hide()
		
	# Pause game agar player tidak bisa bergerak saat dialog berlangsung
	get_tree().paused = true
	
	# Tampilkan CanvasLayer menggunakan properti visible (tanpa mengubah posisi di editor)
	visible = true
	
	# Mulai baris teks pertama
	_show_line()

func _show_line() -> void:
	if current_line_index >= dialog_lines.size():
		_end_dialogue()
		return
		
	current_text = dialog_lines[current_line_index]
	
	if dialogue_text != null:
		dialogue_text.text = current_text
		dialogue_text.visible_characters = 0
		
	is_typing = true
	visible_characters_count = 0.0
	
	if continue_label != null:
		continue_label.hide()

func _physics_process(delta: float) -> void:
	if not visible:
		return
		
	if is_typing:
		visible_characters_count += delta / typing_speed
		if dialogue_text != null:
			dialogue_text.visible_characters = int(visible_characters_count)
			if dialogue_text.visible_characters >= current_text.length():
				dialogue_text.visible_characters = -1
				is_typing = false
				if continue_label != null:
					continue_label.show()
		else:
			is_typing = false

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
		if dialogue_text != null:
			dialogue_text.visible_characters = -1
		is_typing = false
		if continue_label != null:
			continue_label.show()
	else:
		# Lanjut ke baris berikutnya
		current_line_index += 1
		_show_line()

func _end_dialogue() -> void:
	get_tree().paused = false
	visible = false
	dialogue_finished.emit()
