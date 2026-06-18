extends VBoxContainer

@onready var row1: HBoxContainer = $Row1
@onready var row1_key: Label = $Row1/KeyPanel/Label
@onready var row1_action: Label = $Row1/ActionLabel

@onready var row2: HBoxContainer = $Row2
@onready var row2_key: Label = $Row2/KeyPanel/Label
@onready var row2_action: Label = $Row2/ActionLabel

@onready var row3: HBoxContainer = $Row3
@onready var row3_key: Label = $Row3/KeyPanel/Label
@onready var row3_action: Label = $Row3/ActionLabel

func _ready() -> void:
	_update_static_keys()
	if Utils.has_signal("keybinds_changed"):
		Utils.keybinds_changed.connect(_update_static_keys)

func _update_static_keys() -> void:
	row2_key.text = Utils.get_key_label_for_action("CyclePocket")
	row2_action.text = "Cycle Tools"
	
	row3_key.text = Utils.get_key_label_for_action("Inventory")
	row3_action.text = "Open Bag"

func _process(_delta: float) -> void:
	# If system prompts is turned off in settings, hide all
	if not Utils.show_system_prompts:
		hide()
		return
		
	show()
	
	# Clean up any invalid/deleted nodes in active_interactables
	var valid_items := []
	for item in Game.active_interactables:
		if is_instance_valid(item.get("node")):
			valid_items.append(item)
	
	if valid_items.size() != Game.active_interactables.size():
		Game.active_interactables = valid_items
		
	if valid_items.is_empty():
		row1.hide()
	else:
		row1.show()
		var active_item = valid_items.back()
		_update_context_row(active_item)

func _update_context_row(item: Dictionary) -> void:
	var type = item.get("type", "")
	var interact_key = Utils.get_key_label_for_action("Interact")
	var hoe_key = Utils.get_key_label_for_action("Hoe")
	
	match type:
		"door":
			row1_key.text = interact_key
			row1_action.text = "Enter Room"
		"bed":
			row1_key.text = interact_key
			row1_action.text = "Go to Sleep"
		"shipping_bin":
			row1_key.text = interact_key
			row1_action.text = "Sell Harvest"
		"seed_seller":
			row1_key.text = interact_key
			var seed_name = Game.get_selected_seed_name()
			if seed_name != "":
				var display_name = Game.ShopItems.get(seed_name, {}).get("DisplayName", seed_name)
				row1_action.text = "Buy %s Seed" % display_name
			else:
				row1_action.text = "Buy Seed"
		"npc":
			row1_key.text = interact_key
			row1_action.text = "Talk to NPC"
		"tillable_grass":
			row1_key.text = hoe_key
			row1_action.text = "Till Soil"
		"plot_dirt":
			row1_key.text = interact_key
			var plot = item.get("node")
			if not is_instance_valid(plot):
				row1.hide()
				return
			if plot.has_seed:
				var is_watered = false
				if plot.plot_index >= 0 and plot.plot_index < Game.Plot.size() and Game.Plot[plot.plot_index] is Dictionary:
					var data = Game.Plot[plot.plot_index]
					is_watered = (int(data.get("LastWateredDay", 0)) == Game.game_day)
				
				if is_watered:
					# Already watered: hide prompt since no action is possible
					row1.hide()
				else:
					var selected_item = Game.get_selected_pocket_item()
					if selected_item.get("Name", "") == "Watering Can":
						row1_action.text = "Water Crop"
					else:
						row1.hide() # hide action if not holding watering can
			else:
				if Game.get_current_pocket_mode() == "Seed":
					var seed_name = Game.get_selected_seed_name()
					if seed_name != "":
						row1_action.text = "Plant %s" % seed_name
					else:
						row1_action.text = "Plant Seed"
				else:
					row1.hide()
