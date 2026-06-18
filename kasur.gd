extends Area2D

# Mendapatkan node parent CanvasGroup di bawah BedArea
@onready var prompt = get_node_or_null("NotifTidur")

var player_in_range = false
var player_node: Node2D = null # Menyimpan referensi player agar bisa dikunci posisinya

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_update_prompt_text()
	if Utils.has_signal("keybinds_changed"):
		Utils.keybinds_changed.connect(_update_prompt_text)
	
	# Matikan tulisan dan kotak saat pertama kali game dimulai
	if prompt != null:
		prompt.visible = false

func _update_prompt_text() -> void:
	if prompt != null:
		var label = prompt.get_node_or_null("Prompt")
		if label != null:
			label.text = "Tidur (" + Utils.get_key_label_for_action("Interact") + ")"

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("Interact"):
		sleep()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		player_node = body # Simpan referensi player
		# Tampilkan kotak dan tulisan secara bersamaan
		if prompt != null:
			prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		player_node = null # Hapus referensi player
		# Sembunyikan kotak dan tulisan saat player pergi
		if prompt != null:
			prompt.visible = false

func sleep() -> void:
	player_in_range = false
	if prompt != null:
		prompt.visible = false
		
	# Kunci pergerakan player agar diam di tempat selama tidur
	if player_node != null:
		player_node.set_physics_process(false)
		
	# ----------------------------------------------------
	# EFEK TRANSISI TIDUR (FADE OUT -> BLACK -> FADE IN)
	# ----------------------------------------------------
	
	# 1. Buat CanvasLayer dinamis agar layar hitam selalu di depan kamera
	var canvas_layer = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas_layer)
	
	# 2. Buat ColorRect hitam penutup layar
	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0) # Mulai dari transparan
	color_rect.anchor_right = 1.0 # Penuhi lebar layar
	color_rect.anchor_bottom = 1.0 # Penuhi tinggi layar
	canvas_layer.add_child(color_rect)
	
	# 3. Jalankan Tween transisi
	var tween = create_tween()
	
	# FADE OUT: Gelapkan layar ke hitam selama 0.7 detik
	tween.tween_property(color_rect, "color:a", 1.0, 0.7)
	
	# EKSEKUSI DATA HARI (Saat layar hitam total)
	tween.tween_callback(func():
		# Majukan hari global
		Game.advance_day()
		
		# Reset waktu global ke jam 6 pagi
		Game.game_hour = 6
		Game.game_minute = 0
		
		# Reset waktu lokal pada scene utama agar UI jam ikut terupdate
		var root = get_tree().current_scene
		if root != null:
			if "game_hour" in root:
				root.game_hour = 6
			if "game_minute" in root:
				root.game_minute = 0
			if "time_passed" in root:
				root.time_passed = 0.0
			
			# Segarkan visual pertumbuhan tanaman di kebun secara langsung
			var dirt_container = root.get_node_or_null("DirtContainer")
			if dirt_container != null and dirt_container.has_method("refresh_all_plants"):
				dirt_container.refresh_all_plants()
		
		# Simpan data terbaru
		#Utils.save_game()
		Utils.notif("Selamat Pagi! Hari %d dimulai 🌅" % Game.game_day)
	)
	
	# TIDUR SEJENAK: Tahan layar hitam selama 0.6 detik
	tween.tween_interval(0.6)
	
	# FADE IN: Terangkan layar kembali selama 0.7 detik
	tween.tween_property(color_rect, "color:a", 0.0, 0.7)
	
	# SELESAI TRANSISI: Bersihkan node hitam & bebaskan pergerakan player
	tween.tween_callback(func():
		canvas_layer.queue_free()
		if player_node != null:
			player_node.set_physics_process(true)
	)
