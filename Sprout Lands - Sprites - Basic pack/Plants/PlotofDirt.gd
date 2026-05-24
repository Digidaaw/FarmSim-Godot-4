extends Area2D
const Corn = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Corn.tscn")
const Tomato = preload("res://Sprout Lands - Sprites - Basic pack/Plants/Tomato.tscn")

var has_seed = false
var canPlant = false

func get_input():
	if Input.is_action_just_pressed("Spawn"):
		if canPlant == true:
			spawn()
func _physics_process(delta):
	get_input()

@onready var seeds_node = $Seeds

func spawn():
	if !has_seed:
		print("Spawning seed!")
		match Game.Selected:
			0:
				var plant1 = Corn.instantiate()
				self.add_child(plant1)       # add_child DULU
				plant1.global_position = global_position  # baru set posisi
				#plant1.position = self.position  # baru set posisi
				has_seed = true
			1: 
				var plant1 = Tomato.instantiate()
				self.add_child(plant1)       # add_child DULU
				plant1.global_position = global_position  # baru set posisi
				#plant1.position = self.position  # baru set posisi
				has_seed = true


func _on_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		Utils.notif("Press Z to plant")
		canPlant = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		canPlant = false
