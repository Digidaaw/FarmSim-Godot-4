extends Panel


func _process(delta):
	size.x = get_node("../Label").size.x + 16
	size.y = get_node("../Label").size.y + 16
	
