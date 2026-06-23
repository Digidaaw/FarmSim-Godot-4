extends Control

@export var box_gap := 12.0
@export var box_y_offset := 40.0

var opened_box = null
var player_inventory = null
var is_open := false
var selected_slot_index := -1

## Jumlah kolom di SlotContainer (harus sama dengan GridContainer.columns di scene)
const SLOT_COLUMNS := 6

var box_open_position: Vector2
var box_hidden_position: Vector2

@onready var slotContainer: GridContainer = get_node("SlotContainer")
@onready var selection: Sprite2D = get_node("Selection")
var SlotButtons := []

func _ready() -> void:
	box_open_position = position
	box_hidden_position = box_open_position + Vector2(0, size.y + 20)

	visible = false
	position = box_hidden_position

	if slotContainer != null:
		SlotButtons = slotContainer.get_children()
		for slot in SlotButtons:
			slot.texture_normal = null
	_update_selection()


func open_box(box, inventory_ui) -> void:
	if is_open:
		return

	opened_box = box
	player_inventory = inventory_ui
	is_open = true
	selected_slot_index = 0

	# Blok pergerakan player saat box terbuka
	_set_player_blocked(true)

	_refresh_box()

	print("Buka UI box:", opened_box.box_id)

	var viewport_size = get_viewport_rect().size
	var center_x = viewport_size.x / 2

	var box_size = size * scale
	var player_size = player_inventory.size * player_inventory.scale

	var is_player_fullscreen = player_inventory.size.x >= viewport_size.x - 10.0

	var visual_player_width = box_size.x if is_player_fullscreen else player_size.x

	var target_box_x = center_x + (box_gap / 2)
	var target_player_x : float
	if is_player_fullscreen:
		target_player_x = - (visual_player_width + box_gap) / 2
	else:
		target_player_x = center_x - (box_gap / 2) - visual_player_width

	var target_player_y = player_inventory.default_open_position.y

	var target_box_y = target_player_y + player_size.y - box_size.y - box_y_offset

	var target_player_pos = Vector2(target_player_x, target_player_y)
	var target_box_pos = Vector2(target_box_x, target_box_y)

	var hidden_player_pos = target_player_pos + Vector2(0, player_inventory.size.y + 20)
	var hidden_box_pos = target_box_pos + Vector2(0, size.y + 20)

	visible = true
	position = hidden_box_pos

	if player_inventory != null and player_inventory.has_method("open_inventory_from_box"):
		player_inventory.open_inventory_from_box(target_player_pos, hidden_player_pos)

	var tween := create_tween()
	tween.tween_property(self, "position", target_box_pos, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# Tunda update selector sampai layout GridContainer selesai
	await tween.finished
	call_deferred("_update_selection")


func close_box() -> void:
	if not is_open:
		return

	is_open = false

	# Bebaskan pergerakan player kembali
	_set_player_blocked(false)

	if player_inventory != null:
		if player_inventory.has_method("close_inventory_from_box"):
			var hidden_player_pos = player_inventory.position + Vector2(0, player_inventory.size.y + 20)
			player_inventory.close_inventory_from_box(hidden_player_pos)
		elif player_inventory.has_method("close_inventory"):
			player_inventory.close_inventory()

	var hidden_box_pos = position + Vector2(0, size.y + 20)
	var tween := create_tween()
	tween.tween_property(self, "position", hidden_box_pos, 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	await tween.finished

	visible = false
	opened_box = null
	player_inventory = null
	selected_slot_index = -1
	_update_selection()


## Blok / bebaskan input gerak player
func _set_player_blocked(blocked: bool) -> void:
	var player = get_tree().root.find_child("Player", true, false)
	if player != null:
		player.set_physics_process(not blocked)
		player.set_process(not blocked)


# ─────────────────────────────────────────────
# Input keyboard untuk navigasi & transfer
# ─────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	var total_slots = SlotButtons.size()
	if total_slots == 0:
		return

	# Navigasi dengan tombol arah (panah kiri/kanan/atas/bawah)
	if event.is_action_pressed("ui_right"):
		selected_slot_index = (selected_slot_index + 1) % total_slots
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_left"):
		selected_slot_index = (selected_slot_index - 1 + total_slots) % total_slots
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_down"):
		var next = selected_slot_index + SLOT_COLUMNS
		if next < total_slots:
			selected_slot_index = next
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_up"):
		var prev = selected_slot_index - SLOT_COLUMNS
		if prev >= 0:
			selected_slot_index = prev
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	# Tekan Enter/Space → pindahkan item yang dipilih ke inventory player
	elif event.is_action_pressed("ui_accept"):
		_transfer_selected_slot()
		get_viewport().set_input_as_handled()


func _transfer_selected_slot() -> void:
	if opened_box == null:
		return
	var box_items = opened_box.items
	if selected_slot_index < 0 or selected_slot_index >= box_items.size():
		return
	var item = box_items[selected_slot_index]
	if item == null:
		return
	transfer_from_box(item, selected_slot_index)
	_refresh_box()
	if player_inventory != null and player_inventory.has_method("_refresh_inventory"):
		player_inventory._refresh_inventory(true)


# ─────────────────────────────────────────────
func _refresh_box() -> void:
	for slot in SlotButtons:
		slot.clear_item()

	if selected_slot_index >= SlotButtons.size():
		selected_slot_index = -1
	_update_selection()

	if opened_box == null:
		return

	var box_items = opened_box.items
	for i in min(box_items.size(), SlotButtons.size()):
		var item = box_items[i]
		if item == null or not (item is Dictionary):
			continue
		var icon = Game.get_item_texture(item)
		SlotButtons[i].set_item(item["Name"], item["Count"], icon)


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_open and opened_box != null:
				selected_slot_index = slot_index
				call_deferred("_update_selection")

				var box_items = opened_box.items
				if slot_index < box_items.size():
					var item = box_items[slot_index]
					if item != null:
						transfer_from_box(item, slot_index)
						selected_slot_index = -1
						_refresh_box()
						if player_inventory != null and player_inventory.has_method("_refresh_inventory"):
							player_inventory._refresh_inventory(true)


func transfer_to_box(item: Dictionary) -> void:
	if opened_box == null:
		return

	# Selalu append ke slot kosong pertama (target_slot = -1).
	# Jangan gunakan selected_slot_index — itu bisa menyebabkan item
	# masuk ke index tengah sehingga slot 0..N-1 jadi null dan
	# klik pada slot tersebut tidak menemukan item.
	var added := false
	if opened_box.has_method("add_item_unified_to_slot"):
		added = opened_box.add_item_unified_to_slot(item, -1, SlotButtons.size())
	else:
		opened_box.add_item_unified(item)
		added = true

	if not added:
		print("Box penuh atau tidak bisa menampung item ini.")
		return

	# Hapus item dari player hanya setelah box berhasil menerima item.
	Game.remove_player_item(item)

	# Reset selector agar tidak menunjuk slot yang mungkin sudah berubah.
	selected_slot_index = -1

	# Refresh UI box
	_refresh_box()


func transfer_from_box(item: Dictionary, slot_index: int) -> void:
	if opened_box == null:
		return

	# Hapus item dari box
	opened_box.remove_item_at(slot_index)

	# Tambahkan item ke player
	Game.add_player_item(item)


func _update_selection() -> void:
	if selection == null:
		return
	if selected_slot_index < 0 or selected_slot_index >= SlotButtons.size():
		selection.hide()
		return

	# Hitung posisi center slot ke-N secara manual berdasarkan konstanta layout.
	# Data dari inventory_box.tscn & slot.tscn:
	#   slot size        = 40 x 40
	#   h_separation     = 0, v_separation = 5
	#   columns          = 6
	#   container offset = (7, 8)
	#   container scale  = 0.6
	var col := selected_slot_index % SLOT_COLUMNS
	var row := selected_slot_index / SLOT_COLUMNS

	# Posisi pusat slot dalam ruang lokal container (sebelum scale)
	var local_x := col * 40.0 + 20.0        # (40 + 0) * col + half(40)
	var local_y := row * 45.0 + 20.0        # (40 + 5) * row + half(40)

	# Konversi ke ruang lokal InventoryBox (tambah offset container lalu kalikan scale)
	selection.position = Vector2(7.0 + local_x * 0.6, 8.0 + local_y * 0.6)
	selection.show()


