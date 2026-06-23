extends Area2D

@export var box_id: String = "box_1"

@onready var prompt_panel: Panel = $Panel

var items: Array = []
var player_inside := false


func _ready() -> void:
	load_box()

	prompt_panel.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("Interact"):
		# Cari node "UI" terlebih dahulu
		var ui_node = get_tree().root.find_child("UI", true, false)
		if ui_node != null:
			# Cari InventoryBox di dalam "UI"
			var box_inventory = ui_node.find_child("InventoryBox", true, false)
			if box_inventory != null:
				# Jika sedang terbuka, pencet F akan menutupnya
				if box_inventory.is_open:
					box_inventory.close_box()
				# Jika sedang tertutup, pencet F akan membukanya
				else:
					open_box()


func open_box() -> void:
	# 1. Cari node induk bernama "UI"
	var ui_node = get_tree().root.find_child("UI", true, false)
	
	if ui_node == null:
		print("Node induk 'UI' tidak ditemukan")
		return

	# 2. Cari InventoryBox & Inventory spesifik di dalam node "UI"
	var box_inventory = ui_node.find_child("InventoryBox", true, false)
	var player_inventory = ui_node.find_child("Inventory", true, false)

	if box_inventory == null:
		print("InventoryBox UI tidak ditemukan di dalam UI")
		return

	if player_inventory == null:
		print("Inventory player UI tidak ditemukan di dalam UI")
		return

	box_inventory.open_box(self, player_inventory)


func add_item(item_id: String, amount: int) -> void:
	items.append({
		"id": item_id,
		"amount": amount
	})
	save_box()


func add_item_unified(item: Dictionary) -> void:
	add_item_unified_to_slot(item, -1)


func add_item_unified_to_slot(item: Dictionary, slot_index: int = -1, max_slots: int = -1) -> bool:
	var name = item.get("Name", "")
	var type = item.get("Type", "")
	var count = int(item.get("Count", 1))
	var icon = item.get("Icon", "")
	var frame = int(item.get("Frame", -1))

	if name == "" or count <= 0:
		return false

	if slot_index >= 0:
		if max_slots > 0 and slot_index >= max_slots:
			return false
		_ensure_slot_size(slot_index + 1)
		var slot_item = items[slot_index]
		if slot_item == null:
			items[slot_index] = _make_unified_item(name, type, count, icon, frame)
			save_box()
			return true
		if _can_stack_items(slot_item, name, type, frame):
			slot_item["Count"] = int(slot_item.get("Count", 0)) + count
			save_box()
			return true
		return false

	if type != "Tool":
		for i in range(items.size()):
			var box_item = items[i]
			if _can_stack_items(box_item, name, type, frame):
				box_item["Count"] = int(box_item.get("Count", 0)) + count
				save_box()
				return true

	for i in range(items.size()):
		if items[i] == null:
			items[i] = _make_unified_item(name, type, count, icon, frame)
			save_box()
			return true

	if max_slots > 0 and items.size() >= max_slots:
		return false

	items.append(_make_unified_item(name, type, count, icon, frame))
	save_box()
	return true


func _ensure_slot_size(size: int) -> void:
	while items.size() < size:
		items.append(null)


func _make_unified_item(name: String, type: String, count: int, icon: String, frame: int) -> Dictionary:
	return {
		"Name": name,
		"Type": type,
		"Count": count,
		"Icon": icon,
		"Frame": frame
	}


func _can_stack_items(box_item, name: String, type: String, frame: int) -> bool:
	if not (box_item is Dictionary):
		return false
	if type == "Tool":
		return false
	return box_item.get("Name", "") == name and box_item.get("Type", "") == type and int(box_item.get("Frame", -1)) == frame


func remove_item_at(index: int) -> void:
	if index >= 0 and index < items.size():
		items[index] = null
		# Compact: hapus semua null (tengah maupun akhir)
		# agar index UI selalu sesuai dengan index data.
		_compact_items()
		save_box()


func _compact_items() -> void:
	## Hapus semua slot null sehingga item selalu berurutan dari index 0.
	## Tanpa ini, item bisa tersimpan di index 5 sementara 0-4 null,
	## menyebabkan klik di slot 0 UI tidak menemukan item.
	var packed: Array = []
	for itm in items:
		if itm != null:
			packed.append(itm)
	items = packed


func save_box() -> void:
	Game.inventory_boxes[box_id] = items


func load_box() -> void:
	if Game.inventory_boxes.has(box_id):
		items = Game.inventory_boxes[box_id]
	else:
		items = []


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		prompt_panel.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		prompt_panel.visible = false
		
		# Otomatis tutup box jika player berjalan menjauh
		var ui_node = get_tree().root.find_child("UI", true, false)
		if ui_node != null:
			var box_inventory = ui_node.find_child("InventoryBox", true, false)
			if box_inventory != null and box_inventory.is_open:
				box_inventory.close_box()
