extends Panel

const PADDING := Vector2(16, 16)
const MIN_TEXT_SIZE := Vector2(32, 18)
const MAX_TEXT_WIDTH := 320.0

@onready var label: Label = get_node("../Label")

func _ready() -> void:
	_update_size()

func _process(_delta):
	_update_size()

func _update_size() -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var single_line_width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_width = clamp(single_line_width, MIN_TEXT_SIZE.x, MAX_TEXT_WIDTH)
	var text_size := font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		text_width,
		font_size
	)
	text_size.x = max(text_size.x, MIN_TEXT_SIZE.x)
	text_size.y = max(text_size.y, MIN_TEXT_SIZE.y)
	var new_size := text_size + PADDING
	size = new_size
	label.size = text_size
	label.global_position = global_position + (PADDING / 3.5)
	
