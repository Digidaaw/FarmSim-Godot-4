extends Node2D

var dragging = false
var click_radius = 40
var posClicked

var ButtonInfo = {
	"Name": "Corn",
	"Count": 0,
}
var inventory_snapshot = ""


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
	self.hide()

func _process(_delta: float) -> void:
	if visible and not dragging:
		_refresh_inventory()

# Called when the node enters the scene tree for the first time.
func _input(event):
	if event.is_action_pressed("Inventory"):
		if self.visible == true:
			self.hide()
		else:
			self.show()
			_refresh_inventory(true)


func _on_slot_gui_input(event: InputEvent, extra_arg_0: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if (event.position.length()) < click_radius:
			if not dragging and event.pressed:
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
			for i in SlotButtons.size():
				var slot = slotContainer.get_child(i)
				var mouse_pos = get_viewport().get_mouse_position()
				var slot_rect = Rect2(slot.global_position, slot.size)

				if slot_rect.has_point(mouse_pos):
					_move_harvest_item(ButtonInfo["SourceIndex"], i)
					dropped = true
					break

			if not dropped:
				_refresh_inventory(true)
			
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

func _refresh_inventory(force: bool = false) -> void:
	var current_snapshot = JSON.stringify(Game.Harvest)
	if force or current_snapshot != inventory_snapshot:
		slotContainer.setInventory()
		inventory_snapshot = current_snapshot
