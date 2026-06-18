extends CharacterBody2D

# --- Pengaturan Kecepatan & Navigasi ---
@export var speed: float = 40.0 # Kecepatan berjalan NPC
@export var patrol_radius: float = 80.0 # Radius maksimum jalan dari posisi awal spawn
@export var wait_time_min: float = 1.5 # Waktu tunggu minimal
@export var wait_time_max: float = 4.0 # Waktu tunggu maksimal

# --- Node Referensi ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = get_node_or_null("AreaInteraksi/Prompt") 
@onready var prompt_panel: Panel = get_node_or_null("AreaInteraksi/PromptPanel") 

# --- Variabel State ---
var spawn_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var current_state: String = "idle" # "idle" atau "walking"
var last_direction: String = "down" # "down", "up", "left", "right"
var wait_timer: float = 0.0
var walk_timeout: float = 0.0 # Batas waktu jalan agar tidak stuck selamanya

var player_in_range := false
var player_node: Node2D = null

# --- Bank Percakapan (Sesuai Waktu Game) ---
const DIALOGUE_MORNING = [
	"Selamat pagi! Udara hari ini terasa sangat segar.",
	"Semoga harimu menyenangkan di kebun!",
	"Pagi-pagi begini paling enak mulai bersiap-siap kerja."
]
const DIALOGUE_AFTERNOON = [
	"Halo! Panas sekali ya siang ini.",
	"Jangan lupa menyiram tanamanmu agar tidak layu.",
	"Hari sudah siang, apakah pekerjaanmu di kebun lancar?"
]
const DIALOGUE_NIGHT = [
	"Malam yang tenang... Sangat sunyi di luar rumah.",
	"Hari sudah larut malam, tidurlah agar besok bangun segar.",
	"Waktunya beristirahat dari pekerjaan kebun."
]

func _ready() -> void:
	spawn_position = global_position
	wait_timer = randf_range(wait_time_min, wait_time_max)
	
	# Hubungkan signal sensor area interaksi
	if has_node("AreaInteraksi"):
		$AreaInteraksi.body_entered.connect(_on_area_body_entered)
		$AreaInteraksi.body_exited.connect(_on_area_body_exited)
		
	_update_prompt_text()
	if Utils.has_signal("keybinds_changed"):
		Utils.keybinds_changed.connect(_update_prompt_text)
		
	# Sembunyikan prompt F di awal
	_set_prompt_visible(false)

func _update_prompt_text() -> void:
	if prompt != null:
		prompt.text = Utils.get_key_label_for_action("Interact")

func _physics_process(delta: float) -> void:
	# 1. Jika player berada di jangkauan dekat, NPC berhenti & hadap player
	if player_in_range and player_node != null:
		velocity = Vector2.ZERO
		_face_node(player_node)
		_play_animation("Idle")
		
		# Deteksi interaksi tombol F
		if Input.is_action_just_pressed("Interact"):
				chat()
		return

	# 2. Logic AI State Machine
	match current_state:
		"idle":
			velocity = Vector2.ZERO
			_play_animation("Idle")
			
			wait_timer -= delta
			if wait_timer <= 0.0:
				_choose_new_target()
				
		"walking":
			# Hitung arah ke target
			var direction = global_position.direction_to(target_position)
			velocity = direction * speed
			
			# Set arah hadap animasi berdasarkan pergerakan
			_set_direction_from_velocity(velocity)
			_play_animation("Walk")
			
			# Gerakkan NPC
			move_and_slide()
			
			# Cek batas waktu jalan (Timeout) agar tidak berjalan menabrak tembok selamanya
			walk_timeout -= delta
			if walk_timeout <= 0.0:
				current_state = "idle"
				wait_timer = randf_range(wait_time_min, wait_time_max)
				return

			# Cek apakah sudah sampai ke tujuan
			if global_position.distance_to(target_position) < 5.0:
				current_state = "idle"
				wait_timer = randf_range(wait_time_min, wait_time_max)

# --- FUNGSI HELPER PERGERAKAN ---

# Pilih koordinat target secara acak dalam radius patroli
func _choose_new_target() -> void:
	var angle = randf() * PI * 2
	var distance = randf() * patrol_radius
	# --- Tambahkan * distance di ujung baris ini ---
	target_position = spawn_position + Vector2(cos(angle), sin(angle)) * distance
	# -----------------------------------------------
	current_state = "walking"
	walk_timeout = 5.0 # NPC diberi waktu maksimal 5 detik untuk sampai ke tujuan

