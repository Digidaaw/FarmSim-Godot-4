extends CanvasGroup

const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")

func _ready() -> void:
	Utils.notif("Hi!! :D")
	_load_plants_from_save()

func _load_plants_from_save() -> void:
	var curr_plot = Game.Plot
	if curr_plot.size() == 0:
		return

	var max_plots = min(curr_plot.size(), get_child_count())
	for i in range(max_plots):
		var data = curr_plot[i]
		var plot = get_child(i)

		# Plot mati atau kosong — pastikan plot tidak punya tanaman
		if not (data is Dictionary) or not data.has("Seed"):
			plot.has_seed = false
			continue

		# Skip jika sudah di-harvest
		if data.get("Harvested", false):
			plot.has_seed = false
			continue

		var plant = null
		match data["Seed"]:
			"Corn":
				plant = Corn.instantiate()
			"Tomato":
				plant = Tomato.instantiate()

		if plant != null:
			plant.PlantNum = i
			plant.stage = int(data.get("Stage", 1))
			plant.time = float(round(data.get("TimeLeft", 0.0)))
			plot.add_child(plant)
			plot.has_seed = true

# Dipanggil oleh World.gd setelah advance_day() agar plant di scene ter-refresh
func refresh_all_plants() -> void:
	for i in range(get_child_count()):
		var plot = get_child(i)
		# Cek apakah plot ini punya data yang sudah null (tanaman mati)
		if i < Game.Plot.size() and Game.Plot[i] == null:
			# Hapus semua child plant dari plot ini
			for child in plot.get_children():
				if child is Area2D:
					child.queue_free()
			plot.has_seed = false
			if plot.has_method("_update_plant_prompt"):
				plot._update_plant_prompt()
