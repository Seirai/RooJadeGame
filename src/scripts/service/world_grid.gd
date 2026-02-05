extends Node
class_name WorldGrid
## Foundational logical grid service for the game world.
##
## Owns all cell data and provides the authoritative spatial API.
## All game systems (territory, buildings, pathfinding) query and write
## through this service rather than maintaining their own grids.
##
## Accessible via GameManager.WorldGridService.

#region Signals

signal cell_changed(cell_pos: Vector2i)
signal building_placed(cell_pos: Vector2i, building: Node)
signal building_removed(cell_pos: Vector2i)

#endregion

#region Constants

## Default cell data template
const CELL_DEFAULTS: Dictionary = {
	"terrain": Enums.TerrainType.GRASS,
	"passable": true,
	"building": null,
	"territory_state": Enums.TileState.UNKNOWN,
	"threat_level": 0,
	"scouted_at": 0.0,
	"claimed_at": 0.0,
	"scouted_by": -1,
}

#endregion

#region State

## Cell data store: Vector2i -> Dictionary
var _cells: Dictionary = {}

## World grid extents
var _bounds: Rect2i = Rect2i()

## Reference to the visual terrain TileMapLayer
var _tilemap_layer: TileMapLayer = null

## World seed used for procedural generation
var _world_seed: int = 0

#endregion

#region Coordinate API

## Convert world-space position to grid cell coordinates
func world_to_cell(world_pos: Vector2) -> Vector2i:
	if _tilemap_layer:
		return _tilemap_layer.local_to_map(world_pos)
	push_warning("WorldGrid: No TileMapLayer set, falling back to integer division")
	return Vector2i(int(world_pos.x), int(world_pos.y))


## Convert grid cell coordinates to world-space position (center of cell)
func cell_to_world(cell_pos: Vector2i) -> Vector2:
	if _tilemap_layer:
		return _tilemap_layer.map_to_local(cell_pos)
	push_warning("WorldGrid: No TileMapLayer set, falling back to direct cast")
	return Vector2(cell_pos)


## Check if a cell position is within the grid bounds
func is_in_bounds(cell_pos: Vector2i) -> bool:
	return _bounds.has_point(cell_pos)


## Get orthogonal neighbor positions for a cell
func get_neighbors(cell_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(0, -1),  # Up
		Vector2i(1, 0),   # Right
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
	]
	for offset in offsets:
		var neighbor = cell_pos + offset
		if is_in_bounds(neighbor):
			neighbors.append(neighbor)
	return neighbors

#endregion

#region Cell API

## Get the full cell data dictionary for a position (or null if not found)
func get_cell(cell_pos: Vector2i) -> Dictionary:
	return _cells.get(cell_pos, {})


## Get terrain type for a cell
func get_terrain(cell_pos: Vector2i) -> Enums.TerrainType:
	var cell = _cells.get(cell_pos, {})
	return cell.get("terrain", Enums.TerrainType.VOID)


## Check if a cell is passable (terrain allows movement)
func is_passable(cell_pos: Vector2i) -> bool:
	var cell = _cells.get(cell_pos, {})
	return cell.get("passable", false)


## Check if a cell can be built on (passable + no building + CLAIMED territory)
func is_buildable(cell_pos: Vector2i) -> bool:
	var cell = _cells.get(cell_pos, {})
	if cell.is_empty():
		return false
	return cell.get("passable", false) \
		and cell.get("building") == null \
		and cell.get("territory_state", Enums.TileState.UNKNOWN) == Enums.TileState.CLAIMED


## Get the building node at a cell (or null)
func get_building(cell_pos: Vector2i) -> Node:
	var cell = _cells.get(cell_pos, {})
	return cell.get("building", null)


## Place a building reference on a cell
func set_building(cell_pos: Vector2i, building: Node) -> void:
	if not _cells.has(cell_pos):
		push_warning("WorldGrid: Cannot set building on non-existent cell ", cell_pos)
		return
	_cells[cell_pos]["building"] = building
	building_placed.emit(cell_pos, building)
	cell_changed.emit(cell_pos)


## Remove a building reference from a cell
func clear_building(cell_pos: Vector2i) -> void:
	if not _cells.has(cell_pos):
		return
	_cells[cell_pos]["building"] = null
	building_removed.emit(cell_pos)
	cell_changed.emit(cell_pos)

