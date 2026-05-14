extends Area2D

@onready var timer = $Timer
@onready var plant = $Sprite2D

var stage = 1

var PlantNum = -1

func _ready():
	if PlantNum == -1:
		PlantNum = Game.Plot.size()
	Game.Plot += [{
		"Seed": "Corn",
		"TimeLeft": timer.time_left,
		"Stage" : stage,
	}]
	Utils.save_game()

func _process(_delta: float):
	Game.Plot[PlantNum]["Timer"] = timer.time_left
	plant.frame = stage

func _on_timer_timeout():
	if stage < 5:
		stage += 1
	Game.Plot[PlantNum]["Stage"] = stage
	Utils.save_game()
