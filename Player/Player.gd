extends CharacterBody2D

class_name PersistentState

var state
var state_manager
var is_watering := false

var speed = 100
var last_direction: String = "down"
var is_hoeing := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var walk_sprite: Sprite2D = $Sprite2D
@onready var hoe_sprite: Sprite2D = $Sprite2D2

const HOE_INPUT := "Hoe"
const HOE_ANIMATIONS := {
	"down": "Hoeing Down",
	"up": "Hoeing Up",
	"left": "Hoeing Left",
	"right": "Hoeing Right",
}
const HOE_DURATION := 3.0

const WATER_ANIMATIONS := {
	"down": "Watering Down",
	"up": "Watering Up",
	"left": "Watering Left",
	"right": "Watering Right",
}	
const WATER_DURATION := 1.5

func _ready():
	state_manager = StateManager.new()
	change_state("idle")

	walk_sprite.visible = true
	hoe_sprite.visible = false
	
func get_input():
	velocity = Vector2.ZERO

	if is_hoeing or is_watering:
		return

	if Input.is_action_just_pressed(HOE_INPUT):
		hoe()
		return

	if Input.is_action_pressed("ui_left"):
		move_left()
	elif Input.is_action_pressed("ui_right"):
		move_right()
	elif Input.is_action_pressed("ui_down"):
		move_down()
	elif Input.is_action_pressed("ui_up"):
		move_up()

	velocity = velocity.normalized() * speed
		
func _physics_process(_delta):
	get_input()
	move_and_slide()

func hoe():
	is_hoeing = true
	velocity = Vector2.ZERO

	if state != null:
		state.set_process(false)
		state.set_physics_process(false)

	walk_sprite.visible = false
	hoe_sprite.visible = true
	hoe_sprite.frame = 0

	var hoe_animation = HOE_ANIMATIONS.get(last_direction, "Hoeing Down")

	animation_player.stop()
	animation_player.play(hoe_animation)

	await get_tree().create_timer(HOE_DURATION).timeout

	is_hoeing = false

	if state != null:
		state.set_process(true)
		state.set_physics_process(true)

	hoe_sprite.visible = false
	walk_sprite.visible = true
	change_state("idle")
	
func move_left():
	last_direction = "left"
	state.move_left()
	
func move_right():
	last_direction = "right"
	state.move_right()
	
func move_down():
	last_direction = "down"
	state.move_down()
	
func move_up():
	last_direction = "up"
	state.move_up()

func change_state(new_state_name):
	if state != null:
		state.queue_free()
		
	state = state_manager.get_state(new_state_name).new()
	state.setup(Callable(self, "change_state"), animation_player, self)
	state.name = str(new_state_name)
	add_child(state)
	
func water_animate():
	is_watering = true
	velocity = Vector2.ZERO
	# Matikan input state mesin
	if state != null:
		state.set_process(false)
		state.set_physics_process(false)
	# Sembunyikan sprite jalan, nyalakan sprite aksi ($Sprite2D2)
	walk_sprite.visible = false
	hoe_sprite.visible = true
	hoe_sprite.frame = 0
	# Ambil nama animasi menyiram sesuai arah hadap terakhir
	var water_animation = WATER_ANIMATIONS.get(last_direction, "Watering Down")
	animation_player.stop()
	animation_player.play(water_animation)
	# Tunggu sampai durasi menyiram selesai
	await get_tree().create_timer(WATER_DURATION).timeout
	is_watering = false
	# Hidupkan kembali input state mesin
	if state != null:
		state.set_process(true)
		state.set_physics_process(true)
	# Sembunyikan sprite aksi, kembalikan ke sprite jalan
	hoe_sprite.visible = false
	walk_sprite.visible = true
	change_state("idle")
