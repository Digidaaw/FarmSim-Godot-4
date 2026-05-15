extends Label


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in Game.Harvest.size():
		if "Tomato" in Game.Harvest[i]["Name"]:
			self.text = str(int(Game.Harvest[i]["Count"]))
