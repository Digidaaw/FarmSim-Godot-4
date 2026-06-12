extends Control

@onready var seed_slots = [
	$Seed1,
	$Seed2,
]
@onready var mode_label: Label = $ModeLabel

func _ready():
	_sync_slots()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
		Game.cycle_pocket_mode()
		_sync_slots()
		return

	if event.is_action_pressed("Select_Up"):
		Game.move_pocket_selection(1)
	if event.is_action_pressed("Select_Down"):
		Game.move_pocket_selection(-1)
	_sync_slots()
	
func _process(_delta):
	_sync_slots()
	
func hide_all():
	for slot in seed_slots:
		slot.get_node("Select").hide()

func _sync_slots():
	hide_all()
	var pocket_items = Game.get_current_pocket_items()
	var max_slots = min(seed_slots.size(), pocket_items.size())
	mode_label.text = Game.get_current_pocket_mode()
	if max_slots <= 0:
		for slot in seed_slots:
			slot.visible = false
		return

	Game.PocketSlotIndex = clamp(Game.PocketSlotIndex, 0, pocket_items.size() - 1)
	Game.Selected = Game.PocketSlotIndex
	for i in seed_slots.size():
		var slot = seed_slots[i]
		slot.visible = i < max_slots
		if not slot.visible:
			continue

		var item = pocket_items[i]
		var icon_path = str(item.get("Icon", ""))
		if icon_path != "":
			# --- Bagian yang Diubah ---
			var tex = load(icon_path)
			slot.texture = tex
			if tex != null:
				slot.hframes = max(1, int(tex.get_width() / 16))
				slot.vframes = max(1, int(tex.get_height() / 16))
			# --------------------------
		slot.frame = int(item.get("Frame", 0))
		slot.get_node("Count").text = _format_count(item)
		if i == Game.PocketSlotIndex:
			slot.get_node("Select").show()

func _format_count(item: Dictionary) -> String:
	if item.get("Type", "") == "Tool":
		return ""
	return str(int(item.get("Count", 0)))
