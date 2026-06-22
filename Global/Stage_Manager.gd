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

	fade_out_bgm(1.0)

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

func fade_out_bgm(duration: float = 1.0) -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		var players = []
		_find_audio_players(current_scene, players)
		for player in players:
			if player is AudioStreamPlayer and player.playing:
				var tween = create_tween()
				tween.tween_property(player, "volume_db", -80.0, duration)

func _find_audio_players(node: Node, players: Array) -> void:
	if node is AudioStreamPlayer:
		players.append(node)
	for child in node.get_children():
		_find_audio_players(child, players)

func apply_player_spawn(player: Node2D, fallback_position: Vector2) -> void:
	if _has_next_player_spawn:
		player.position = _next_player_spawn_position
		_has_next_player_spawn = false
	else:
		player.position = fallback_position
