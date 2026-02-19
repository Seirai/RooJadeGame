extends Node2D
class_name TileStateOverlay
## World-space debug overlay that color-codes every grid cell by gameplay category.
##
## Priority (highest wins per cell):
##   Resource Node — orange  (has a harvestable resource)
##   Structure     — purple  (settlement has built on it)
##   Hostile       — red     (threat_level > 0)
##   Claimed       — green   (settlement territory)
##   Free          — blue    (scouted, unclaimed, safe)
##   (UNKNOWN cells are not drawn)
##
## Redraws every process tick via queue_redraw() — always reflects current WorldGrid state.
## Toggleable via `debug overlays on|off` in the DevConsole.
## Excluded from production builds via export filter: src/scenes/components/debug/*

#region Constants

const COLOR_FREE:      Color = Color(0.40, 0.70, 1.00, 0.25)
const COLOR_CLAIMED:   Color = Color(0.10, 0.75, 0.30, 0.30)
const COLOR_RESOURCE:  Color = Color(0.95, 0.60, 0.10, 0.40)
const COLOR_HOSTILE:   Color = Color(0.85, 0.15, 0.15, 0.35)
const COLOR_STRUCTURE: Color = Color(0.65, 0.25, 0.90, 0.40)

#endregion

#region State

var _wg: WorldGrid = null
var _cell_size: Vector2 = Vector2.ZERO

#endregion

#region Lifecycle

func _ready() -> void:
	z_index = 50
	z_as_relative = false
	add_to_group("debug_overlay")

	_wg = GameManager.WorldGridService
	if not _wg:
		push_warning("TileStateOverlay: WorldGridService not available")
		return

	_compute_cell_size()


func _process(_delta: float) -> void:
	if _wg and visible:
		queue_redraw()

#endregion

#region Drawing

func _draw() -> void:
	if not _wg or _cell_size == Vector2.ZERO:
		return

	var bounds: Rect2i = _wg.get_bounds()
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var cell := Vector2i(x, y)
			if not _wg.has_cell(cell):
				continue
			var color: Color = _cell_color(cell)
			if color.a == 0.0:
				continue
			var local_pos: Vector2 = to_local(_wg.cell_to_world(cell))
			draw_rect(Rect2(local_pos - _cell_size * 0.5, _cell_size), color)


## Determine the display color for a cell based on priority: Resource > Structure > Hostile > Claimed > Free.
## Resource nodes are shown regardless of territory state (debug tool — visible through fog).
## Returns transparent for UNKNOWN cells with no special data.
func _cell_color(cell: Vector2i) -> Color:
	# Resource nodes always visible, even if the cell hasn't been scouted yet.
	if _wg.get_resource_node(cell) >= 0:
		return COLOR_RESOURCE

	var territory: Enums.TileState = _wg.get_territory_state(cell)
	if territory == Enums.TileState.UNKNOWN:
		return Color.TRANSPARENT
	if _wg.get_building(cell) != null:
		return COLOR_STRUCTURE
	if _wg.get_threat_level(cell) > 0:
		return COLOR_HOSTILE
	if territory == Enums.TileState.CLAIMED:
		return COLOR_CLAIMED
	return COLOR_FREE  # SCOUTED, no resource, no threat

#endregion

#region Public API

## Set visibility — called by DevConsole's `debug overlays` command via the debug_overlay group.
func set_labels_visible(value: bool) -> void:
	visible = value

#endregion

#region Internal

func _compute_cell_size() -> void:
	# Derive pixel dimensions from adjacent cell world positions.
	var c0: Vector2 = _wg.cell_to_world(Vector2i(0, 0))
	var c1: Vector2 = _wg.cell_to_world(Vector2i(1, 0))
	var c2: Vector2 = _wg.cell_to_world(Vector2i(0, 1))
	_cell_size = Vector2(absf(c1.x - c0.x), absf(c2.y - c0.y))

#endregion
