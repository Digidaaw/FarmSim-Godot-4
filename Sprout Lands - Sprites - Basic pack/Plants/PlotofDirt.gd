extends Area2D
const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")

@onready var seeds_node = $Seeds
@onready var prompt: Label = $Prompt
@onready var prompt_panel: Panel = $PromptPanel

const PROMPT_OFFSET := Vector2(-10, -28)

var has_seed = false
var canPlant = false
var player_in_plot = false

func get_input():
	if Input.is_action_just_pressed("Interact"):
		if canPlant == true:
			interact()

func _ready() -> void:
	prompt.text = "F"
	_update_prompt_position()
	_set_prompt_visible(false)

func _physics_process(_delta):
	_update_prompt_position()
	get_input()

func interact() -> void:
	if not has_seed:
		spawn()
		return

	var selected_item = Game.get_selected_pocket_item()
	if selected_item.get("Name", "") != "Watering Can":
		return

	Game.water_plot(get_index())
	var plant_child = _get_plant_child()
	if plant_child != null and plant_child.has_method("water"):
		plant_child.water()
	Utils.save_game()

func spawn():
	if !has_seed:
		if Game.get_current_pocket_mode() != "Seed":
			return
		var seed_name = Game.get_selected_seed_name()
		if seed_name == "":
			return
		if not Game.spend_seed(seed_name):
			Utils.notif("Bibit %s habis" % seed_name)
			return

		var plant1 = null
		match seed_name:
			"Corn":
				plant1 = Corn.instantiate()
			"Tomato":
				plant1 = Tomato.instantiate()

		if plant1 == null:
			Utils.notif("Bibit belum punya tanaman")
			Game.add_seed(seed_name)
			return

		self.add_child(plant1)
		plant1.global_position = global_position
		has_seed = true
		_update_plant_prompt()
		Utils.save_game()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		player_in_plot = true
		_update_plant_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		player_in_plot = false
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

func _get_plant_child() -> Node:
	for child in get_children():
		if child is Area2D and child != self:
			return child
	return null
