extends Node2D

@onready var darkness = get_node("Ambient")
@onready var light = get_node("CharacterBody2D/PointLight2D")

var game_hour = 6
var game_minute = 0
var time_speed = 60.0
var time_passed = 0.0

var color_scheme = {
	0: Color8(40, 40, 40),
	1: Color8(60, 60, 60),
	2: Color8(80, 80, 80),
	3: Color8(100, 100, 100),
	4: Color8(120, 120, 120),
	5: Color8(140, 140, 140),
	6: Color8(160, 160, 160),
	7: Color8(180, 180, 180),
	8: Color8(200, 200, 200),
	9: Color8(220, 220, 220),
	10: Color8(240, 240, 240),
}
var light_schemes = {
	0: 0.8,
	1: 0.7,
	2: 0.6,
	3: 0.5,
	4: 0.4,
	5: 0.3,
	6: 0.2,
	7: 0.1,
	8: 0,
}

func _ready() -> void:
	game_hour = Game.game_hour
	game_minute = Game.game_minute
	StageManager.apply_player_spawn($CharacterBody2D, $CharacterBody2D.position)

func _process(delta: float) -> void:
	time_passed += delta * time_speed

	while time_passed >= 60.0:
		time_passed -= 60.0
		game_minute += 1

		if game_minute >= 60:
			game_minute = 0
			game_hour += 1

			if game_hour >= 24:
				game_hour = 0

	Game.game_hour = game_hour
	Game.game_minute = game_minute

	if (game_hour >= 0 && game_hour < 5):
		darkness.color = color_scheme[0]
		light.energy = light_schemes[0]

	elif (game_hour >= 11 && game_hour < 15):
		darkness.color = color_scheme[4]
		light.energy = light_schemes[4]

	elif (game_hour >= 15 && game_hour < 20):
		darkness.color = color_scheme[4]
		light.energy = light_schemes[0]

	elif (game_hour >= 20 && game_hour < 24):
		darkness.color = color_scheme[2]
		light.energy = light_schemes[2]
