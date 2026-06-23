extends GridContainer


@onready var SlotButtons = [
	get_node("Slot"),
	get_node("Slot2"),
	get_node("Slot3"),
	get_node("Slot4"),
	get_node("Slot5"),
	get_node("Slot6"),
	get_node("Slot7"),
	get_node("Slot8"),
	get_node("Slot9"),
	get_node("Slot10"),
	get_node("Slot11"),
	get_node("Slot12"),
]

func setInventory():
	for slot in SlotButtons:
		slot.clear_item()

	var items = Game.get_unified_inventory()
	for i in min(items.size(), SlotButtons.size()):
		var item = items[i]
		if item == null:
			continue
		var icon = Game.get_item_texture(item)
		SlotButtons[i].set_item(item["Name"], item["Count"], icon)
