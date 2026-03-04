class_name ShelterPlacementService
extends RefCounted
## Pure static utility for evaluating makeshift shelter placement candidates.
##
## Scores every buildable CLAIMED cell by how well it would serve Roos that
## currently lack nearby residential housing. The same evaluate() call is
## consumed by three callers without modification:
##   autonomous  → settlement picks candidates[0] automatically
##   Twitch      → candidates presented as a viewer poll
##   player      → candidates highlighted on the map for manual selection

#region Constants

## A Roo is "served" if any residential building is within this distance of
## their work_position.  Roos beyond this threshold are underserved.
const COVERAGE_RADIUS: float = 400.0

## New shelters are not scored within this distance of existing residential
## buildings, preventing clusters that serve the same Roos redundantly.
const MIN_SHELTER_SPACING: float = 300.0

## Maximum number of candidates returned, sorted best-first.
const MAX_CANDIDATES: int = 5

#endregion


#region Candidate

## A scored candidate cell for shelter placement.
class PlacementCandidate:
	## Grid cell the shelter would occupy.
	var cell: Vector2i
	## World-space centre of that cell.
	var world_pos: Vector2
	## Composite score: higher = better.  Score ≥ 1.0 is considered actionable.
	var score: float
	## IDs of underserved Roos this placement would bring within coverage.
	var covered_roo_ids: Array[int]

	func _init(c: Vector2i, wp: Vector2, s: float, ids: Array[int]) -> void:
		cell = c
		world_pos = wp
		score = s
		covered_roo_ids = ids

#endregion


#region Public API

## Evaluate buildable CLAIMED cells and return the best shelter candidates.
##
## [param world_grid]         WorldGrid service — provides spatial queries.
## [param roos]               All AI Roo nodes to evaluate commute distance for.
## [param existing_residential] All currently placed RESIDENTIAL buildings
##                            (LIVING_QUARTERS + MAKESHIFT_SHELTER).
##                            Used both to identify underserved Roos and to
##                            enforce minimum spacing between shelters.
## [return] Array[PlacementCandidate] sorted by score descending, capped at
##          MAX_CANDIDATES.  Empty if all Roos are already served.
static func evaluate(
	world_grid: WorldGrid,
	roos: Array,
	existing_residential: Array,
) -> Array:  # Array[PlacementCandidate]

	# --- 1. Identify underserved Roos ---
	var underserved: Array = []  # Array[Roo]
	for roo in roos:
		if not roo is Node2D:
			continue
		var work_pos: Vector2 = roo.work_position if roo.has_method("get") or "work_position" in roo else roo.global_position
		var served := false
		for building in existing_residential:
			if building is Node2D and building.global_position.distance_to(work_pos) < COVERAGE_RADIUS:
				served = true
				break
		if not served:
			underserved.append(roo)

	if underserved.is_empty():
		return []

	# --- 2. Gather buildable candidate cells ---
	var claimed_cells: Array[Vector2i] = world_grid.get_cells_by_territory(Enums.TileState.CLAIMED)

	# --- 3. Score each candidate ---
	var candidates: Array = []  # Array[PlacementCandidate]

	for cell in claimed_cells:
		# Require every cell in the full footprint to be buildable.
		if not _footprint_fits(world_grid, cell):
			continue

		# Score/spacing uses the world centre of the footprint's middle cell.
		var cell_world: Vector2 = world_grid.cell_to_world(
			cell + Vector2i(MakeshiftShelter.FOOTPRINT_WIDTH / 2, 0)
		)

		# Reject if too close to an existing residential building.
		var too_close := false
		for building in existing_residential:
			if building is Node2D and building.global_position.distance_to(cell_world) < MIN_SHELTER_SPACING:
				too_close = true
				break
		if too_close:
			continue

		# Score by proximity to underserved Roos' worksites.
		var cell_score: float = 0.0
		var covered_ids: Array[int] = []

		for roo in underserved:
			var work_pos: Vector2 = roo.work_position if "work_position" in roo else roo.global_position
			var dist: float = cell_world.distance_to(work_pos)
			if dist < COVERAGE_RADIUS:
				cell_score += COVERAGE_RADIUS / maxf(dist, 1.0)
				var rid: int = roo.roo_id if "roo_id" in roo else -1
				if rid >= 0:
					covered_ids.append(rid)

		if cell_score > 0.0:
			candidates.append(PlacementCandidate.new(cell, cell_world, cell_score, covered_ids))

	# --- 4. Sort and trim ---
	candidates.sort_custom(func(a: PlacementCandidate, b: PlacementCandidate) -> bool:
		return a.score > b.score
	)
	if candidates.size() > MAX_CANDIDATES:
		candidates.resize(MAX_CANDIDATES)

	return candidates

#endregion

#region Internal

## Returns true if every cell in the shelter's horizontal footprint is buildable.
static func _footprint_fits(world_grid: WorldGrid, anchor: Vector2i) -> bool:
	for dx in range(MakeshiftShelter.FOOTPRINT_WIDTH):
		if not world_grid.is_buildable(anchor + Vector2i(dx, 0)):
			return false
	return true

#endregion
