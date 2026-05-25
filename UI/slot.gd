extends TextureButton


var has_item = false
var itemIcon = preload("res://UI/Free Inventory/Inventory_background.png")
var itemName = ""
var itemCount = 0

func _ready():
	get_node("Info").hide()

func set_item(new_name: String, new_count, new_icon: Texture2D) -> void:
	has_item = true
	itemName = new_name
	itemCount = new_count
	itemIcon = new_icon

func clear_item() -> void:
	has_item = false
	itemName = ""
	itemCount = 0

func _process(delta) : 
	if itemCount == 0:
		get_node("Item").hide()
		get_node("Count").hide()
		get_node("Info").hide()
	else:
		get_node("Count").show()
		get_node("Count").text = str(int(itemCount))
		
	if has_item == true:
		match itemName:
			"Corn":
				itemIcon = load("res://Sprout Lands - Sprites - Basic pack/Objects/Corn.png")
			"Tomato":
				itemIcon = load("res://Sprout Lands - Sprites - Basic pack/Objects/Tomato.png")
		get_node("Item").texture = itemIcon
		get_node("Item").show()
	else:
		get_node("Item").hide()


func _on_mouse_entered() -> void:
	if has_item:
		get_node("Info").show()
		get_node("Info/Label").text = "Name: " + str(itemName) + "\n" + "Count: " + str(int(itemCount))


func _on_mouse_exited() -> void:
	get_node("Info").hide()
