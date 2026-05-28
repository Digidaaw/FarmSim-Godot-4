extends Node2D

func _ready() -> void:
	if has_node("Player"):
		StageManager.apply_player_spawn($Player, Vector2(480, 395))
