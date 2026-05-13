extends Area2D

@onready var timer = $Timer
@onready var plant = $Sprite2D

var stage: int = 1

func _ready():
	timer.start()
	plant.frame = stage

func _process(_delta: float):
	plant.frame = stage

func _on_timer_timeout():
	if stage < 5:
		stage += 1
