extends Control

@export var box_gap := 12.0
@export var box_y_offset := 40.0

var opened_box = null
var player_inventory = null
var is_open := false

var box_open_position: Vector2
var box_hidden_position: Vector2

func _ready() -> void:
	box_open_position = position
	box_hidden_position = box_open_position + Vector2(0, size.y + 20)

	visible = false
	position = box_hidden_position

func open_box(box, inventory_ui) -> void:
	if is_open:
		return
		
	opened_box = box
	player_inventory = inventory_ui
	is_open = true

	print("Buka UI box:", opened_box.box_id)

	var viewport_size = get_viewport_rect().size
	var center_x = viewport_size.x / 2
	
	var box_size = size * scale
	var player_size = player_inventory.size * player_inventory.scale

	var is_player_fullscreen = player_inventory.size.x >= viewport_size.x - 10.0
	
	var visual_player_width = box_size.x if is_player_fullscreen else player_size.x

	var target_box_x = center_x + (box_gap / 2)
	var target_player_x : float
	if is_player_fullscreen:
		target_player_x = - (visual_player_width + box_gap) / 2
	else:
		target_player_x = center_x - (box_gap / 2) - visual_player_width

	var target_player_y = player_inventory.default_open_position.y
	
	var target_box_y = target_player_y + player_size.y - box_size.y - box_y_offset

	var target_player_pos = Vector2(target_player_x, target_player_y)
	var target_box_pos = Vector2(target_box_x, target_box_y)

	var hidden_player_pos = target_player_pos + Vector2(0, player_inventory.size.y + 20)
	var hidden_box_pos = target_box_pos + Vector2(0, size.y + 20)

	visible = true
	position = hidden_box_pos

	if player_inventory != null and player_inventory.has_method("open_inventory_from_box"):
		player_inventory.open_inventory_from_box(target_player_pos, hidden_player_pos)

	var tween := create_tween()
	tween.tween_property(self, "position", target_box_pos, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)


func close_box() -> void:
	if not is_open:
		return

	is_open = false

	if player_inventory != null:
		if player_inventory.has_method("close_inventory_from_box"):
			var hidden_player_pos = player_inventory.position + Vector2(0, player_inventory.size.y + 20)
			player_inventory.close_inventory_from_box(hidden_player_pos)
		elif player_inventory.has_method("close_inventory"):
			player_inventory.close_inventory()

	var hidden_box_pos = position + Vector2(0, size.y + 20)
	var tween := create_tween()
	tween.tween_property(self, "position", hidden_box_pos, 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	await tween.finished

	visible = false
	opened_box = null
	player_inventory = null
