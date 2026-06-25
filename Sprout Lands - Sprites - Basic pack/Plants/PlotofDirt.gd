extends Area2D

const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")
const Carrot = preload("res://Sprout Lands - Sprites - Basic pack/Plants/carrot.tscn")
const Ginger = preload("res://Sprout Lands - Sprites - Basic pack/Plants/ginger.tscn")

@onready var seeds_node = $Seeds
@onready var prompt: Label = $Prompt
@onready var prompt_panel: Panel = $PromptPanel

const PROMPT_OFFSET := Vector2(-10, -28)

var plot_index := -1
var plot_cell := Vector2i.ZERO

var player_node: Node2D = null

var has_seed = false
var canPlant = false
var player_in_plot = false

func _ready() -> void:
	prompt.position = PROMPT_OFFSET
	prompt_panel.position = PROMPT_OFFSET
	_update_prompt_text()
	_set_prompt_visible(false)
	set_process(false)
	if Utils.has_signal("keybinds_changed"):
		Utils.keybinds_changed.connect(_update_prompt_text)
	Game.time_changed.connect(_update_dirt_visual)

func _update_prompt_text() -> void:
	prompt.text = Utils.get_key_label_for_action("Interact")

func setup_plot(new_plot_index: int, new_cell: Vector2i) -> void:
	plot_index = new_plot_index
	plot_cell = new_cell
	
	if plot_index == -1:
		plot_index = get_index()

	if plot_index >= 0 and plot_index < Game.Plot.size() and Game.Plot[plot_index] is Dictionary:
		has_seed = true
		_load_plant_from_save()

	_update_dirt_visual()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact") and canPlant:
		interact()
		get_viewport().set_input_as_handled()

func _process(_delta):
	if player_in_plot:
		_update_plant_prompt()

func interact() -> void:
	if not has_seed:
		spawn()
		return

	var selected_item = Game.get_selected_pocket_item()
	if selected_item.get("Name", "") != "Watering Can":
		return

	var is_already_watered = false
	if plot_index >= 0 and plot_index < Game.Plot.size() and Game.Plot[plot_index] is Dictionary:
		var data = Game.Plot[plot_index]
		is_already_watered = (int(data.get("LastWateredDay", 0)) == Game.game_day)
	if is_already_watered:
		Utils.notif("Tanah sudah basah 💧")
		return
	
	Game.water_plot(plot_index)
	
	_update_dirt_visual()
	
	if player_node != null and player_node.has_method("water_animate"):
		player_node.water_animate()

	var plant_child = _get_plant_child()
	if plant_child != null and plant_child.has_method("water"):
		plant_child.water()

	Utils.save_game()

func spawn():
	if has_seed:
		return

	if Game.get_current_pocket_mode() != "Seed":
		return

	var seed_name = Game.get_selected_seed_name()
	if seed_name == "":
		return

	if not Game.spend_seed(seed_name):
		Utils.notif("Bibit %s habis" % seed_name)
		return

	while Game.Plot.size() <= plot_index:
		Game.Plot.append(null)

	Game.Plot[plot_index] = {
		"Seed": seed_name,
		"Stage": 1,
		"MaxStage": 5,
		"PlantedDay": Game.game_day,
		"LastWateredDay": Game.game_day - 1,
		"AgeDays": 0,
		"Harvested": false,
	}

	var plant1 = _create_plant(seed_name)

	if plant1 == null:
		Utils.notif("Bibit belum punya tanaman")
		Game.add_seed(seed_name)
		Game.Plot[plot_index] = null
		return

	if "PlantNum" in plant1:
		plant1.PlantNum = plot_index

	add_child(plant1)
	plant1.global_position = global_position

	has_seed = true
	_update_plant_prompt()
	Utils.save_game()

func _load_plant_from_save() -> void:
	var data = Game.Plot[plot_index]
	var seed_name := str(data.get("Seed", ""))

	var plant1 = _create_plant(seed_name)
	if plant1 == null:
		return

	if "PlantNum" in plant1:
		plant1.PlantNum = plot_index

	add_child(plant1)
	plant1.global_position = global_position

func _create_plant(seed_name: String) -> Node:
	match seed_name:
		"Corn":
			return Corn.instantiate()
		"Tomato":
			return Tomato.instantiate()
		"Carrot":
			return Carrot.instantiate()
		"Ginger":
			return Ginger.instantiate()
	return null

func _on_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D" or body.name == "Player":
		player_in_plot = true
		player_node = body # <-- Simpan node player
		set_process(true)
		_update_plant_prompt()
func _on_body_exited(body: Node2D) -> void:
	if body.name == "CharacterBody2D" or body.name == "Player":
		player_in_plot = false
		player_node = null # <-- Hapus node player
		set_process(false)
		_update_plant_prompt()

func _update_plant_prompt() -> void:
	var selected_item = Game.get_selected_pocket_item()
	var can_water = has_seed and selected_item.get("Name", "") == "Watering Can"
	var can_seed = not has_seed and Game.get_current_pocket_mode() == "Seed"
	var should_show_prompt = player_in_plot and (can_seed or can_water)

	if should_show_prompt == canPlant:
		return

	canPlant = should_show_prompt
	_set_prompt_visible(canPlant)

func _update_prompt_position() -> void:
	prompt.global_position = global_position + PROMPT_OFFSET
	prompt_panel.global_position = prompt.global_position

func _set_prompt_visible(should_show: bool) -> void:
	prompt.visible = should_show
	prompt_panel.visible = should_show
	if should_show:
		Game.register_interactable(self, "plot_dirt")
	else:
		Game.unregister_interactable(self)

func _get_plant_child() -> Node:
	for child in get_children():
		if child is Area2D and child != self:
			return child
	return null

func _update_dirt_visual() -> void:
	var is_watered = false
	
	# Cek apakah tanah ini sudah disiram hari ini
	if plot_index >= 0 and plot_index < Game.Plot.size() and Game.Plot[plot_index] is Dictionary:
		var data = Game.Plot[plot_index]
		is_watered = (int(data.get("LastWateredDay", 0)) == Game.game_day)

	# Asumsi node gambar tanah di dalam PlotOfDirt bernama "Sprite2D"
	if has_node("Dirt"):
		var sprite = $Dirt
		if is_watered:
			# Warna kecoklatan/gelap (tanah basah)
			sprite.modulate = Color(0.65, 0.55, 0.45, 1.0) 
		else:
			# Warna normal (tanah kering)
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
