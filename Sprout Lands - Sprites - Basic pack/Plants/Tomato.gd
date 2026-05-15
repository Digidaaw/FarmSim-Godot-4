extends Area2D

@onready var timer = $Timer
var time = 0.0

@onready var plant = $Sprite2D
var stage = 1

var PlantNum = -1

func _ready():
	if PlantNum == -1:
		PlantNum = Game.Plot.size()
		Game.Plot += [{
			"Seed": "Tomato",
			"TimeLeft": timer.time_left,
			"Stage" : stage,
		}]
		Utils.save_game()
	elif time > 0.0:
		timer.start(time)

func _process(_delta: float):
	Game.Plot[PlantNum]["TimeLeft"] = timer.time_left
	if stage <= 5:
		plant.frame = stage + 6
	else:
		get_parent().get_parent().has_seed = false
		queue_free()

func _on_timer_timeout():
	stage += 1
	Game.Plot[PlantNum]["Stage"] = stage
	Utils.save_game()
