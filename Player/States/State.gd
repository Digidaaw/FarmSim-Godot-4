extends Node2D

class_name State

var change_state
var animation
var persistent_state
var velocity = 0

func _physics_process(_delta):
	persistent_state.velocity = persistent_state.velocity
	persistent_state.move_and_slide()
	
func setup(change_state, animation, persistent_state):
	self.change_state = change_state
	self.animation = animation
	self.persistent_state = persistent_state
