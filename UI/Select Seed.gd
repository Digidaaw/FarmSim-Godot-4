extends Control

@onready var seed_slots = [
	$Seed1,
	$Seed2,
]
@onready var mode_label: Label = $ModeLabel

func _ready():
	_sync_slots()

func _input(event):
	# 1. Ganti mode tas dengan tombol Q atau keyboard navigasi < >
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_Q:
			Game.cycle_pocket_mode()
			_sync_slots()
			return
		elif event.physical_keycode == KEY_COMMA or event.physical_keycode == KEY_LESS:
			Game.move_pocket_selection(-1)
			_sync_slots()
			get_viewport().set_input_as_handled()
			return
		elif event.physical_keycode == KEY_PERIOD or event.physical_keycode == KEY_GREATER:
			Game.move_pocket_selection(1)
			_sync_slots()
			get_viewport().set_input_as_handled()
			return

	# 2. Deteksi Scroll Mouse dan Klik Kiri Mouse
	if event is InputEventMouseButton and event.pressed:
		# Scroll ke atas (Pilih item sebelumnya)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			Game.move_pocket_selection(-1)
			_sync_slots()
			get_viewport().set_input_as_handled() # Konsumsi input agar tidak tembus ke kamera
			return
		# Scroll ke bawah (Pilih item berikutnya)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Game.move_pocket_selection(1)
			_sync_slots()
			get_viewport().set_input_as_handled()
			return

		# Klik kiri mouse untuk memilih slot secara langsung
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_local_mouse_position()
			var pocket_items = Game.get_current_pocket_items()
			var max_slots = min(seed_slots.size(), pocket_items.size())
			
			for i in range(max_slots):
				var slot = seed_slots[i]
				if slot.visible and _is_mouse_over_slot(slot, mouse_pos):
					Game.PocketSlotIndex = i
					Game.Selected = i
					_sync_slots()
					get_viewport().set_input_as_handled()
					return

	# 3. Navigasi keyboard/gamepad bawaan
	if event.is_action_pressed("Select_Up"):
		Game.move_pocket_selection(1)
		_sync_slots()
	if event.is_action_pressed("Select_Down"):
		Game.move_pocket_selection(-1)
		_sync_slots()
	
func _process(_delta):
	_sync_slots()
	
func hide_all():
	for slot in seed_slots:
		slot.get_node("Select").hide()

func _sync_slots():
	hide_all()
	var pocket_items = Game.get_current_pocket_items()
	var max_slots = min(seed_slots.size(), pocket_items.size())
	mode_label.text = Game.get_current_pocket_mode()
	if max_slots <= 0:
		for slot in seed_slots:
			slot.visible = false
		return

	Game.PocketSlotIndex = clamp(Game.PocketSlotIndex, 0, pocket_items.size() - 1)
	Game.Selected = Game.PocketSlotIndex
	for i in seed_slots.size():
		var slot = seed_slots[i]
		slot.visible = i < max_slots
		if not slot.visible:
			continue

		var item = pocket_items[i]
		var icon_path = str(item.get("Icon", ""))
		if icon_path != "":
			var tex = load(icon_path)
			slot.texture = tex
			if tex != null:
				slot.hframes = max(1, int(tex.get_width() / 16))
				slot.vframes = max(1, int(tex.get_height() / 16))
		slot.frame = int(item.get("Frame", 0))
		slot.get_node("Count").text = _format_count(item)
		if i == Game.PocketSlotIndex:
			slot.get_node("Select").show()

func _format_count(item: Dictionary) -> String:
	if item.get("Type", "") == "Tool":
		return ""
	return str(int(item.get("Count", 0)))

# Fungsi pembantu untuk mendeteksi apakah kursor mouse berada di dalam area slot Sprite2D
func _is_mouse_over_slot(slot: Node, mouse_pos: Vector2) -> bool:
	if not slot is Node2D or slot.texture == null:
		return false
		
	# Hitung ukuran pixel per-cell dari sprite sheet (lebar/hframes, tinggi/vframes)
	var w = slot.texture.get_width() / max(1, slot.hframes)
	var h = slot.texture.get_height() / max(1, slot.vframes)
	var size = Vector2(w, h) * slot.scale
	
	# Hitung batas kotak deteksi (Rect2)
	var pos = slot.position
	var rect: Rect2
	if slot.centered:
		rect = Rect2(pos - size / 2.0, size)
	else:
		rect = Rect2(pos, size)
		
	return rect.has_point(mouse_pos)
