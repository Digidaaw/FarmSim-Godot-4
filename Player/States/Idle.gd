extends State

class_name IdleState

func _physics_process(_delta):
	match persistent_state.last_direction:
		"down":
			animation.play("Idle")
		"up":
			animation.stop()
			persistent_state.get_node("Sprite2D").frame = 4
		"left":
			animation.stop()
			persistent_state.get_node("Sprite2D").frame = 8
		"right":
			animation.stop()
			persistent_state.get_node("Sprite2D").frame = 12


func move_left():
	change_state.call("run")
	
func move_right():
	change_state.call("run")

func move_up():
	change_state.call("run")
	
func move_down():
	change_state.call("run")
