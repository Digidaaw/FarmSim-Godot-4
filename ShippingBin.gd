extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var prompt: Label = $Prompt
@onready var prompt_panel: Panel = $PromptPanel

const PROMPT_OFFSET := Vector2(-10, -30)

var player_nearby := false
var is_open := false

func _ready() -> void:
	_update_prompt_text()
	_update_prompt_position()
	_set_prompt_visible(false)
	if Utils.has_signal("keybinds_changed"):
		Utils.keybinds_changed.connect(_update_prompt_text)

func _update_prompt_text() -> void:
	prompt.text = Utils.get_key_label_for_action("Interact")

func _process(_delta: float) -> void:
	_update_prompt_position()
	if player_nearby and Input.is_action_just_pressed("Interact"):
		_ship_harvest()

func _ship_harvest() -> void:
	var result = Game.ship_all_harvest()
	Utils.notif(str(result.get("Message", "")))
	if result.get("Success", false):
		Utils.save_game()
		_play_bin()

func _play_bin() -> void:
	if animation_player == null:
		return
	animation_player.play("Open Bin")
	await animation_player.animation_finished
	animation_player.play("Close Bin")

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is PersistentState:
		player_nearby = true
		_set_prompt_visible(true)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is PersistentState:
		player_nearby = false
		_set_prompt_visible(false)

func _update_prompt_position() -> void:
	prompt.global_position = global_position + PROMPT_OFFSET
	prompt_panel.global_position = prompt.global_position

func _set_prompt_visible(should_show: bool) -> void:
	prompt.visible = should_show
	prompt_panel.visible = should_show
