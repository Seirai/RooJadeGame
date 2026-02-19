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

## Base seconds a scout must dwell to claim a tile.
const CLAIM_DURATION: float = 5.0

var _timer: float = 0.0
var _scouted: bool = false


func _on_start() -> void:
	_timer = 0.0
	_scouted = false


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


## Returns the effective dwell duration for this Roo.
## Override or extend to apply research/progression/experience modifiers.
func _get_claim_duration() -> float:
	return CLAIM_DURATION
