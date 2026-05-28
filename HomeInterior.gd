extends Node2D

func _ready() -> void:
	if has_node("Player"):
		$Player.position = Vector2(480, 395)
