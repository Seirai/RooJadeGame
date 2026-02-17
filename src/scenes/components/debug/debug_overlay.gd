extends Node2D
class_name DebugOverlay
## Lightweight debug label overlay that draws text above an entity.
##
## Add as a child of any node to display debug information (name, state, info).
## Uses draw_string() for rendering — no Control nodes required.
## Designed to be easily stripped from release builds.

#region Debug Configuration

## Display name shown as the top line
@export var display_name: String = "":
	set(value):
		display_name = value
		queue_redraw()

## Show all debug labels
@export var show_labels: bool = true:
	set(value):
		show_labels = value
		visible = value

## Show name label
@export var show_name: bool = true:
	set(value):
		show_name = value
		queue_redraw()

## Show extra info label
@export var show_info: bool = false:
	set(value):
		show_info = value
		queue_redraw()

## Offset for labels above parent (in screen pixels)
@export var label_offset: Vector2 = Vector2(0, -32)

## Debug text font size (in screen pixels)
@export var font_size: int = 12

## Custom state -> color mapping (overrides defaults)
@export var state_colors: Dictionary = {}

#endregion

#region Internal State

var _state_text: String = ""
var _state_color: Color = Color(0.533, 0.533, 0.533)
var _info_text: String = ""

#endregion

#region Default Colors

const DEFAULT_STATE_COLORS: Dictionary = {
	&"idle": Color(0.533, 0.533, 0.533),      # Gray
	&"run": Color(0.267, 0.667, 0.267),       # Green
	&"jump": Color(0.267, 0.667, 0.667),      # Cyan
	&"fall": Color(0.267, 0.4, 0.667),        # Blue
	&"dash": Color(0.867, 0.867, 0.267),      # Yellow
	&"death": Color(0.4, 0.133, 0.133),       # Dark Red
	&"attack": Color(0.867, 0.267, 0.267),    # Red
	&"working": Color(0.267, 0.533, 0.867),   # Blue
	&"scouting": Color(0.867, 0.867, 0.267),  # Yellow
	&"building": Color(0.867, 0.533, 0.267),  # Orange
	&"harvesting": Color(0.533, 0.867, 0.267),# Lime
}

const OUTLINE_SIZE: int = 3

#endregion

#region Lifecycle

func _ready() -> void:
	z_index = 100
	z_as_relative = false
	queue_redraw()


func _draw() -> void:
	if not show_labels:
		return

	var font: Font = ThemeDB.fallback_font
	if not font:
		return

	# Compensate for parent scale so text appears at constant screen size
	var s: Vector2 = global_scale
	if s.x == 0 or s.y == 0:
		return
	var inv := Vector2(1.0 / s.x, 1.0 / s.y)
	var scaled_fs: int = int(font_size * inv.x)
	var scaled_outline: int = int(OUTLINE_SIZE * inv.x)
	var base_pos: Vector2 = label_offset * inv

	var line_h: float = (font_size + 4) * inv.y
	var y_cursor: float = base_pos.y

	# Draw name (topmost line)
	if show_name and display_name != "":
		_draw_centered_text(font, Vector2(base_pos.x, y_cursor), display_name, scaled_fs, scaled_outline, Color.WHITE)
		y_cursor += line_h

	# Draw state
	if _state_text != "":
		_draw_centered_text(font, Vector2(base_pos.x, y_cursor), _state_text, scaled_fs, scaled_outline, _state_color)
		y_cursor += line_h

	# Draw info
	if show_info and _info_text != "":
		_draw_centered_text(font, Vector2(base_pos.x, y_cursor), _info_text, scaled_fs, scaled_outline, Color.WHITE)

#endregion

#region Public API

## Set the display name shown as the top line
func set_display_name(new_name: String) -> void:
	display_name = new_name


## Set state text with automatic color lookup
func set_state(state_name: StringName) -> void:
	_state_text = str(state_name).to_upper()
	_state_color = state_colors.get(state_name, DEFAULT_STATE_COLORS.get(state_name, Color.WHITE))
	queue_redraw()


## Set additional info text (profession, target, etc.)
func set_info(info: String) -> void:
	_info_text = info
	queue_redraw()


## Set visibility of debug labels
func set_labels_visible(labels_visible: bool) -> void:
	show_labels = labels_visible

#endregion

#region Internal

func _draw_centered_text(font: Font, pos: Vector2, text: String, size: int, outline: int, color: Color) -> void:
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var draw_pos := Vector2(pos.x - text_width / 2.0, pos.y)
	draw_string_outline(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color.BLACK)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

#endregion
