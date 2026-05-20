extends CharacterBody2D

class_name PersistentState

var state
var state_manager

var speed = 100
var last_direction: String = "down"

func _ready():
	state_manager = StateManager.new()
	change_state("idle")
	
func get_input():
	Utils.save_game()
	velocity = Vector2()
	if Input.is_action_pressed("ui_left"):
		move_left()
	elif Input.is_action_pressed("ui_right"):
		move_right()
	elif Input.is_action_pressed("ui_down"):
		move_down()
	elif Input.is_action_pressed("ui_up"):
		move_up()
	velocity = velocity.normalized()*speed
		
func _physics_process(_delta):
	get_input()
	move_and_slide()
	
func move_left():
	state.move_left()
	
func move_right():
	state.move_right()
	
func move_down():
	state.move_down()
	
func move_up( ):
	state.move_up()

func change_state(new_state_name):
	
	if state != null:
		state.queue_free()
		
	state = state_manager.get_state(new_state_name).new()
	
	state.setup(Callable(self, "change_state"), get_node("AnimationPlayer"), self )
	state.name = str(new_state_name)
	add_child(state)
