class_name BTFindFrontierTile
extends BTAction
## Finds the nearest unexplored frontier tile and sets it as the move target.
##
## Sets blackboard["move_target"] (Vector2) and blackboard["scout_target_cell"] (Vector2i).
## Returns SUCCESS if a frontier tile was found, FAILURE if none available.
## Requires blackboard keys: "world_grid" (WorldGrid), "roo" (Roo).

func _execute(_delta: float) -> Enums.BTStatus:
	var world_grid: WorldGrid = blackboard.get_value("world_grid")
	if world_grid == null:
		return Enums.BTStatus.FAILURE

	var roo = blackboard.get_value("roo")
	if roo == null:
		return Enums.BTStatus.FAILURE

	# Release any stale reservation from a previous sequence that failed at
	# BTMoveTo (where BTScoutTile._on_start never fired to clean up).
	# Record the failed cell so this Roo won't immediately retry an unreachable tile.
	var stale_cell = blackboard.get_value("scout_target_cell")
	if stale_cell is Vector2i:
		world_grid.release_scout_target(stale_cell)
		blackboard.erase_key("scout_target_cell")
		var failed: Array = blackboard.get_value("move_failed_cells", [])
		if not failed.has(stale_cell):
			failed.append(stale_cell)
		blackboard.set_value("move_failed_cells", failed)

	var frontiers: Array[Vector2i] = world_grid.get_frontier_cells()

	if frontiers.is_empty():
		return Enums.BTStatus.FAILURE

	# Find the closest passable, unreserved, reachable frontier tile.
	# Non-passable cells (rock walls) are excluded: the Roo can't enter them.
	# Reserved cells are excluded: another scout is already claiming them.
	# Failed cells are excluded: this Roo previously got stuck trying to reach them.
	var failed_cells: Array = blackboard.get_value("move_failed_cells", [])
	var roo_pos: Vector2 = roo.global_position
	var best_cell: Vector2i = Vector2i(-999999, -999999)
	var best_dist: float = INF

	for cell in frontiers:
		if not world_grid.is_passable(cell):
			continue
		if world_grid.is_scout_reserved(cell):
			continue
		if failed_cells.has(cell):
			continue
		var cell_world: Vector2 = world_grid.cell_to_world(cell)
		var dist = roo_pos.distance_squared_to(cell_world)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell

	if best_dist == INF:
		return Enums.BTStatus.FAILURE  # No passable frontier tiles available

	# Reserve immediately — before BTMoveTo starts — so no other scout picks
	# this cell during transit.
	world_grid.reserve_scout_target(best_cell, roo.roo_id)
	blackboard.set_value("move_target", world_grid.cell_to_world(best_cell))
	blackboard.set_value("scout_target_cell", best_cell)
	return Enums.BTStatus.SUCCESS
