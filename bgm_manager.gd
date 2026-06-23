extends Node

@export var morning_playlist: Array[AudioStream] = []
@export var afternoon_playlist: Array[AudioStream] = []
@export var night_playlist: Array[AudioStream] = []

@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer

var current_period: String = ""
var current_playlist: Array[AudioStream] = []
var music_queue: Array[AudioStream] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()

	music_player.finished.connect(_on_music_finished)

	update_music(Game.game_hour)

	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(func():
		update_music(Game.game_hour)
	)
	add_child(timer)
	timer.start()


func update_music(hour: int) -> void:
	var new_period: String = get_period(hour)

	if new_period == current_period:
		return

	current_period = new_period

	if current_period == "morning":
		current_playlist = morning_playlist
	elif current_period == "afternoon":
		current_playlist = afternoon_playlist
	else:
		current_playlist = night_playlist

	make_music_queue()
	play_next_music()


func get_period(hour: int) -> String:
	if hour >= 4 and hour <= 11:
		return "morning"
	elif hour >= 12 and hour <= 18:
		return "afternoon"
	else:
		return "night"


func make_music_queue() -> void:
	music_queue = current_playlist.duplicate()
	music_queue.shuffle()


func play_next_music() -> void:
	if music_queue.is_empty():
		make_music_queue()

	if music_queue.is_empty():
		return

	var next_music: AudioStream = music_queue.pop_front()
	music_player.stream = next_music
	music_player.play()


func _on_music_finished() -> void:
	play_next_music()
