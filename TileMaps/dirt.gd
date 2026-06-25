extends TileMapLayer

@export var player: CharacterBody2D
@export var plot_of_dirt_scene: PackedScene

var hoed_cells := {}
var scene_path := ""
var hoe_prompt_panel: PanelContainer
var hoe_prompt: Label

func _ready() -> void:
	if owner:
		scene_path = owner.scene_file_path.to_lower()
	else:
		scene_path = get_tree().current_scene.scene_file_path.to_lower()
		
	print("==== DIRT.GD READY ====")
	print("Scene Path Aktif: ", scene_path)
	print("Data Cangkulan di Game: ", Game.hoed_plot_cells)
	
	register_existing_plots()
	setup_hoe_prompt()
	
	# Panggil load_hoed_plots secara deferred (tunda 1 frame) agar sistem 
	# koordinat global TileMapLayer sudah siap dihitung oleh Godot.
	load_hoed_plots.call_deferred()

func setup_hoe_prompt() -> void:
	hoe_prompt_panel = PanelContainer.new()
	hoe_prompt_panel.name = "HoePromptPanel"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.08, 0.85) # Cozy dark-brown flat panel
	style.set_corner_radius_all(3)
	style.set_border_width_all(1)
	style.border_color = Color(0.35, 0.23, 0.15, 0.95)
	
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	
	hoe_prompt_panel.add_theme_stylebox_override("panel", style)
	
	hoe_prompt = Label.new()
	hoe_prompt.name = "HoePrompt"
	hoe_prompt.add_theme_font_size_override("font_size", 8)
	hoe_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	hoe_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hoe_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	hoe_prompt_panel.add_child(hoe_prompt)
	get_parent().add_child.call_deferred(hoe_prompt_panel)
	hoe_prompt_panel.hide()
	
	if Utils.has_signal("keybinds_changed"):
		Utils.keybinds_changed.connect(_update_hoe_prompt_text)
	_update_hoe_prompt_text()

func _update_hoe_prompt_text() -> void:
	if hoe_prompt != null:
		hoe_prompt.text = Utils.get_key_label_for_action("Hoe")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Hoe"):
		var is_holding_hoe = Game.get_current_pocket_mode() == "Tool" and Game.get_selected_pocket_item().get("Name", "") == "Hoe"
		if is_holding_hoe:
			hoe_tile()
			get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	_update_hoe_prompt_visibility()

func _update_hoe_prompt_visibility() -> void:
	if hoe_prompt_panel == null:
		return
		
	if player == null:
		if hoe_prompt_panel.visible:
			hoe_prompt_panel.hide()
			Game.unregister_interactable(self)
		return
		
	var is_holding_hoe = Game.get_current_pocket_mode() == "Tool" and Game.get_selected_pocket_item().get("Name", "") == "Hoe"
	var cell := get_target_cell()
	var is_tillable = is_holding_hoe and get_cell_source_id(cell) != -1 and not hoed_cells.has(cell)
	
	if is_tillable:
		var cell_global_pos = to_global(map_to_local(cell))
		var size_needed = hoe_prompt_panel.get_combined_minimum_size()
		# Center horizontally over the 16x16 tile, offset vertically
		hoe_prompt_panel.global_position = cell_global_pos + Vector2(-size_needed.x / 2.0, -18)
		if not hoe_prompt_panel.visible:
			hoe_prompt_panel.show()
			Game.register_interactable(self, "tillable_grass")
	else:
		if hoe_prompt_panel.visible:
			hoe_prompt_panel.hide()
			Game.unregister_interactable(self)

func _exit_tree() -> void:
	if hoe_prompt_panel != null and hoe_prompt_panel.visible:
		Game.unregister_interactable(self)

