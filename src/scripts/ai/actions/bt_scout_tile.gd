class_name BTScoutTile
extends BTAction
## Executes scouting on the target tile via the Settlement system.
##
## Calls settlement.scout_tile() and settlement.try_claim_tile().
## Returns SUCCESS after scouting, FAILURE if required data is missing.
## Requires blackboard keys: "settlement" (Settlement), "roo" (Roo),
##                           "scout_target_cell" (Vector2i).

func _execute(_delta: float) -> Enums.BTStatus:
	var settlement = blackboard.get_value("settlement")
	var roo = blackboard.get_value("roo")
	var cell = blackboard.get_value("scout_target_cell")

	if settlement == null or roo == null or not cell is Vector2i:
		return Enums.BTStatus.FAILURE

	settlement.scout_tile(cell, roo.roo_id)
	settlement.try_claim_tile(cell)

	# Clear the scouted cell from blackboard
	blackboard.erase_key("scout_target_cell")

	return Enums.BTStatus.SUCCESS