#endregion

#region Territory API

## Get the territory state of a cell
func get_territory_state(cell_pos: Vector2i) -> Enums.TileState:
	var cell = _cells.get(cell_pos, {})
	return cell.get("territory_state", Enums.TileState.UNKNOWN)


## Set the territory state of a cell
func set_territory_state(cell_pos: Vector2i, state: Enums.TileState) -> void:
	if not _cells.has(cell_pos):
		return
	_cells[cell_pos]["territory_state"] = state
	cell_changed.emit(cell_pos)


## Get all cell positions that match a given territory state
func get_cells_by_territory(state: Enums.TileState) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in _cells.keys():
		if _cells[pos].get("territory_state") == state:
			result.append(pos)
	return result


## Get frontier cells: UNKNOWN cells adjacent to SCOUTED or CLAIMED cells
func get_frontier_cells() -> Array[Vector2i]:
	var frontier: Array[Vector2i] = []
	var seen: Dictionary = {}

	for pos in _cells.keys():
		var state = _cells[pos].get("territory_state", Enums.TileState.UNKNOWN)
		if state == Enums.TileState.UNKNOWN:
			continue
		# Check neighbors of known cells for UNKNOWN ones
		for neighbor in get_neighbors(pos):
			if seen.has(neighbor):
				continue
			seen[neighbor] = true
			if _cells.has(neighbor) and _cells[neighbor].get("territory_state", Enums.TileState.UNKNOWN) == Enums.TileState.UNKNOWN:
				frontier.append(neighbor)

	return frontier


## Get a cell's threat level
func get_threat_level(cell_pos: Vector2i) -> int:
	var cell = _cells.get(cell_pos, {})
	return cell.get("threat_level", 0)


## Set a cell's threat level
func set_threat_level(cell_pos: Vector2i, level: int) -> void:
	if not _cells.has(cell_pos):
		return
	_cells[cell_pos]["threat_level"] = level
	cell_changed.emit(cell_pos)


## Update scouting metadata on a cell
func set_scouted(cell_pos: Vector2i, scout_id: int) -> void:
	if not _cells.has(cell_pos):
		return
	_cells[cell_pos]["scouted_at"] = Time.get_unix_time_from_system()
	_cells[cell_pos]["scouted_by"] = scout_id
	cell_changed.emit(cell_pos)


## Update claim timestamp on a cell
func set_claimed_at(cell_pos: Vector2i) -> void:
	if not _cells.has(cell_pos):
		return
	_cells[cell_pos]["claimed_at"] = Time.get_unix_time_from_system()
	cell_changed.emit(cell_pos)

#endregion

#region Generation

## Load grid data from an existing TileMapLayer scene
func load_from_tilemap(tilemap_layer: TileMapLayer) -> void:
	_tilemap_layer = tilemap_layer
	_cells.clear()

	var used_cells = tilemap_layer.get_used_cells()
	if used_cells.is_empty():
		push_warning("WorldGrid: TileMapLayer has no used cells")
		return

	# Calculate bounds from used cells
	var min_pos = Vector2i(999999, 999999)
	var max_pos = Vector2i(-999999, -999999)

	for cell_pos in used_cells:
		min_pos.x = mini(min_pos.x, cell_pos.x)
		min_pos.y = mini(min_pos.y, cell_pos.y)
		max_pos.x = maxi(max_pos.x, cell_pos.x)
		max_pos.y = maxi(max_pos.y, cell_pos.y)

		var source_id = tilemap_layer.get_cell_source_id(cell_pos)
		var atlas_coords = tilemap_layer.get_cell_atlas_coords(cell_pos)
		var terrain = _terrain_from_tile(source_id, atlas_coords)

		_cells[cell_pos] = _make_cell(terrain)

	_bounds = Rect2i(min_pos, max_pos - min_pos + Vector2i.ONE)
	print("WorldGrid: Loaded %d cells from TileMapLayer, bounds: %s" % [_cells.size(), _bounds])


