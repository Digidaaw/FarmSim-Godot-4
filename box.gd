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
