extends CanvasLayer

const MainMenu = "res://MainMenu.tscn"
const MainWorld = "res://World.tscn"
const HomeInterior = "res://HomeInterior.tscn"

var _has_next_player_spawn := false
var _next_player_spawn_position := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func stage_change(stage_path, spawn_position = null):
	get_tree().paused = false
	if spawn_position != null:
		_has_next_player_spawn = true
		_next_player_spawn_position = spawn_position

	get_node("ColorRect").show()
	var old_layer = layer
	layer = 5
	get_node("anim").play("Fade In")
	await get_node("anim").animation_finished
	
	get_tree().change_scene_to_file(stage_path)
	layer = old_layer
	get_node("anim").play("Fade Out")
	await get_node("anim").animation_finished
	get_node("ColorRect").hide()

func apply_player_spawn(player: Node2D, fallback_position: Vector2) -> void:
	if _has_next_player_spawn:
		player.position = _next_player_spawn_position
		_has_next_player_spawn = false
	else:
		player.position = fallback_position
