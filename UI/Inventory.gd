extends Control

var dragging = false
var click_radius = 40
var posClicked

var default_open_position: Vector2
var is_sliding := false

var ButtonInfo = {
	"Name": "Corn",
	"Count": 0,
}


@onready var slotContainer = get_node("SlotContainer")
@onready var SlotButtons = [
	get_node("SlotContainer/Slot"),
	get_node("SlotContainer/Slot2"),
	get_node("SlotContainer/Slot3"),
	get_node("SlotContainer/Slot4"),
	get_node("SlotContainer/Slot5"),
	get_node("SlotContainer/Slot6"),
	get_node("SlotContainer/Slot7"),
	get_node("SlotContainer/Slot8"),
	get_node("SlotContainer/Slot9"),
	get_node("SlotContainer/Slot10"),
	get_node("SlotContainer/Slot11"),
	get_node("SlotContainer/Slot12"),
]

func _ready() -> void:
	# Simpan posisi awal desain dari editor
	default_open_position = position
	position = default_open_position + Vector2(0, size.y + 20)
	self.hide()
	Game.inventory_updated.connect(_on_inventory_updated)
func _input(event):
	if event.is_action_pressed("Inventory") and not is_sliding:
		var ui_node = get_tree().root.find_child("UI", true, false)
		if ui_node != null:
			var box_inventory = ui_node.find_child("InventoryBox", true, false)
			if box_inventory != null and box_inventory.is_open:
				box_inventory.close_box()
				return
		
		if self.visible:
			close_inventory()
		else:
			open_inventory()


func open_inventory() -> void:
	is_sliding = true
	self.show()
	_refresh_inventory(true)
	position = default_open_position + Vector2(0, size.y + 20) # Mulai dari bawah
	
	var tween = create_tween()
	tween.tween_property(self, "position", default_open_position, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	await tween.finished
	is_sliding = false


func close_inventory() -> void:
	is_sliding = true
	var tween = create_tween()
	tween.tween_property(self, "position", default_open_position + Vector2(0, size.y + 20), 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	await tween.finished
	self.hide()
	is_sliding = false


func open_inventory_from_box(target_pos: Vector2, hidden_pos: Vector2) -> void:
	is_sliding = true
	self.show()
	_refresh_inventory(true)
	position = hidden_pos
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	await tween.finished
	is_sliding = false


func close_inventory_from_box(hidden_pos: Vector2) -> void:
	is_sliding = true
	var tween = create_tween()
	tween.tween_property(self, "position", hidden_pos, 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	await tween.finished
	self.hide()
	is_sliding = false


func _on_slot_gui_input(event: InputEvent, extra_arg_0: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if (event.position.length()) < click_radius:
			if not dragging and event.pressed:
				# START DRAGGING
				if slotContainer.get_child(extra_arg_0).has_item == true:
					dragging = true
					posClicked = slotContainer.get_child(extra_arg_0).position.x
					ButtonInfo["Name"] = slotContainer.get_child(extra_arg_0).itemName
					ButtonInfo["Count"] = slotContainer.get_child(extra_arg_0).itemCount
					ButtonInfo["SourceIndex"] = extra_arg_0
					slotContainer.get_child(extra_arg_0).clear_item()
					
		if dragging and not event.pressed:
			dragging = false
			slotContainer.get_child(extra_arg_0).get_node("Item").position = Vector2(20,20)
			get_node("Sprite2D").hide()
			
			var dropped = false
			var mouse_pos = get_viewport().get_mouse_position()

			# Cek apakah drop di InventoryBox
			var ui_node = get_tree().root.find_child("UI", true, false)
			var box_inventory = null
			if ui_node != null:
				box_inventory = ui_node.find_child("InventoryBox", true, false)
				
			if box_inventory != null and box_inventory.is_open:
				var box_slot_container = box_inventory.get_node("SlotContainer")
				if box_slot_container != null:
					for i in box_inventory.SlotButtons.size():
						var box_slot = box_inventory.SlotButtons[i]
						var box_actual_size = box_slot.size * box_slot.get_global_transform().get_scale()
						var box_slot_rect = Rect2(box_slot.global_position, box_actual_size)
						if box_slot_rect.has_point(mouse_pos):
							var items = Game.get_unified_inventory()
							if ButtonInfo["SourceIndex"] < items.size():
								var item = items[ButtonInfo["SourceIndex"]]
								if item != null:
									# Pindahkan ke box di slot i
									box_inventory.transfer_to_box(item, i)
							dropped = true
							break

			# Jika tidak drop di box, cek apakah drop di player inventory sendiri
			if not dropped:
				for i in SlotButtons.size():
					var slot = slotContainer.get_child(i)
					var actual_size = slot.size * slot.get_global_transform().get_scale()
					var slot_rect = Rect2(slot.global_position, actual_size)

					if slot_rect.has_point(mouse_pos):
						_move_harvest_item(ButtonInfo["SourceIndex"], i)
						dropped = true
						break

			_refresh_inventory(true)
			if box_inventory != null and box_inventory.is_open:
				box_inventory._refresh_box()
			
	if event is InputEventMouseMotion and dragging:
		get_node("Sprite2D").show()
		get_node("Sprite2D").texture = slotContainer.get_child(extra_arg_0).get_node("Item").texture
		get_node("Sprite2D").global_position = get_viewport().get_mouse_position()


func _move_harvest_item(source_index: int, target_index: int) -> void:
	_ensure_harvest_slots(max(source_index, target_index) + 1)

	var moved_item = Game.Harvest[source_index]
	if moved_item == null:
		_refresh_inventory(true)
		return

	if source_index == target_index:
		_refresh_inventory(true)
		return

	var target_item = Game.Harvest[target_index]
	Game.Harvest[target_index] = moved_item
	Game.Harvest[source_index] = target_item

	_trim_empty_harvest_slots()
	_refresh_inventory(true)
	Utils.save_game()


func _ensure_harvest_slots(size: int) -> void:
	while Game.Harvest.size() < size:
		Game.Harvest.append(null)


func _trim_empty_harvest_slots() -> void:
	while Game.Harvest.size() > 0 and Game.Harvest[Game.Harvest.size() - 1] == null:
		Game.Harvest.pop_back()


func _on_inventory_updated() -> void:
	if visible and not dragging:
		_refresh_inventory()

func _refresh_inventory(force: bool = false) -> void:
	slotContainer.setInventory()
