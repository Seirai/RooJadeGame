class_name MouseCoordOverlay
extends CanvasLayer
## Shows the world position and grid cell under the mouse cursor in the top-right
## corner of the screen. Updated every frame.
## Toggled via: debug coords on|off

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	var wg: WorldGrid = GameManager.WorldGridService if GameManager else null
	if not wg:
		_label.text = "grid: unavailable"
		return

	# Convert screen-space mouse position to world space via the canvas transform.
	var mouse_world := get_viewport().get_canvas_transform().affine_inverse() \
		* get_viewport().get_mouse_position()

	var cell := wg.world_to_cell(mouse_world)

	var state_str: String
	if wg.has_cell(cell):
		state_str = Enums.TileState.keys()[wg.get_territory_state(cell)].to_lower()
	else:
		state_str = "void"

	_label.text = "cell (%d, %d)   world (%.0f, %.0f)   %s" \
		% [cell.x, cell.y, mouse_world.x, mouse_world.y, state_str]
