extends Control

# Hotbar dinamis: Tool | Seed | Item pocket
# Tekan Q untuk cycle mode, scroll mouse / E/R untuk navigate slot

const MAX_SLOTS = 8

var _slot_nodes: Array = []
var _last_snapshot: String = ""

@onready var mode_label: Label = $BG/VBox/ModeLabel
@onready var slots_container: HBoxContainer = $BG/VBox/SlotsContainer

func _ready() -> void:
	_build_slots()
	_sync()

func _build_slots() -> void:
	# Hapus slot lama jika ada
	for child in slots_container.get_children():
		child.queue_free()
	_slot_nodes.clear()

	for i in range(MAX_SLOTS):
		var slot = _make_slot(i)
		slots_container.add_child(slot)
		_slot_nodes.append(slot)

func _make_slot(index: int) -> Control:
	var container = PanelContainer.new()
	container.name = "HotSlot%d" % index
	container.custom_minimum_size = Vector2(44, 44)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.12, 0.12, 0.75)
	style_normal.set_corner_radius_all(6)
	style_normal.set_border_width_all(2)
	style_normal.border_color = Color(0.55, 0.55, 0.55, 0.8)
	container.add_theme_stylebox_override("panel", style_normal)
	container.set_meta("style_normal", style_normal)

	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0.15, 0.38, 0.58, 0.92)
	style_selected.set_corner_radius_all(6)
	style_selected.set_border_width_all(2)
	style_selected.border_color = Color(0.45, 0.82, 1.0, 1.0)
	container.set_meta("style_selected", style_selected)

	var center = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(center)

	# Icon sprite
	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.custom_minimum_size = Vector2(30, 30)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	center.add_child(icon_rect)

	# Count label (pojok kanan bawah)
	var count_label = Label.new()
	count_label.name = "Count"
	count_label.layout_mode = 1
	count_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	count_label.anchor_left = 1.0
	count_label.anchor_top = 1.0
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.offset_left = -18.0
	count_label.offset_top = -16.0
	count_label.offset_right = -2.0
	count_label.offset_bottom = -1.0
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	container.add_child(count_label)

	# Invisible button overlay untuk klik pilih slot
	var btn = Button.new()
	btn.name = "Btn"
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	var slot_index = index
	btn.pressed.connect(func():
		var items = Game.get_current_pocket_items()
		if slot_index < items.size():
			Game.PocketSlotIndex = slot_index
			Game.Selected = slot_index
			_sync()
	)
	container.add_child(btn)

	# Store referensi node untuk akses cepat tanpa get_node()
	container.set_meta("icon_rect", icon_rect)
	container.set_meta("count_label", count_label)

	return container

func _input(event: InputEvent) -> void:
	# Cycle mode (Tool → Seed → Item)
	if event.is_action_pressed("CyclePocket"):
		Game.cycle_pocket_mode()
		_sync()

	# Scroll mouse: navigate slot
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Game.move_pocket_selection(1)
			_sync()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			Game.move_pocket_selection(-1)
			_sync()

	# E: next slot, R: previous slot (keyboard fallback)
	if event.is_action_pressed("Select_Down"):
		Game.move_pocket_selection(1)
		_sync()
	if event.is_action_pressed("Select_Up"):
		Game.move_pocket_selection(-1)
		_sync()

func _process(_delta: float) -> void:
	# Cukup sync kalau data berubah (pakai snapshot)
	var snap = "%s|%d|%d" % [
		Game.get_current_pocket_mode(),
		Game.PocketSlotIndex,
		_get_item_count_hash()
	]
	if snap != _last_snapshot:
		_last_snapshot = snap
		_sync()

func _get_item_count_hash() -> int:
	var items = Game.get_current_pocket_items()
	var total = 0
	for item in items:
		total += int(item.get("Count", 0))
	return total

func _sync() -> void:
	var mode = Game.get_current_pocket_mode()
	var items = Game.get_current_pocket_items()
	var selected = clamp(Game.PocketSlotIndex, 0, max(0, items.size() - 1))
	Game.PocketSlotIndex = selected
	Game.Selected = selected

	# Update mode label
	var mode_icon = {"Tool": "🔧", "Seed": "🌱", "Item": "🎒"}
	mode_label.text = "%s %s  [%s]" % [mode_icon.get(mode, ""), mode, Utils.get_key_label_for_action("CyclePocket")]

	for i in range(_slot_nodes.size()):
		var slot = _slot_nodes[i]
		var icon_rect: TextureRect = slot.get_meta("icon_rect")
		var count_label: Label = slot.get_meta("count_label")

		if i >= items.size():
			# Slot kosong
			icon_rect.texture = null
			count_label.text = ""
			slot.add_theme_stylebox_override("panel", slot.get_meta("style_normal"))
			slot.modulate = Color(1, 1, 1, 0.35)
			continue

		slot.modulate = Color(1, 1, 1, 1.0)
		var item = items[i]

		# Load icon
		var icon_path = str(item.get("Icon", ""))
		if icon_path != "":
			var tex = load(icon_path)
			if tex is AtlasTexture or tex is Texture2D:
				# Jika spritesheet, bungkus dengan AtlasTexture untuk frame tertentu
				if tex is Texture2D and item.has("Frame") and int(item.get("Frame", 0)) > 0:
					icon_rect.texture = _get_frame_texture(tex, item)
				else:
					icon_rect.texture = tex
			else:
				icon_rect.texture = tex
		else:
			icon_rect.texture = null

		# Count
		var item_type = str(item.get("Type", ""))
		if item_type == "Tool":
			count_label.text = ""
		else:
			count_label.text = str(int(item.get("Count", 0)))

		# Highlight slot aktif
		if i == selected:
			slot.add_theme_stylebox_override("panel", slot.get_meta("style_selected"))
		else:
			slot.add_theme_stylebox_override("panel", slot.get_meta("style_normal"))

func _get_frame_texture(source_tex: Texture2D, item: Dictionary) -> Texture2D:
	# Untuk Basic Plants.png: 6 hframes × 2 vframes, tiap frame 16×16
	# Frame 0-5 = row 0 (Corn), Frame 6-11 = row 1 (Tomato)
	var frame_idx = int(item.get("Frame", 0))
	var hframes = 6
	var frame_w = source_tex.get_width() / hframes
	var frame_h = source_tex.get_height() / 2
	var col = frame_idx % hframes
	var row = frame_idx / hframes
	var atlas = AtlasTexture.new()
	atlas.atlas = source_tex
	atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
	return atlas
