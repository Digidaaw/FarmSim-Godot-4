extends CanvasGroup

const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")


func _ready():
	var plot_copy = Game.Plot.duplicate()
	var max_plots = min(plot_copy.size(), get_child_count())
	for i in max_plots:
		var dirt_plot = get_child(i)
		if dirt_plot == null:
			push_warning("DirtContainer: no child at index %d, skipping." % i)
			continue
		var seeds_node = dirt_plot.get_node("Seeds")
		var plant1 = Corn.instantiate()
		plant1.PlantNum = i
		plant1.stage = int(plot_copy[i]["Stage"])
		seeds_node.add_child(plant1)
		plant1.global_position = dirt_plot.global_position
		plant1.timer.start(int(plot_copy[i]["TimeLeft"]))
		dirt_plot.has_seed = true
	if plot_copy.size() > 0:
		Utils.save_game()
