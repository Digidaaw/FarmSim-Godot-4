extends Node2D


func _ready() -> void:
	self.hide()

# Called when the node enters the scene tree for the first time.
func _input(event):
	if event.is_action_pressed("Inventory"):
		if self.visible == true:
			self.hide()
		else:
			self.show()
