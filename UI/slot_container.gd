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

	for item in min(Game.Harvest.size(), SlotButtons.size()):
		var harvest_item = Game.Harvest[item]
		if not (harvest_item is Dictionary) or not harvest_item.has("Name") or harvest_item.get("Count", 0) <= 0:
			continue

		if "Corn" in harvest_item["Name"]:
			SlotButtons[item].set_item(harvest_item["Name"], harvest_item["Count"], load("res://Sprout Lands - Sprites - Basic pack/Objects/Corn.png"))
		if "Tomato" in harvest_item["Name"]:
			SlotButtons[item].set_item(harvest_item["Name"], harvest_item["Count"], load("res://Sprout Lands - Sprites - Basic pack/Objects/Tomato.png"))
