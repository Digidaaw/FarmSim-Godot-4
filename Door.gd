extends Node2D

@export_file("*.tscn") var target_scene_path: String = "res://HomeInterior.tscn"
@export var auto_enter_after_open := true
@export var use_target_spawn_position := false
@export var target_spawn_position := Vector2.ZERO

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var prompt: Label = $Prompt
@onready var prompt_panel: Panel = $PromptPanel
@onready var door_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D

const PROMPT_OFFSET := Vector2(-10, -34)

var player_nearby := false
var is_open := false
var is_transitioning := false

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
		_interact()

func _update_prompt_position() -> void:
	prompt.global_position = global_position + PROMPT_OFFSET
	prompt_panel.global_position = prompt.global_position

func _interact() -> void:
	if is_transitioning:
		return

	if is_open:
		close_door()
		return

	await open_door()

	if auto_enter_after_open and target_scene_path != "":
		if use_target_spawn_position:
			StageManager.stage_change(target_scene_path, target_spawn_position)
		else:
			StageManager.stage_change(target_scene_path)

func open_door() -> void:
	if is_open:
		return

	is_transitioning = true
	_set_prompt_visible(false)
	animation_player.play("Open Door")
	await animation_player.animation_finished
	is_open = true
	door_collision.disabled = true
	is_transitioning = false

func close_door() -> void:
	if not is_open:
		return

	is_transitioning = true
	animation_player.play("Close Door")
	await animation_player.animation_finished
	is_open = false
	door_collision.disabled = false
	is_transitioning = false
	if player_nearby:
		_set_prompt_visible(true)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is PersistentState:
		player_nearby = true
		if not is_transitioning:
			_set_prompt_visible(true)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is PersistentState:
		player_nearby = false
		_set_prompt_visible(false)

func _set_prompt_visible(should_show: bool) -> void:
	prompt.visible = should_show
	prompt_panel.visible = should_show
	if should_show:
		Game.register_interactable(self, "door")
	else:
		Game.unregister_interactable(self)
