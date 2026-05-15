extends CanvasGroup

const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")

func _ready() -> void:
	var curr_plot = Game.Plot

	if curr_plot.size() > 0:

		var max_plots = min(curr_plot.size(), get_child_count())

		for i in range(max_plots):

			var data = curr_plot[i]
			var plant
			if not (data is Dictionary) or not data.has("Seed"):
				continue

			match data["Seed"]:

				"Corn":
					plant = Corn.instantiate()

				"Tomato":
					plant = Tomato.instantiate()

			if plant != null:

				plant.PlantNum = i
				plant.stage = int(data.get("Stage", 1))
				plant.time = float(round(data.get("TimeLeft", 0.0)))

				var plot = get_child(i)

				plot.add_child(plant)
				plot.has_seed = true
