class_name BTScoutTile
extends BTAction
## Scout and claim the target frontier tile via a timed dwell.
##
## On the first tick the tile transitions UNKNOWN -> SCOUTED so the world grid
## reflects the discovery immediately. The Roo then dwells at the tile for
## CLAIM_DURATION seconds before the tile is claimed.
##
## Returns RUNNING while dwelling, SUCCESS when the tile is claimed.
## Returns FAILURE if required blackboard data is missing.
##
## Future extensibility: override _get_claim_duration() per-roo to factor in
## research (EXPLORATION_GEAR), progression stage, and Roo experience.
##
## Requires blackboard keys: "settlement" (Settlement), "roo" (Roo),
##                           "scout_target_cell" (Vector2i).

## Base seconds a scout must dwell to claim a tile at real-game speed.
## Divided by GameManager.debug_speed at runtime (default 60× in debug builds).
const CLAIM_DURATION: float = 120.0

var _timer: float = 0.0
var _scouted: bool = false
## The cell currently reserved in WorldGrid so other scouts skip it.
var _reserved_cell: Vector2i = Vector2i.MIN


func _on_start() -> void:
	_timer = 0.0
	_scouted = false
	# Reserve the target cell immediately so no other scout picks the same tile.
	var cell = blackboard.get_value("scout_target_cell")
	var world_grid: WorldGrid = blackboard.get_value("world_grid")
	var roo = blackboard.get_value("roo")
	if cell is Vector2i and world_grid:
		_reserved_cell = cell
		world_grid.reserve_scout_target(cell, roo.roo_id if roo else -1)
	else:
		_reserved_cell = Vector2i.MIN


func _execute(delta: float) -> Enums.BTStatus:
	var settlement: Settlement = blackboard.get_value("settlement")
	var roo = blackboard.get_value("roo")
	var cell = blackboard.get_value("scout_target_cell")

	if settlement == null or roo == null or not cell is Vector2i:
		return Enums.BTStatus.FAILURE

	# Mark the tile as scouted on the first tick so the world grid updates immediately.
	if not _scouted:
		settlement.scout_tile(cell, roo.roo_id)
		_scouted = true
		blackboard.set_value("activity_state", "Claiming")

	# Dwell until the claim duration elapses.
	_timer += delta
	if _timer < _get_claim_duration():
		return Enums.BTStatus.RUNNING

	# Dwell complete — claim the tile and finish.
	settlement.claim_tile_direct(cell)
	blackboard.erase_key("scout_target_cell")
	return Enums.BTStatus.SUCCESS


func _on_end(_status: Enums.BTStatus) -> void:
	_timer = 0.0
	_scouted = false
	blackboard.erase_key("activity_state")
	# Release the reservation so the cell becomes available again if the dwell
	# was aborted, or to keep reservations tidy on success.
	if _reserved_cell != Vector2i.MIN:
		var world_grid: WorldGrid = blackboard.get_value("world_grid")
		if world_grid:
			world_grid.release_scout_target(_reserved_cell)
		_reserved_cell = Vector2i.MIN


## Returns the effective dwell duration for this Roo.
## Divides by GameManager.debug_speed so the DevConsole can accelerate time.
## Override or extend to apply research/progression/experience modifiers.
func _get_claim_duration() -> float:
	var speed := GameManager.debug_speed if GameManager else 1.0
	return CLAIM_DURATION / maxf(speed, 0.01)
