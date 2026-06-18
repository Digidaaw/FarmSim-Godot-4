extends Panel

const PADDING := Vector2(24, 16)

@onready var label: Label = $Label

func _ready() -> void:
	_update_size()

func _process(_delta: float) -> void:
	_update_size()

func _update_size() -> void:
	if label == null:
		return
		
	# Apply dynamic styling based on error state
	var is_error = get_meta("is_error", false)
	var style = get_theme_stylebox("panel").duplicate()
	if is_error:
		style.bg_color = Color(0.25, 0.1, 0.1, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.2, 0.2, 1.0)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85, 1.0))
	else:
		style.bg_color = Color(1.0, 1.0, 1.0, 0.85)
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	add_theme_stylebox_override("panel", style)

	var font = label.get_theme_font("font")
	var font_size = label.get_theme_font_size("font_size")
	
	# Calculate text size
	var single_line_width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_width = clamp(single_line_width, 60, 240)
	var text_size = font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		text_width,
		font_size
	)
	
	# Update label size and position locally
	label.size = text_size
	size = text_size + PADDING
	label.position = (size - text_size) / 2
	
	# Keep panel centered horizontally relative to its new size
	pivot_offset = size / 2
	position.x = (get_viewport_rect().size.x - size.x) / 2
	
	# Set vertical position based on error type
	if is_error:
		position.y = 20
	else:
		position.y = 220 # Original vertical location near the player
