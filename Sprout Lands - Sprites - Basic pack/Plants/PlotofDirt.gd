extends Area2D
const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")

var has_seed = false

@onready var seeds_node = $Seeds

func _on_dirt_2_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if !has_seed:
		if event.is_action_pressed("Spawn"):
			print("Spawning seed!")
			match Game.Selected:
				0:
					var plant1 = Corn.instantiate()
					seeds_node.add_child(plant1)       # add_child DULU
					plant1.global_position = global_position  # baru set posisi
					#plant1.position = self.position  # baru set posisi
					has_seed = true
				1: 
					var plant1 = Tomato.instantiate()
					seeds_node.add_child(plant1)       # add_child DULU
					plant1.global_position = global_position  # baru set posisi
					#plant1.position = self.position  # baru set posisi
					has_seed = true
