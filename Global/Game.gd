extends Node

signal interactables_changed

var saved_scene_path: String = ""
var saved_player_position: Vector2 = Vector2.ZERO

var active_interactables : Array = []

func register_interactable(node: Node, type: String, custom_text: String = "") -> void:
	# Clean up any dead nodes first
	var cleaned = []
	for item in active_interactables:
		if is_instance_valid(item.node):
			cleaned.append(item)
	active_interactables = cleaned
	
	# Add or update
	var found = false
	for item in active_interactables:
		if item.node == node:
			item.type = type
			item.custom_text = custom_text
			found = true
			break
	if not found:
		active_interactables.append({"node": node, "type": type, "custom_text": custom_text})
	
	interactables_changed.emit()

func unregister_interactable(node: Node) -> void:
	var cleaned = []
	var changed = false
	for item in active_interactables:
		if is_instance_valid(item.node):
			if item.node == node:
				changed = true
			else:
				cleaned.append(item)
	active_interactables = cleaned
	if changed:
		interactables_changed.emit()

var Plot = [

]

var Harvest = []

var hoed_plot_cells: Array[String] = []

var Selected = 0

var game_hour = 6
var game_minute = 0
var game_day = 1
var last_shipping_collect_day = 0

var Money = 100

var SeedOrder = [
	"Corn",
	"Tomato",
	"Carrot",
	"Ginger",
]

var Seeds = {
	"Corn": 3,
	"Tomato": 3,
	"Carrot": 3,
	"Ginger": 3,
}

var inventory_boxes := {}

var ToolPocket = [
	{
		"Name": "Watering Can",
		"Type": "Tool",
		"Icon": "res://Sprout Lands - Sprites - Basic pack/Objects/Basic tools and meterials.png",
		"Frame": 0, # Frame 0 adalah Watering Can
	},
	{
		"Name": "Axe",
		"Type": "Tool",
		"Icon": "res://Sprout Lands - Sprites - Basic pack/Objects/Basic tools and meterials.png",
		"Frame": 1, # Frame 1 adalah Axe
	},
	{
		"Name": "Hoe",
		"Type": "Tool",
		"Icon": "res://Sprout Lands - Sprites - Basic pack/Objects/Basic tools and meterials.png",
		"Frame": 2, # Frame 2 adalah Hoe
	}
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
	"Carrot": {
		"DisplayName": "Carrot Seed",
		"Price": 15,       # Tentukan harga beli Carrot di sini
		"SeedName": "Carrot",
		"Stock": -1,
	},
	"Ginger": {
		"DisplayName": "Ginger Seed",
		"Price": 20,       # Tentukan harga beli Ginger di sini
		"SeedName": "Ginger",
		"Stock": -1,
	},
}

