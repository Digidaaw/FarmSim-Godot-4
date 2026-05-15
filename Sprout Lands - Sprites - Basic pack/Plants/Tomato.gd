extends Area2D

@onready var timer = $Timer
var time = 0.0

@onready var plant = $Sprite2D
var stage = 1
const MAX_STAGE = 5

var PlantNum = -1
var harvested = false

func _ready():
	if PlantNum == -1:
		PlantNum = get_parent().get_index()
		while Game.Plot.size() <= PlantNum:
			Game.Plot.append(null)
		Game.Plot[PlantNum] = {
			"Seed": "Tomato",
			"TimeLeft": timer.time_left,
			"Stage" : stage,
			"Harvested" : false,
		}
		Utils.save_game()
	elif time > 0.0:
		timer.start(time)

func _process(_delta: float):
	if harvested:
		return
	Game.Plot[PlantNum]["TimeLeft"] = timer.time_left
	plant.frame = min(stage, MAX_STAGE) + 6

func _on_timer_timeout():
	if stage < MAX_STAGE:
		stage += 1
	Game.Plot[PlantNum]["Stage"] = stage
	Utils.save_game()
	if stage == MAX_STAGE:
		for body in get_overlapping_bodies():
			if body is PersistentState:
				_harvest()
				return

func _on_body_entered(body: Node2D) -> void:
	if not (body is PersistentState) or stage < MAX_STAGE:
		return

	_harvest()
	print(Game.Harvest	)
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if stage >= MAX_STAGE and event.is_action_pressed("Spawn"):
		_harvest()

func _harvest() -> void:
	if harvested:
		return
	harvested = true
	
	Game.Plot[PlantNum]["Harvested"] = true
	_add_harvest()
	#Game.Plot[PlantNum] = null
	get_parent().has_seed = false
	Utils.save_game()
	queue_free()

func _add_harvest() -> void:
	for item in Game.Harvest:
		if item["Name"] == "Tomato":
			item["Count"] += 1
			return

	Game.Harvest.append({
		"Name": "Tomato",
		"Count": 1,
		"Consumable": true,
	})
