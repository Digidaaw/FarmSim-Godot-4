extends GridContainer


@onready var SlotButtons = [
	get_node("Slot"),
	get_node("Slot2"),
	get_node("Slot3"),
	get_node("Slot4"),
	get_node("Slot5"),
	get_node("Slot6"),
]

func setInventory():
	for item in Game.Harvest.size():
		if SlotButtons.size() >= Game.Harvest.size():
			if "Corn" in Game.Harvest[item]["Name"]:
				SlotButtons[item].has_item = true
				SlotButtons[item].itemIcon = load("res://Sprout Lands - Sprites - Basic pack/Objects/Corn.png")
				SlotButtons[item].itemName = Game.Harvest[item]["Name"]
				SlotButtons[item].itemCount = Game.Harvest[item]["Count"]
			if "Tomato" in Game.Harvest[item]["Name"]:
				SlotButtons[item].has_item = true
				SlotButtons[item].itemIcon = load("res://Sprout Lands - Sprites - Basic pack/Objects/Tomato.png")
				SlotButtons[item].itemName = Game.Harvest[item]["Name"]
				SlotButtons[item].itemCount = Game.Harvest[item]["Count"]
