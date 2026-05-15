extends Label

func _process(_delta):
	text = "0"

	for item in Game.Harvest:
		if item["Name"] == "Tomato":
			text = str(int(item["Count"]))
			return
