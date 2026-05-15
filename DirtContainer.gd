extends CanvasGroup

const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")

func _ready() -> void:
	var curr_plot = Game.Plot
	print(curr_plot.size())
	if curr_plot.size() > 0:
		#for i in curr_plot.size():
			#match (curr_plot[i-1]["Seed"]):
				#"Corn":
					#Game.Plot.pop_at(i)
					#var plant1 = Corn.instantiate()
					#plant1.PlantNum = i
					#plant1.stage = int(curr_plot[i-1]["Stage"])
					#plant1.time = (float(round(curr_plot[i-1]["Time Left"])))
					#get_child(i).add_child(plant1)
					#get_child(i).has_seed = true
					#Utils.save_game()
				#"Tomato":
					#Game.Plot.pop_at(i)
					#var plant1 = Tomato.instantiate()
					#plant1.PlantNum = i
					#plant1.stage = int(curr_plot[i-1]["Stage"])
					#plant1.time = (float(round(curr_plot[i-1]["Time Left"])))
					#get_child(i).add_child(plant1)
					#get_child(i).has_seed = true
					#Utils.save_game()
					
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
