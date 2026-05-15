extends CanvasGroup

const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")


func _ready():
	var Curr_plot = Game.Plot
	if Curr_plot.size() > 0:
		var max_plots = min(Curr_plot.size(), get_child_count())
		for i in max_plots:
			var plot = get_child(i)
			var plant_scene = Corn
			if Curr_plot[i].get("Seed", "Corn") == "Tomato":
				plant_scene = Tomato
			var plant1 = plant_scene.instantiate()
			plant1.PlantNum = i
			plant1.stage = int(Curr_plot[i]["Stage"])
			plant1.time = float(round(Curr_plot[i].get("TimeLeft", 0.0)))
			plot.seeds_node.add_child(plant1)
			plant1.global_position = plot.global_position
			plot.has_seed = true
		if Curr_plot.size() > max_plots:
			Game.Plot.resize(max_plots)
			Utils.save_game()
