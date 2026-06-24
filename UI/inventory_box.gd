extends Control

@export var box_gap := 12.0
@export var box_y_offset := 40.0
@export var selection_scale_multiplier := 1.0

var opened_box = null
var player_inventory = null
var is_open := false
var selected_slot_index := -1
var is_focus_on_box := true

	

var box_open_position: Vector2
var box_hidden_position: Vector2

@onready var slotContainer: GridContainer = get_node("SlotContainer")
@onready var selection: Sprite2D = get_node("Selection")
var SlotButtons := []

var dragging := false
var drag_sprite: Sprite2D
var drag_source_index := -1

func _ready() -> void:
	box_open_position = position
	box_hidden_position = box_open_position + Vector2(0, size.y + 20)

	visible = false
	position = box_hidden_position

	if slotContainer != null:
		SlotButtons = slotContainer.get_children()
		for slot in SlotButtons:
			slot.custom_minimum_size = Vector2(40.0, 40.0)
			slot.texture_normal = null
	
	if selection != null:
		selection.hide()
		
	_update_selection()

	drag_sprite = Sprite2D.new()
	drag_sprite.visible = false
	drag_sprite.z_index = 100
	drag_sprite.scale = Vector2(1.5, 1.5)
	add_child(drag_sprite)

func _process(delta: float) -> void:
	if dragging and drag_sprite != null:
		drag_sprite.global_position = get_global_mouse_position()


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

	# Sejajarkan bagian atas box dengan bagian atas inventory
	var target_box_y = target_player_y

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

	if selection != null:
		selection.hide()

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

	var current_slots = SlotButtons if is_focus_on_box else player_inventory.SlotButtons
	var total_slots = current_slots.size()
	if total_slots == 0:
		return

	var columns = slotContainer.columns if is_focus_on_box else 6

	if event.is_action_pressed("ui_right"):
		if (selected_slot_index + 1) % columns == 0:
			if not is_focus_on_box:
				is_focus_on_box = true
				selected_slot_index -= (columns - 1)
				if selected_slot_index >= SlotButtons.size():
					selected_slot_index = SlotButtons.size() - 1
			else:
				selected_slot_index = (selected_slot_index + 1) % total_slots
		else:
			selected_slot_index = (selected_slot_index + 1) % total_slots
			
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_left"):
		if selected_slot_index % columns == 0:
			if is_focus_on_box:
				is_focus_on_box = false
				selected_slot_index += (columns - 1)
				if selected_slot_index >= player_inventory.SlotButtons.size():
					selected_slot_index = player_inventory.SlotButtons.size() - 1
			else:
				selected_slot_index = (selected_slot_index - 1 + total_slots) % total_slots
		else:
			selected_slot_index = (selected_slot_index - 1 + total_slots) % total_slots
			
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_down"):
		var next = selected_slot_index + columns
		if next < total_slots:
			selected_slot_index = next
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_up"):
		var prev = selected_slot_index - columns
		if prev >= 0:
			selected_slot_index = prev
		call_deferred("_update_selection")
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_Z and event.pressed and not event.echo):
		_transfer_selected_slot()
		get_viewport().set_input_as_handled()


func _transfer_selected_slot() -> void:
	if opened_box == null:
		return
	
	if is_focus_on_box:
		var box_items = opened_box.items
		if selected_slot_index < 0 or selected_slot_index >= box_items.size():
			return
		var item = box_items[selected_slot_index]
		if item == null:
			return
		transfer_from_box(item, selected_slot_index)
	else:
		var items = Game.get_unified_inventory()
		if selected_slot_index < 0 or selected_slot_index >= items.size():
			return
		var item = items[selected_slot_index]
		if item == null:
			return
		transfer_to_box(item)
		
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
		if not dragging and event.pressed:
			if is_open and opened_box != null:
				selected_slot_index = slot_index
				call_deferred("_update_selection")

				var box_items = opened_box.items
				if slot_index < box_items.size():
					var item = box_items[slot_index]
					if item != null:
						dragging = true
						drag_source_index = slot_index
						
						var icon = Game.get_item_texture(item)
						drag_sprite.texture = icon
						drag_sprite.visible = true
						
						SlotButtons[slot_index].clear_item()
						
		elif dragging and not event.pressed:
			dragging = false
			drag_sprite.visible = false
			
			var dropped = false
			var mouse_pos = get_viewport().get_mouse_position()
			
			if player_inventory != null and player_inventory.visible:
				var p_slot_container = player_inventory.get_node("SlotContainer")
				if p_slot_container != null:
					for i in player_inventory.SlotButtons.size():
						var p_slot = player_inventory.SlotButtons[i]
						var p_actual_size = p_slot.size * p_slot.get_global_transform().get_scale()
						var p_slot_rect = Rect2(p_slot.global_position, p_actual_size)
						if p_slot_rect.has_point(mouse_pos):
							var box_items = opened_box.items
							if drag_source_index < box_items.size():
								var item = box_items[drag_source_index]
								if item != null:
									transfer_from_box(item, drag_source_index)
									dropped = true
							break
							
			if not dropped:
				for i in SlotButtons.size():
					var slot = SlotButtons[i]
					var actual_size = slot.size * slot.get_global_transform().get_scale()
					var slot_rect = Rect2(slot.global_position, actual_size)
					if slot_rect.has_point(mouse_pos):
						if i != drag_source_index:
							_move_box_item(drag_source_index, i)
						dropped = true
						break
			
			_refresh_box()
			if player_inventory != null and player_inventory.has_method("_refresh_inventory"):
				player_inventory._refresh_inventory(true)

func _move_box_item(from_idx: int, to_idx: int) -> void:
	if opened_box == null: return
	var items = opened_box.items
	if from_idx < 0 or from_idx >= items.size(): return
	var item = items[from_idx]
	if item == null: return
	
	items.remove_at(from_idx)
	if to_idx >= items.size():
		items.append(item)
	else:
		items.insert(to_idx, item)
	opened_box.save_box()


func transfer_to_box(item: Dictionary, target_slot_index: int = -1) -> void:
	if opened_box == null:
		return

	var added := false
	if opened_box.has_method("add_item_unified_to_slot"):
		added = opened_box.add_item_unified_to_slot(item, target_slot_index, SlotButtons.size())
	else:
		opened_box.add_item_unified(item)
		added = true

	if not added:
		print("Box penuh atau tidak bisa menampung item ini.")
		return

	# Hapus item dari player hanya setelah box berhasil menerima item.
	Game.remove_player_item(item)


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

	if selected_slot_index < 0:
		selection.hide()
		return

	var current_slots = SlotButtons if is_focus_on_box else player_inventory.SlotButtons
	if selected_slot_index >= current_slots.size():
		return

	var slot = current_slots[selected_slot_index]
	
	# Gunakan ukuran dasar slot (40x40) dikalikan dengan skala globalnya
	# Ini mengatasi masalah di mana get_global_rect().size bernilai 0 sebelum layout
	var slot_scale = slot.get_global_transform().get_scale()
	var actual_size = Vector2(40.0, 40.0) * slot_scale
	var slot_center = slot.global_position + (actual_size / 2.0)
	
	selection.centered = true
	selection.global_position = slot_center
	selection.global_scale = slot_scale * selection_scale_multiplier
	selection.show()