# Tentukan arah hadap animasi (down/up/left/right) dari pergerakan
func _set_direction_from_velocity(vel: Vector2) -> void:
	if vel.length() < 0.1:
		return
	if abs(vel.x) > abs(vel.y):
		last_direction = "right" if vel.x > 0 else "left"
	else:
		last_direction = "down" if vel.y > 0 else "up"

# Buat NPC memutar badan menghadap ke arah player
func _face_node(target: Node2D) -> void:
	var diff = target.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		last_direction = "right" if diff.x > 0 else "left"
	else:
		last_direction = "down" if diff.y > 0 else "up"

# Jalankan animasi secara dinamis (Walk Down, Idle Up, dll.)
func _play_animation(anim_prefix: String) -> void:
	var anim_name = anim_prefix + " " + last_direction.capitalize()
	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

# --- FUNGSI PERCAKAPAN (CHAT) ---

const DIALOGUE_BOX_SCENE = preload("res://dialogue_box.tscn")

func chat() -> void:
	print("=== DEBUG NPC: INTERAKSI TOMBOL F ===")
	# Cegah double trigger jika dialog box sudah ada di dalam scene utama
	if get_tree().current_scene.has_node("DialogueBox"):
		print("Debug NPC: DialogueBox terdeteksi masih ada di scene utama, batalkan pembukaan baru.")
		return
		
	print("Debug NPC: Menyiapkan kumpulan dialog...")
	var dialogue_pool = []
	var hour = Game.game_hour
	print("Debug NPC: Jam game saat ini -> ", hour)
	
	# Pilih kelompok dialog berdasarkan jam in-game saat ini
	if hour >= 6 and hour < 12:
		dialogue_pool = DIALOGUE_MORNING
		print("Debug NPC: Menggunakan kumpulan dialog Pagi.")
	elif hour >= 12 and hour < 19:
		dialogue_pool = DIALOGUE_AFTERNOON
		print("Debug NPC: Menggunakan kumpulan dialog Siang/Sore.")
	else:
		dialogue_pool = DIALOGUE_NIGHT
		print("Debug NPC: Menggunakan kumpulan dialog Malam.")
		
	# Ambil baris teks acak dari kelompok dialog terpilih
	var random_line = dialogue_pool[randi() % dialogue_pool.size()]
	print("Debug NPC: Kalimat terpilih -> ", random_line)
	
	# Instantiate dialogue box
	print("Debug NPC: Melakukan instantiate pada dialogue_box.tscn...")
	var db = DIALOGUE_BOX_SCENE.instantiate()
	get_tree().current_scene.add_child(db)
	print("Debug NPC: Instansiasi ditambahkan ke scene utama. Nama node: ", db.name)
	
	# Load portrait Pinku jika ada
	var portrait_path = "res://Sprout Lands - Sprites - Basic pack/Characters/Sprite_NPC_Girl.png"
	print("Debug NPC: Mencoba memuat file portrait -> ", portrait_path)
	var portrait_tex = load(portrait_path)
	if portrait_tex != null:
		print("Debug NPC: Portrait berhasil dimuat.")
	else:
		print("Debug NPC WARNING: Gagal memuat portrait!")
	
	# Hubungi node CanvasLayer
	if db.has_node("CanvasLayer"):
		print("Debug NPC: Menghubungi node 'CanvasLayer'...")
		var cl = db.get_node("CanvasLayer")
		cl.start_dialogue("Pinku", [random_line], portrait_tex)
		
		# Hubungkan sinyal untuk membebaskan memori saat selesai
		cl.dialogue_finished.connect(func():
			print("Debug NPC: DialogueBox selesai dibaca, membebaskan memori (queue_free).")
			db.queue_free()
		)
	else:
		print("Debug NPC ERROR: Node 'CanvasLayer' tidak ditemukan di root DialogueBox!")



# --- DETEKSI AREA PLAYER ---

func _on_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.name == "Player" or body.name == "CharacterBody2D":
		player_in_range = true
		player_node = body
		_set_prompt_visible(true)

func _on_area_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body.name == "Player" or body.name == "CharacterBody2D":
		player_in_range = false
		player_node = null
		_set_prompt_visible(false)

func _set_prompt_visible(should_show: bool) -> void:
	if prompt != null:
		prompt.visible = should_show
	if prompt_panel != null:
		prompt_panel.visible = should_show
	if should_show:
		Game.register_interactable(self, "npc")
	else:
		Game.unregister_interactable(self)