func hoe_tile() -> void:
	if player == null:
		print("[CANGKUL GAGAL]: Variabel 'Player' di Inspector KOSONG!")
		return
	if plot_of_dirt_scene == null:
		print("[CANGKUL GAGAL]: Variabel 'Plot of Dirt Scene' di Inspector KOSONG!")
		return

	var cell := get_target_cell()
	print("Mencoba mencangkul di koordinat cell: ", cell)

	if hoed_cells.has(cell):
		print("[CANGKUL GAGAL]: Koordinat cell ini sudah ada di hoed_cells!")
		return

	if get_cell_source_id(cell) == -1:
		print("[CANGKUL GAGAL]: get_cell_source_id bernilai -1! (Bukan ubin tanah/kosong)")
		return

	var cell_text := scene_path + ":" + cell_to_text(cell)
	print("Menyimpan koordinat baru ke Game: ", cell_text)

	if not Game.hoed_plot_cells.has(cell_text):
		Game.hoed_plot_cells.append(cell_text)

	var plot_index := get_plot_index(cell_text)
	create_plot(cell, plot_index)

	Utils.save_game()

func register_existing_plots() -> void:
	for child in get_parent().get_children():
		if child is Area2D and child.has_method("setup_plot"):
			_register_single_plot(child)
			
	for child in get_parent().get_children():
		if child is CanvasGroup:
			for sub_child in child.get_children():
				if sub_child is Area2D and sub_child.has_method("setup_plot"):
					_register_single_plot(sub_child)

func _register_single_plot(plot_node: Area2D) -> void:
	var cell := local_to_map(to_local(plot_node.global_position))
	var cell_text := scene_path + ":" + cell_to_text(cell)
	var plot_index := get_plot_index(cell_text)

	plot_node.setup_plot(plot_index, cell)
	hoed_cells[cell] = plot_node

func load_hoed_plots() -> void:
	print("Memuat tanah cangkul untuk scene: ", scene_path)
	for cell_text in Game.hoed_plot_cells:
		var normalized_text = cell_text.to_lower()
		if not normalized_text.begins_with(scene_path + ":"):
			continue
		
		var coord_text := normalized_text.trim_prefix(scene_path + ":")
		var cell := text_to_cell(coord_text)

		if hoed_cells.has(cell):
			continue

		var plot_index := get_plot_index(cell_text)
		print("-> Berhasil memunculkan kembali tanah cangkul di cell: ", cell, " (Index: ", plot_index, ")")
		create_plot(cell, plot_index)

func create_plot(cell: Vector2i, plot_index: int) -> void:
	var plot := plot_of_dirt_scene.instantiate()
	
	# 1. Tambahkan ke parent terlebih dahulu
	get_parent().add_child(plot)
	get_parent().move_child(plot, get_index() + 1)
	
	# 2. Atur posisi globalnya setelah berada di scene tree
	plot.global_position = to_global(map_to_local(cell))

	# 3. Panggil setup_plot untuk memuat tanaman jika ada
	if plot.has_method("setup_plot"):
		plot.setup_plot(plot_index, cell)

	hoed_cells[cell] = plot

func get_plot_index(cell_text: String) -> int:
	if not Game.hoed_plot_cells.has(cell_text):
		Game.hoed_plot_cells.append(cell_text)
	return Game.hoed_plot_cells.find(cell_text)

func get_target_cell() -> Vector2i:
	var cell := local_to_map(to_local(player.global_position))

	if player.last_direction == "left":
		cell += Vector2i(-1, 0)
	elif player.last_direction == "right":
		cell += Vector2i(1, 0)
	elif player.last_direction == "up":
		cell += Vector2i(0, -1)
	elif player.last_direction == "down":
		cell += Vector2i(0, 1)

	return cell

func cell_to_text(cell: Vector2i) -> String:
	return "%s,%s" % [cell.x, cell.y]

func text_to_cell(cell_text: String) -> Vector2i:
	var parts: PackedStringArray = cell_text.split(",")

	if parts.size() < 2:
		return Vector2i.ZERO

	return Vector2i(int(parts[0]), int(parts[1]))
