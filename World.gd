extends Node2D

@onready var darkness = get_node("Ambient")
@onready var light = get_node("CharacterBody2D/PointLight2D")
@onready var dirt_container = get_node_or_null("DirtContainer")

var game_hour = 6
var game_minute = 0
var time_speed = 60.0
var time_passed = 0.0

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
				Game.advance_day()
				# Refresh tanaman di scene tree setelah ganti hari
				if dirt_container != null and dirt_container.has_method("refresh_all_plants"):
					dirt_container.refresh_all_plants()
				Utils.save_game()

	Game.game_hour = game_hour
	Game.game_minute = game_minute
	_try_collect_shipping_bin()

	# Update ambient darkness color based on time
	var total_minutes = game_hour * 60 + game_minute
	var target_color: Color
	
	var dawn_start = 5 * 60      # 5:00 AM (300 minutes)
	var sunrise_end = 7 * 60     # 7:00 AM (420 minutes)
	var sunset_start = 17 * 60   # 5:00 PM (1020 minutes)
	var night_start = 18 * 60    # 6:00 PM (1080 minutes)
	
	var dark_color = Color8(40, 40, 40)
	var bright_color = Color8(240, 240, 240)
	
	if total_minutes < dawn_start:
		# Midnight to 5:00 AM (fully dark)
		target_color = dark_color
	elif total_minutes < sunrise_end:
		# 5:00 AM to 7:00 AM (dawn transition)
		var t = float(total_minutes - dawn_start) / float(sunrise_end - dawn_start)
		target_color = dark_color.lerp(bright_color, t)
	elif total_minutes < sunset_start:
		# 7:00 AM to 5:00 PM (fully bright day)
		target_color = bright_color
	elif total_minutes < night_start:
		# 5:00 PM to 6:00 PM (sunset transition)
		var t = float(total_minutes - sunset_start) / float(night_start - sunset_start)
		target_color = bright_color.lerp(dark_color, t)
	else:
		# 6:00 PM to Midnight (fully dark)
		target_color = dark_color
		
	darkness.color = target_color
	
	# Flashlight energy depends directly on ambient darkness level.
	# Red component of target_color (ranges from 0.157 at night to 0.941 at day).
	# We turn the light off when it's bright (>= 0.5) and fully on when it's dark (<= 0.157).
	var v = target_color.r
	var target_energy: float
	if v <= 0.157:
		target_energy = 0.8
	elif v >= 0.5:
		target_energy = 0.0
	else:
		var t = (v - 0.157) / (0.5 - 0.157)
		target_energy = lerp(0.8, 0.0, t)
		
	light.energy = target_energy
	light.enabled = target_energy > 0.0

func _try_collect_shipping_bin() -> void:
	if game_hour != 17 or Game.last_shipping_collect_day == Game.game_day:
		return

	Game.last_shipping_collect_day = Game.game_day
	var result = Game.collect_shipping_bin()
	if int(result.get("Total", 0)) > 0:
		Utils.notif("Shipping +%dG" % int(result["Total"]))
	Utils.save_game()
