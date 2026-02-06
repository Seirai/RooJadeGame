extends Sprite2D
class_name DebugSprite
## Drop-in replacement for AnimatedSprite2D that displays debug text overlays.
##
## Provides visual feedback for entity states during development by rendering
## text labels over a placeholder image. Compatible with existing animation
## code that calls play() and checks the animation property.

#region AnimatedSprite2D Compatibility

## Current animation name - updated when play() is called
var animation: StringName = &"idle":
	set(value):
		if animation != value:
			animation = value
			_update_state_display()
			animation_changed.emit()

## Optional SpriteFrames for animation validation (not used, but matches API)
var sprite_frames: SpriteFrames = null

## Internal playing state
var _is_playing: bool = false

## Signals matching AnimatedSprite2D
signal animation_changed()
signal animation_finished()
signal animation_looped()
signal frame_changed()

## Play animation - called by _update_animations() in player.gd and similar
func play(anim_name: StringName = &"", _custom_speed: float = 1.0, _from_end: bool = false) -> void:
	if anim_name != &"":
		animation = anim_name
	_is_playing = true
	# Emit finished immediately since we have no frames (matches single-frame behavior)
	animation_finished.emit()


func stop() -> void:
	_is_playing = false


func is_playing() -> bool:
	return _is_playing


func get_frame() -> int:
	return 0

#endregion

#region Debug Configuration

## Display name shown above sprite
@export var display_name: String = "":
	set(value):
		display_name = value
		if _name_label:
			_name_label.text = value
			_name_label.visible = show_name and value != ""

## Show debug labels
@export var show_labels: bool = true:
	set(value):
		show_labels = value
		if _labels_container:
			_labels_container.visible = value

## Show name label
@export var show_name: bool = true:
	set(value):
		show_name = value
		if _name_label:
			_name_label.visible = value and display_name != ""

## Show extra info label
@export var show_info: bool = false:
	set(value):
		show_info = value
		if _info_label:
			_info_label.visible = value

## Offset for labels above sprite
@export var label_offset: Vector2 = Vector2(0, -32)

## Debug text font size
@export var font_size: int = 12

## Fallback shape when no texture (0 = rect, 1 = circle)
@export_enum("Rectangle", "Circle") var fallback_shape: int = 0

## Fallback shape size
@export var fallback_size: Vector2 = Vector2(32, 32)

## Fallback shape color
@export var fallback_color: Color = Color.MAGENTA

## Custom animation -> color mapping (overrides defaults)
@export var state_colors: Dictionary = {}

#endregion

#region Internal References

var _labels_container: Control
var _name_label: Label
var _state_label: Label
var _info_label: Label
var _flash_timer: Timer
var _original_modulate: Color = Color.WHITE

#endregion

#region Default Colors

const DEFAULT_STATE_COLORS: Dictionary = {
	&"idle": Color(0.533, 0.533, 0.533),      # Gray #888888
	&"run": Color(0.267, 0.667, 0.267),       # Green #44AA44
	&"jump": Color(0.267, 0.667, 0.667),      # Cyan #44AAAA
	&"fall": Color(0.267, 0.4, 0.667),        # Blue #4466AA
	&"dash": Color(0.867, 0.867, 0.267),      # Yellow #DDDD44
	&"death": Color(0.4, 0.133, 0.133),       # Dark Red #662222
	&"attack": Color(0.867, 0.267, 0.267),    # Red #DD4444
	&"working": Color(0.267, 0.533, 0.867),   # Blue #4488DD
	&"scouting": Color(0.867, 0.867, 0.267),  # Yellow #DDDD44
	&"building": Color(0.867, 0.533, 0.267),  # Orange #DD8844
	&"harvesting": Color(0.533, 0.867, 0.267),# Lime #88DD44
}

#endregion

#region Lifecycle

func _ready() -> void:
	_create_labels()
	_create_flash_timer()
	_update_state_display()
	_update_label_scale()

	# Draw fallback shape if no texture
	if not texture:
		queue_redraw()


func _process(_delta: float) -> void:
	# Keep labels at fixed size regardless of sprite scale
	_update_label_scale()


func _draw() -> void:
	# Draw fallback shape when no texture is assigned
	if texture:
		return

	match fallback_shape:
		0:  # Rectangle
			draw_rect(Rect2(-fallback_size / 2, fallback_size), fallback_color)
		1:  # Circle
			draw_circle(Vector2.ZERO, fallback_size.x / 2, fallback_color)

#endregion

#region Debug-Specific API

## Set the display name shown above sprite
func set_display_name(new_name: String) -> void:
	display_name = new_name


## Set additional info text (profession, target, etc.)
func set_info(info: String) -> void:
	if _info_label:
		_info_label.text = info
		_info_label.visible = show_info and info != ""


## Set placeholder texture at runtime
func set_placeholder(new_texture: Texture2D) -> void:
	texture = new_texture
	queue_redraw()


## Flash the sprite (for damage, selection, etc.)
func flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	_original_modulate = modulate
	modulate = color
	_flash_timer.start(duration)


## Set visibility of debug labels
func set_labels_visible(labels_visible: bool) -> void:
	show_labels = labels_visible

#endregion

#region Internal

func _create_labels() -> void:
	# Create container for labels (Control node for UI positioning)
	_labels_container = Control.new()
	_labels_container.name = "LabelsContainer"
	_labels_container.z_index = 4096  # High z-index to render above everything
	_labels_container.z_as_relative = false  # Absolute z-index, not relative to parent
	_labels_container.position = label_offset
	_labels_container.visible = show_labels
	add_child(_labels_container)

	# Create name label
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", font_size)
	_name_label.text = display_name
	_name_label.visible = show_name and display_name != ""
	_name_label.position = Vector2(-50, -font_size * 3)
	_name_label.size = Vector2(100, font_size + 4)
	_labels_container.add_child(_name_label)

	# Create state label
	_state_label = Label.new()
	_state_label.name = "StateLabel"
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", font_size)
	_state_label.position = Vector2(-50, -font_size * 2)
	_state_label.size = Vector2(100, font_size + 4)
	_labels_container.add_child(_state_label)

	# Create info label
	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", font_size)
	_info_label.visible = show_info
	_info_label.position = Vector2(-50, -font_size)
	_info_label.size = Vector2(100, font_size + 4)
	_labels_container.add_child(_info_label)


func _create_flash_timer() -> void:
	_flash_timer = Timer.new()
	_flash_timer.name = "FlashTimer"
	_flash_timer.one_shot = true
	_flash_timer.timeout.connect(_on_flash_timeout)
	add_child(_flash_timer)


func _update_state_display() -> void:
	if not _state_label:
		return

	# Update text (uppercase for visibility)
	_state_label.text = str(animation).to_upper()

	# Update color from custom colors, then defaults, then white
	var color = state_colors.get(animation, DEFAULT_STATE_COLORS.get(animation, Color.WHITE))
	_state_label.modulate = color


func _on_flash_timeout() -> void:
	modulate = _original_modulate


func _update_label_scale() -> void:
	if not _labels_container:
		return
	# Counter-scale labels to maintain fixed size regardless of sprite scale
	var current_scale = global_scale
	if current_scale.x != 0 and current_scale.y != 0:
		var inverse_scale = Vector2(1.0 / current_scale.x, 1.0 / current_scale.y)
		_labels_container.scale = inverse_scale
		# Position must also be scaled to maintain constant visual offset
		# (otherwise label_offset gets multiplied by sprite scale, appearing too close)
		_labels_container.position = label_offset * inverse_scale

#endregion
