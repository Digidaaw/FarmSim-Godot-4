extends Node2D

var dragging = false
var click_radius = 40
var posClicked

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
	self.hide()

# Called when the node enters the scene tree for the first time.
func _input(event):
	if event.is_action_pressed("Inventory"):
		if self.visible == true:
			self.hide()
		else:
			self.show()
			get_node("SlotContainer").setInventory()


func _on_slot_gui_input(event: InputEvent, extra_arg_0: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if (event.position.length()) < click_radius:
			if not dragging and event.pressed:
				if slotContainer.get_child(extra_arg_0).has_item == true:
					dragging = true
					posClicked = slotContainer.get_child(extra_arg_0).position.x
					ButtonInfo["Name"] = slotContainer.get_child(extra_arg_0).itemName
					ButtonInfo["Count"] = slotContainer.get_child(extra_arg_0).itemCount
					slotContainer.get_child(extra_arg_0).itemCount = 0
					slotContainer.get_child(extra_arg_0).itemName = ""
					slotContainer.get_child(extra_arg_0).has_item = false
		if dragging and not event.pressed:
			dragging = false
			slotContainer.get_child(extra_arg_0).get_node("Item").position = Vector2(20,20)
			get_node("Sprite2D").hide()
			
			for i in SlotButtons.size():
				var slot = slotContainer.get_child(i)
				var mouse_pos = get_viewport().get_mouse_position()
				var slot_rect = Rect2(slot.global_position, slot.size)

				if slot_rect.has_point(mouse_pos):
					slot.has_item = true
					slot.itemName = ButtonInfo["Name"]
					slot.itemCount = ButtonInfo["Count"]
					slotContainer.setInventory()
			
	if event is InputEventMouseMotion and dragging:
		get_node("Sprite2D").show()
		get_node("Sprite2D").texture = slotContainer.get_child(extra_arg_0).get_node("Item").texture
		get_node("Sprite2D").global_position = get_viewport().get_mouse_position()
