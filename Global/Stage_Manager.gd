extends CanvasLayer

const MainMenu = "res://MainMenu.tscn"
const MainWorld = "res://World.tscn"

func stage_change(stage_path):
	get_node("ColorRect").show()
	var old_layer = layer
	layer = 5
	get_node("anim").play("Fade In")
	await get_node("anim").animation_finished
	
	get_tree().change_scene_to_file(stage_path)
	layer = old_layer
	get_node("anim").play("Fade Out")
	#get_node("ColorRect").hide()