var CropSellPrices = {
	"Corn": 18,
	"Tomato": 22,
	"Carrot": 28,  # Tentukan harga jual Wortel di sini (misal: 28)
	"Ginger": 35,
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
					"Icon": _get_seed_icon(seed_name),
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
					"Frame": _get_item_frame(str(item.get("Name", ""))), # DIUBAH DI SINI (sebelumnya ditulis 0)
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
		"Carrot":
			return 5
		"Ginger":
			return 7
		_:
			return 0

func _get_seed_icon(seed_name: String) -> String:
	match seed_name:
		"Carrot", "Ginger":
			# Sesuaikan path di bawah ini dengan lokasi folder tempat menyimpan file tersebut
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Farming Plants items v2.png"
		_:
			# Default untuk Corn & Tomato
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Basic Plants.png"

func _get_item_icon(item_name: String) -> String:
	match item_name:
		"Corn":
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Corn.png"
		"Tomato":
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Tomato.png"
		"Carrot", "Ginger":
			return "res://Sprout Lands - Sprites - Basic pack/Objects/Farming Plants items v2.png" # DIUBAH DI SINI
		_:
			return ""

func _get_item_frame(item_name: String) -> int:
	match item_name:
		"Carrot":
			return 6 # Sesuai dengan inspector Carrot matang (Frame 6)
		"Ginger":
			return 8 # (Nanti sesuaikan dengan nomor frame Jahe di file items)
		_:
			return -1 # Mengembalikan -1 untuk Corn/Tomato agar gambarnya tidak terpotong (single image)


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

func get_unified_inventory() -> Array:
	var list = []
	
	# 1. Tools
	for tool in ToolPocket:
		list.append({
			"Name": tool["Name"],
			"Type": "Tool",
			"Count": 1,
			"Icon": tool["Icon"],
			"Frame": tool.get("Frame", 0)
		})
		
	# 2. Seeds
	for seed_name in SeedOrder:
		var count = get_seed_count(seed_name)
		if count > 0:
			list.append({
				"Name": seed_name,
				"Type": "Seed",
				"Count": count,
				"Icon": _get_seed_icon(seed_name),
				"Frame": _get_seed_frame(seed_name)
			})
			
	# 3. Crops
	# 3. Crops
	for item in Harvest:
		if item is Dictionary and int(item.get("Count", 0)) > 0:
			list.append({
				"Name": item["Name"],
				"Type": "Item",
				"Count": item["Count"],
				"Icon": _get_item_icon(item["Name"]),
				"Frame": _get_item_frame(item["Name"]) # DIUBAH DI SINI (sebelumnya ditulis -1)
			})
			
	# Fill rest with null up to 12 slots
	while list.size() < 12:
		list.append(null)
		
	return list

func get_item_texture(item: Dictionary) -> Texture2D:
	var icon_path = item.get("Icon", "")
	if icon_path == "":
		return null
	var tex = load(icon_path)
	if tex == null:
		return null
	if item.has("Frame") and int(item.get("Frame", -1)) >= 0:
		var frame_idx = int(item.get("Frame", 0))
		var frame_w = 16
		var frame_h = 16
		var h_count = int(tex.get_width() / frame_w)
		if h_count == 0: h_count = 1
		var col = frame_idx % h_count
		var row = frame_idx / h_count
		var atlas = AtlasTexture.new()
		atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		atlas.atlas = tex
		return atlas
	return tex

func add_player_item(item: Dictionary) -> void:
	var type = item.get("Type", "")
	var name = item.get("Name", "")
	var count = int(item.get("Count", 1))
	
	if type == "Tool":
		var has_tool = false
		for t in ToolPocket:
			if t["Name"] == name:
				has_tool = true
				break
		if not has_tool:
			ToolPocket.append({
				"Name": name,
				"Type": "Tool",
				"Icon": item.get("Icon", ""),
				"Frame": item.get("Frame", 0)
			})
	elif type == "Seed":
		add_seed(name, count)
	else:
		add_harvest_item(name, count)
	Utils.save_game()

func remove_player_item(item: Dictionary, amount: int = -1) -> void:
	var type = item.get("Type", "")
	var name = item.get("Name", "")
	var count = int(item.get("Count", 1))
	if amount < 0:
		amount = count
		
	if type == "Tool":
		var target_idx = -1
		for i in range(ToolPocket.size()):
			if ToolPocket[i]["Name"] == name:
				target_idx = i
				break
		if target_idx != -1:
			ToolPocket.remove_at(target_idx)
	elif type == "Seed":
		spend_seed(name, amount)
	else:
		# Crop/Item
		for i in range(Harvest.size()):
			var h_item = Harvest[i]
			if h_item is Dictionary and h_item.get("Name", "") == name:
				var h_count = int(h_item.get("Count", 0))
				if h_count > amount:
					h_item["Count"] = h_count - amount
				else:
					Harvest[i] = null
				break
		_trim_empty_harvest_slots()
	Utils.save_game()

func _trim_empty_harvest_slots() -> void:
	while Harvest.size() > 0 and Harvest[Harvest.size() - 1] == null:
		Harvest.pop_back()

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
	
func reset_game() -> void:
	# 1. Kembalikan semua data ke nilai default awal game
	game_day = 1
	game_hour = 6
	game_minute = 0
	last_shipping_collect_day = 0
	Money = 100
	Plot.clear() # Kosongkan kebun
	Harvest.clear() # Kosongkan hasil panen di tas
	
	# Bibit awal
	Seeds = {
		"Corn": 3,
		"Tomato": 3,
		"Carrot": 3,
		"Ginger": 3,
	}
	
	ShippingBinItems.clear()
	PocketModeIndex = 1
	PocketSlotIndex = 0
	Selected = 0
	saved_scene_path = ""
	saved_player_position = Vector2.ZERO

	# 2. Simpan data baru yang kosong ini untuk menimpa save file lama
	Utils.save_game()
