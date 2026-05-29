extends Node

var Plot = [

]

var Harvest = []

var Selected = 0

var game_hour = 6
var game_minute = 0
var game_day = 1
var last_shipping_collect_day = 0

var Money = 100

var SeedOrder = [
	"Corn",
	"Tomato",
]

var Seeds = {
	"Corn": 3,
	"Tomato": 3,
}

var ToolPocket = [
	{
		"Name": "Watering Can",
		"Type": "Tool",
		"Icon": "res://Sprout Lands - Sprites - Basic pack/Characters/Tools.png",
		"Frame": 0,
	},
]

var PocketModes = [
	"Tool",
	"Seed",
	"Item",
]
var PocketModeIndex = 1
var PocketSlotIndex = 0

# Tambah atau hapus barang jualan NPC dari dictionary ini.
var ShopItems = {
	"Corn": {
		"DisplayName": "Corn Seed",
		"Price": 10,
		"SeedName": "Corn",
		"Stock": -1,
	},
	"Tomato": {
		"DisplayName": "Tomato Seed",
		"Price": 12,
		"SeedName": "Tomato",
		"Stock": -1,
	},
}

var CropSellPrices = {
	"Corn": 18,
	"Tomato": 22,
}

var ShippingBinItems = []

func get_selected_seed_name() -> String:
	if SeedOrder.is_empty():
		return ""
	if get_current_pocket_mode() != "Seed":
		return ""
	return SeedOrder[clamp(PocketSlotIndex, 0, SeedOrder.size() - 1)]

func get_current_pocket_mode() -> String:
	return PocketModes[clamp(PocketModeIndex, 0, PocketModes.size() - 1)]

func cycle_pocket_mode() -> void:
	PocketModeIndex = (PocketModeIndex + 1) % PocketModes.size()
	PocketSlotIndex = 0
	Selected = 0

func move_pocket_selection(direction: int) -> void:
	var items = get_current_pocket_items()
	if items.is_empty():
		PocketSlotIndex = 0
		Selected = 0
		return
	PocketSlotIndex = clamp(PocketSlotIndex + direction, 0, items.size() - 1)
	Selected = PocketSlotIndex

func get_current_pocket_items() -> Array:
	match get_current_pocket_mode():
		"Tool":
			return ToolPocket
		"Seed":
			var seed_items = []
			for seed_name in SeedOrder:
				seed_items.append({
					"Name": seed_name,
					"Type": "Seed",
					"Count": get_seed_count(seed_name),
					"Icon": "res://Sprout Lands - Sprites - Basic pack/Objects/Basic Plants.png",
					"Frame": _get_seed_frame(seed_name),
				})
			return seed_items
		"Item":
			var item_items = []
			for item in Harvest:
				if not (item is Dictionary) or int(item.get("Count", 0)) <= 0:
					continue
				item_items.append({
					"Name": str(item.get("Name", "")),
					"Type": "Item",
					"Count": int(item.get("Count", 0)),
					"Icon": _get_item_icon(str(item.get("Name", ""))),
					"Frame": 0,
				})
			return item_items
	return []

func get_selected_pocket_item() -> Dictionary:
	var items = get_current_pocket_items()
	if items.is_empty():
		return {}
	return items[clamp(PocketSlotIndex, 0, items.size() - 1)]

func _get_seed_frame(seed_name: String) -> int:
	match seed_name:
		"Tomato":
			return 6
		_:
			return 0

func _get_item_icon(item_name: String) -> String:
	match item_name:
		"Corn":
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Corn.png"
		"Tomato":
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Tomato.png"
		_:
			return ""

func get_seed_count(seed_name: String) -> int:
	return int(Seeds.get(seed_name, 0))

func add_seed(seed_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	Seeds[seed_name] = get_seed_count(seed_name) + amount

func spend_seed(seed_name: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if get_seed_count(seed_name) < amount:
		return false
	Seeds[seed_name] = get_seed_count(seed_name) - amount
	return true

func buy_shop_item(item_name: String, amount: int = 1) -> Dictionary:
	if not ShopItems.has(item_name):
		return {"Success": false, "Message": "Item tidak dijual."}

	var item = ShopItems[item_name]
	var price = int(item.get("Price", 0)) * amount
	var stock = int(item.get("Stock", -1))

	if stock != -1 and stock < amount:
		return {"Success": false, "Message": "Stok habis."}
	if Money < price:
		return {"Success": false, "Message": "Uang tidak cukup."}

	Money -= price
	add_seed(str(item.get("SeedName", item_name)), amount)
	if stock != -1:
		item["Stock"] = stock - amount
		ShopItems[item_name] = item

	return {
		"Success": true,
		"Message": "Beli %s -%dG" % [str(item.get("DisplayName", item_name)), price],
	}

func add_harvest_item(item_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	for item in Harvest:
		if not (item is Dictionary):
			continue
		if item.get("Name", "") == item_name:
			item["Count"] = int(item.get("Count", 0)) + amount
			return

	var new_item = {
		"Name": item_name,
		"Count": amount,
		"Consumable": true,
	}
	var empty_index = Harvest.find(null)
	if empty_index == -1:
		Harvest.append(new_item)
	else:
		Harvest[empty_index] = new_item

func ship_all_harvest() -> Dictionary:
	var shipped_count = 0
	for item in Harvest:
		if not (item is Dictionary):
			continue
		var count = int(item.get("Count", 0))
		if count <= 0:
			continue
		_add_shipping_item(str(item.get("Name", "")), count)
		shipped_count += count

	if shipped_count <= 0:
		return {"Success": false, "Message": "Tidak ada hasil panen."}

	Harvest.clear()
	return {"Success": true, "Message": "Masuk shipping bin: %d item" % shipped_count}

func _add_shipping_item(item_name: String, amount: int) -> void:
	for item in ShippingBinItems:
		if item.get("Name", "") == item_name:
			item["Count"] = int(item.get("Count", 0)) + amount
			return
	ShippingBinItems.append({
		"Name": item_name,
		"Count": amount,
	})

func collect_shipping_bin() -> Dictionary:
	var total = 0
	var shipped_count = 0

	for item in ShippingBinItems:
		if not (item is Dictionary):
			continue
		var item_name = str(item.get("Name", ""))
		var count = int(item.get("Count", 0))
		total += int(CropSellPrices.get(item_name, 0)) * count
		shipped_count += count

	ShippingBinItems.clear()
	if total > 0:
		Money += total

	return {
		"Total": total,
		"Count": shipped_count,
	}

func advance_day() -> void:
	game_day += 1

	for i in range(Plot.size()):
		var data = Plot[i]
		if not (data is Dictionary):
			continue
		if data.get("Harvested", false):
			continue

		var last_watered_day = int(data.get("LastWateredDay", int(data.get("PlantedDay", game_day - 1))))
		if game_day - last_watered_day >= 2:
			Plot[i] = null
			continue

		if last_watered_day >= game_day - 1:
			data["Stage"] = min(int(data.get("Stage", 1)) + 1, int(data.get("MaxStage", 5)))
		data["AgeDays"] = int(data.get("AgeDays", 0)) + 1
		Plot[i] = data

func water_plot(plot_index: int) -> void:
	if plot_index < 0 or plot_index >= Plot.size():
		return
	if not (Plot[plot_index] is Dictionary):
		return
	Plot[plot_index]["LastWateredDay"] = game_day
