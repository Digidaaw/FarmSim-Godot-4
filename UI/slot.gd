extends TextureButton


var has_item = false
var itemIcon = preload("res://UI/Free Inventory/Inventory_background.png")
var itemName = ""
var itemCount = 0

func _ready():
		get_node("Info").hide

func _process(delta) : 
	if itemCount == 0:
		get_node("Item").hide()
		get_node("Count").hide()
	else:
		get_node("Count").show()
		get_node("Count").text = str(itemCount)
		
	if has_item == true:
		get_node("Item").texture = itemIcon
		match itemName:
			"Corn":
				itemIcon = load("res://Sprout Lands - Sprites - Basic pack/Objects/Corn.png")
			"Tomato":
				itemIcon = load("res://Sprout Lands - Sprites - Basic pack/Objects/Tomato.png")
		get_node("Item").show()
	else:
		get_node("Item").hide()


func _on_mouse_entered() -> void:
	if has_item:
		get_node("Info").show()
		get_node("Info/Label").text = "Name: " + str(itemName) + "\n" + "Count: " + str(itemCount)


func _on_mouse_exited() -> void:
	get_node("Info").hide()
