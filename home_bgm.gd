extends Node

@export var home_music: AudioStream

@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if home_music == null:
		return

	music_player.stream = home_music
	music_player.play()

	music_player.finished.connect(_on_music_finished)


func _on_music_finished() -> void:
	music_player.play()