## Procedural generation (future)
func generate(bounds: Rect2i, world_seed: int) -> void:
	_world_seed = world_seed
	_bounds = bounds
	_cells.clear()

	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed

	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var pos = Vector2i(x, y)
			_cells[pos] = _generate_cell(pos, rng)

	if _tilemap_layer:
		_sync_tilemap()

	print("WorldGrid: Generated %d cells, bounds: %s, seed: %d" % [_cells.size(), _bounds, world_seed])

#endregion

#region Serialization

func serialize() -> Dictionary:
	var cells: Array = []
	for pos in _cells.keys():
		var cell = _cells[pos]
		cells.append({
			"x": pos.x, "y": pos.y,
			"terrain": cell.get("terrain", Enums.TerrainType.VOID),
			"territory_state": cell.get("territory_state", Enums.TileState.UNKNOWN),
			"threat_level": cell.get("threat_level", 0),
			"scouted_at": cell.get("scouted_at", 0.0),
			"claimed_at": cell.get("claimed_at", 0.0),
		})
	return {
		"bounds": {"x": _bounds.position.x, "y": _bounds.position.y,
				   "w": _bounds.size.x, "h": _bounds.size.y},
		"seed": _world_seed,
		"cells": cells,
	}


func deserialize(data: Dictionary) -> void:
	_cells.clear()
	var b = data.get("bounds", {})
	_bounds = Rect2i(
		b.get("x", 0), b.get("y", 0),
		b.get("w", 0), b.get("h", 0)
	)
	_world_seed = data.get("seed", 0)

	for cell_data in data.get("cells", []):
		var pos = Vector2i(cell_data.get("x", 0), cell_data.get("y", 0))
		var cell = _make_cell(cell_data.get("terrain", Enums.TerrainType.VOID))
		cell["territory_state"] = cell_data.get("territory_state", Enums.TileState.UNKNOWN)
		cell["threat_level"] = cell_data.get("threat_level", 0)
		cell["scouted_at"] = cell_data.get("scouted_at", 0.0)
		cell["claimed_at"] = cell_data.get("claimed_at", 0.0)
		_cells[pos] = cell

	print("WorldGrid: Deserialized %d cells" % _cells.size())

#endregion

#region Queries

## Get the grid bounds
func get_bounds() -> Rect2i:
	return _bounds


## Get total number of cells
func get_cell_count() -> int:
	return _cells.size()


## Check if a cell exists in the grid
func has_cell(cell_pos: Vector2i) -> bool:
	return _cells.has(cell_pos)

#endregion

#region Internal

## Create a cell dictionary from a terrain type
func _make_cell(terrain: Enums.TerrainType) -> Dictionary:
	var cell = CELL_DEFAULTS.duplicate()
	cell["terrain"] = terrain
	cell["passable"] = _is_terrain_passable(terrain)
	return cell


## Determine if a terrain type is passable
func _is_terrain_passable(terrain: Enums.TerrainType) -> bool:
	match terrain:
		Enums.TerrainType.VOID, Enums.TerrainType.WATER:
			return false
		_:
			return true


## Map TileMapLayer source/atlas data to a TerrainType
## Override or extend this for project-specific tile mappings
func _terrain_from_tile(source_id: int, atlas_coords: Vector2i) -> Enums.TerrainType:
	# Default mapping: all tiles are GRASS
	# TODO: Map specific source_id/atlas_coords to terrain types
	# based on the project's tileset configuration
	return Enums.TerrainType.GRASS


## Procedural cell generation (placeholder)
func _generate_cell(pos: Vector2i, rng: RandomNumberGenerator) -> Dictionary:
	# Simple noise-based terrain distribution
	var roll = rng.randf()
	var terrain: Enums.TerrainType
	if roll < 0.55:
		terrain = Enums.TerrainType.GRASS
	elif roll < 0.75:
		terrain = Enums.TerrainType.FOREST
	elif roll < 0.88:
		terrain = Enums.TerrainType.ROCK
	elif roll < 0.96:
		terrain = Enums.TerrainType.WATER
	else:
		terrain = Enums.TerrainType.JADE_VEIN
	return _make_cell(terrain)


## Write generated grid data to TileMapLayer for rendering
func _sync_tilemap() -> void:
	if not _tilemap_layer:
		return
	# TODO: Map TerrainType back to tileset source_id/atlas_coords
	# and call _tilemap_layer.set_cell() for each position
	pass

#endregion
