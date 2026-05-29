extends Area2D

@onready var timer = $Timer
var time = 0.0

@onready var plant = $Sprite2D
@onready var water_particles: GPUParticles2D = $WaterParticles
var stage = 1
const MAX_STAGE = 5

var PlantNum = -1
var harvested = false
var is_watered_today = false

func _ready():
	if PlantNum == -1:
		PlantNum = get_parent().get_index()
		while Game.Plot.size() <= PlantNum:
			Game.Plot.append(null)
		Game.Plot[PlantNum] = {
			"Seed": "Tomato",
			"Stage" : stage,
			"MaxStage": MAX_STAGE,
			"PlantedDay": Game.game_day,
			"LastWateredDay": Game.game_day,
			"AgeDays": 0,
			"Harvested" : false,
		}
		Utils.save_game()
	_ensure_plot_data()
	timer.stop()
	# Saat load, cek apakah sudah disiram hari ini
	_check_watered_state()

func _check_watered_state() -> void:
	if PlantNum < 0 or PlantNum >= Game.Plot.size() or not (Game.Plot[PlantNum] is Dictionary):
		return
	var last_watered = int(Game.Plot[PlantNum].get("LastWateredDay", 0))
	is_watered_today = (last_watered == Game.game_day)
	_update_wilt_visual()

func _process(_delta: float):
	if harvested:
		return
	if PlantNum >= Game.Plot.size() or Game.Plot[PlantNum] == null:
		_die()
		return
	_ensure_plot_data()
	stage = int(Game.Plot[PlantNum].get("Stage", stage))
	plant.frame = min(stage, MAX_STAGE) + 6
	# Cek status siram setiap frame (hari bisa berganti)
	_check_watered_state()

func _update_wilt_visual() -> void:
	if is_watered_today or stage >= MAX_STAGE:
		# Sudah disiram atau sudah siap panen: normal
		if plant.modulate.g < 0.95:
			var tw = create_tween()
			tw.tween_property(plant, "modulate", Color(1, 1, 1, 1), 0.4)
	else:
		# Belum disiram: tint kuning pucat (layu ringan)
		var target_color = Color(1.0, 0.82, 0.45, 1.0)
		if plant.modulate.distance_to(target_color) > 0.05:
			var tw = create_tween()
			tw.tween_property(plant, "modulate", target_color, 0.8)

func _on_body_entered(body: Node2D) -> void:
	if not (body is PersistentState) or stage < MAX_STAGE:
		return
	_harvest()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if stage >= MAX_STAGE and event.is_action_pressed("Interact"):
		_harvest()

func _harvest() -> void:
	if harvested:
		return
	harvested = true
	Game.Plot[PlantNum]["Harvested"] = true
	_add_harvest()
	get_parent().has_seed = false
	if get_parent().has_method("_update_plant_prompt"):
		get_parent()._update_plant_prompt()
	Utils.save_game()
	queue_free()

func _add_harvest() -> void:
	Game.add_harvest_item("Tomato")

func water() -> void:
	is_watered_today = true
	# Trigger partikel air
	if water_particles != null:
		water_particles.restart()
		water_particles.emitting = true
	# Flash biru bright → kembali normal
	var tween = create_tween()
	tween.tween_property(plant, "modulate", Color(0.5, 0.85, 1.0, 1.0), 0.08)
	tween.tween_property(plant, "modulate", Color(0.85, 1.0, 0.85, 1.0), 0.12)
	tween.tween_property(plant, "modulate", Color(1, 1, 1, 1), 0.3)
	Utils.notif("Tanaman disiram 💧")

func _ensure_plot_data() -> void:
	if PlantNum < 0 or PlantNum >= Game.Plot.size() or not (Game.Plot[PlantNum] is Dictionary):
		return
	var data = Game.Plot[PlantNum]
	data["Seed"] = "Tomato"
	data["Stage"] = int(data.get("Stage", stage))
	data["MaxStage"] = MAX_STAGE
	data["PlantedDay"] = int(data.get("PlantedDay", Game.game_day))
	data["LastWateredDay"] = int(data.get("LastWateredDay", data["PlantedDay"]))
	data["AgeDays"] = int(data.get("AgeDays", 0))
	data["Harvested"] = bool(data.get("Harvested", false))
	Game.Plot[PlantNum] = data

func _die() -> void:
	get_parent().has_seed = false
	if get_parent().has_method("_update_plant_prompt"):
		get_parent()._update_plant_prompt()
	queue_free()
