extends Node
class_name TerritoryManager
## Manages territory expansion through scouting and claiming.
##
## Operates on WorldGrid cells (territory_state, threat_level, scouted_at,
## claimed_at) rather than maintaining a separate data model.
## Handles the UNKNOWN -> SCOUTED -> CLAIMED tile lifecycle.
## Does not own data - reads/writes through WorldGrid service.

#region Signals

signal tile_scouted(cell_pos: Vector2i)
signal tile_claimed(cell_pos: Vector2i)
signal tile_threat_changed(cell_pos: Vector2i, threat_level: int)

#endregion

#region Configuration

## Seconds after scouting before a tile can be claimed
@export var claim_delay: float = 10.0

## Base claim delay reduction from EXPLORATION_GEAR research
@export var exploration_gear_delay_reduction: float = 5.0

#endregion

#region State References

var _claimed_tiles: Dictionary
var _stats: Dictionary
var _world_grid: WorldGrid = null

#endregion

#region Initialization

func init(claimed_tiles: Dictionary, stats: Dictionary) -> void:
	_claimed_tiles = claimed_tiles
	_stats = stats

	if GameManager and GameManager.WorldGridService:
		_world_grid = GameManager.WorldGridService
	else:
		push_warning("TerritoryManager: WorldGridService not available")

#endregion

#region Public API

## Scout a tile, transitioning it from UNKNOWN to SCOUTED
func scout_tile(cell_pos: Vector2i, scout_roo_id: int = -1) -> void:
	if not _world_grid:
		return

	var state = _world_grid.get_territory_state(cell_pos)
	if state != Enums.TileState.UNKNOWN:
		return

	_world_grid.set_territory_state(cell_pos, Enums.TileState.SCOUTED)
	_world_grid.set_scouted(cell_pos, scout_roo_id)
	tile_scouted.emit(cell_pos)


## Attempt to claim a tile (checks claiming rules)
func try_claim_tile(cell_pos: Vector2i) -> bool:
	if not _world_grid:
		return false

	if not _can_claim(cell_pos):
		return false

	_claim_tile(cell_pos)
	return true


## Get the territory state of a tile
func get_tile_state(cell_pos: Vector2i) -> Enums.TileState:
	if not _world_grid:
		return Enums.TileState.UNKNOWN
	return _world_grid.get_territory_state(cell_pos)


## Get all CLAIMED tile positions
func get_claimed_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for pos in _claimed_tiles.keys():
		tiles.append(pos)
	return tiles


## Get frontier tiles (UNKNOWN cells adjacent to known territory)
func get_frontier_tiles() -> Array[Vector2i]:
	if not _world_grid:
		return []
	return _world_grid.get_frontier_cells()


## Report a threat at a cell position
func set_threat(cell_pos: Vector2i, threat_level: int) -> void:
	if not _world_grid:
		return
	_world_grid.set_threat_level(cell_pos, threat_level)
	tile_threat_changed.emit(cell_pos, threat_level)

#endregion

#region Process

## Called from Settlement._process() to auto-claim eligible tiles
func process_claiming(delta: float) -> void:
	if not _world_grid:
		return

	var scouted_cells = _world_grid.get_cells_by_territory(Enums.TileState.SCOUTED)
	for cell_pos in scouted_cells:
		if _can_claim(cell_pos):
			_claim_tile(cell_pos)

#endregion

#region Internal

## Check if a SCOUTED tile meets all claiming requirements
func _can_claim(cell_pos: Vector2i) -> bool:
	if not _world_grid.has_cell(cell_pos):
		return false

	var cell = _world_grid.get_cell(cell_pos)

	# Must be SCOUTED
	if cell.get("territory_state") != Enums.TileState.SCOUTED:
		return false

	# Must have no threats
	if cell.get("threat_level", 0) > 0:
		return false

	# Must be adjacent to an existing CLAIMED cell
	if not _is_adjacent_to_claimed(cell_pos):
		return false

	# Claim delay must have elapsed since scouting
	var scouted_at = cell.get("scouted_at", 0.0)
	if scouted_at <= 0.0:
		return false

	var delay = _get_effective_claim_delay()
	var elapsed = Time.get_unix_time_from_system() - scouted_at
	if elapsed < delay:
		return false

	return true


## Check if cell is adjacent to any CLAIMED cell
func _is_adjacent_to_claimed(cell_pos: Vector2i) -> bool:
	# If no tiles are claimed yet, allow claiming (bootstrap case)
	if _claimed_tiles.is_empty():
		return true

	for neighbor in _world_grid.get_neighbors(cell_pos):
		if _world_grid.get_territory_state(neighbor) == Enums.TileState.CLAIMED:
			return true
	return false


## Perform the actual claim operation
func _claim_tile(cell_pos: Vector2i) -> void:
	_world_grid.set_territory_state(cell_pos, Enums.TileState.CLAIMED)
	_world_grid.set_claimed_at(cell_pos)

	_claimed_tiles[cell_pos] = {
		"claimed_at": Time.get_unix_time_from_system(),
	}

	_stats["territory_tiles_claimed"] = _stats.get("territory_tiles_claimed", 0) + 1
	tile_claimed.emit(cell_pos)


## Get the effective claim delay, accounting for research bonuses
func _get_effective_claim_delay() -> float:
	var delay = claim_delay

	# Check for EXPLORATION_GEAR research reduction
	if GameManager and GameManager.WorldGridService:
		# Access through Settlement reference would be cleaner,
		# but for now check directly via the research path
		pass

	return delay

#endregion
