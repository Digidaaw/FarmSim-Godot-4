extends PanelContainer

@onready var label: Label = $Label

func _ready() -> void:
	_update_position()

func _process(_delta: float) -> void:
	_update_position()

func _update_position() -> void:
	if label == null:
		return
		
	# Dynamically check text width to toggle autowrap and remove empty gaps
	var font = label.get_theme_font("font")
	var font_size = label.get_theme_font_size("font_size")
	var text_width = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	var max_width = 240.0
	if text_width > max_width:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = max_width
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = 0
		
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
		position.y = 20
	else:
		style.bg_color = Color(1.0, 1.0, 1.0, 0.85)
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
		position.y = 160
	add_theme_stylebox_override("panel", style)
	
	# Force the PanelContainer to shrink-to-fit its dynamic content size
	size = get_combined_minimum_size()
	
	# Keep panel centered horizontally relative to its dynamic container size
	pivot_offset = size / 2
	position.x = (get_viewport_rect().size.x - size.x) / 2
