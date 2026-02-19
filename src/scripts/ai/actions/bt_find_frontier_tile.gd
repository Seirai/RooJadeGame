class_name BTFindFrontierTile
extends BTAction
## Finds the nearest unexplored frontier tile and sets it as the move target.
##
## Sets blackboard["move_target"] (Vector2) and blackboard["scout_target_cell"] (Vector2i).
## Returns SUCCESS if a frontier tile was found, FAILURE if none available.
## Requires blackboard keys: "world_grid" (WorldGrid), "roo" (Roo).

func _execute(_delta: float) -> Enums.BTStatus:
	var world_grid = blackboard.get_value("world_grid")
	if world_grid == null:
		return Enums.BTStatus.FAILURE

	var roo = blackboard.get_value("roo")
	if roo == null:
		return Enums.BTStatus.FAILURE

	var frontiers: Array[Vector2i] = world_grid.get_frontier_cells()

	if frontiers.is_empty():
		return Enums.BTStatus.FAILURE

	# Find the closest passable frontier tile.
	# Non-passable cells (rock walls) are excluded: the Roo can't enter them
	# and claim_tile_immediate rejects them, so targeting them causes a stuck state.
	var roo_pos: Vector2 = roo.global_position
	var best_cell: Vector2i = Vector2i(-999999, -999999)
	var best_dist: float = INF

	for cell in frontiers:
		if not world_grid.is_passable(cell):
			continue
		var cell_world: Vector2 = world_grid.cell_to_world(cell)
		var dist = roo_pos.distance_squared_to(cell_world)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell

	if best_dist == INF:
		return Enums.BTStatus.FAILURE  # No passable frontier tiles available

	blackboard.set_value("move_target", world_grid.cell_to_world(best_cell))
	blackboard.set_value("scout_target_cell", best_cell)
	return Enums.BTStatus.SUCCESS
