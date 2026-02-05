extends Node
class_name BuildingManager
## Manages building registration, queries, and spatial lookups.
##
## Handles building lifecycle (register/unregister) and spatial queries
## like finding nearest or available buildings.
## Operates on Settlement's _buildings and _buildings_by_type dictionaries.
## Does not own data - receives references via init().

#region Signals

signal building_placed(building: Node, building_type: Enums.BuildingType)
signal building_completed(building: Node, building_type: Enums.BuildingType)
signal building_destroyed(building: Node, building_type: Enums.BuildingType)
signal building_upgraded(building: Node, old_level: int, new_level: int)

#endregion

#region State References

var _buildings: Dictionary
var _buildings_by_type: Dictionary
var _stats: Dictionary
var _next_building_id: int = 0

#endregion

#region Initialization

func init(buildings: Dictionary, buildings_by_type: Dictionary, stats: Dictionary) -> void:
	_buildings = buildings
	_buildings_by_type = buildings_by_type
	_stats = stats
	_ensure_type_registry_initialized()


## Ensure all building types have an entry in the registry
func _ensure_type_registry_initialized() -> void:
	for building_type in Enums.BuildingType.values():
		if not _buildings_by_type.has(building_type):
			_buildings_by_type[building_type] = []

#endregion

#region Public API

## Register a building in the settlement
func register(building: Node, building_type: Enums.BuildingType) -> int:
	var building_id = _next_building_id
	_next_building_id += 1

	_buildings[building_id] = building
	_buildings_by_type[building_type].append(building)

	building.set_meta("settlement_building_id", building_id)
	building.set_meta("building_type", building_type)

	_stats["buildings_constructed"] = _stats.get("buildings_constructed", 0) + 1
	building_placed.emit(building, building_type)

	return building_id


## Remove a building from the settlement
func unregister(building: Node) -> void:
	var building_id = building.get_meta("settlement_building_id", -1)
	var building_type = building.get_meta("building_type", Enums.BuildingType.NONE)

	if building_id < 0:
		return

	_buildings.erase(building_id)
	_buildings_by_type[building_type].erase(building)

	building_destroyed.emit(building, building_type)


## Get all buildings of a type
func get_by_type(building_type: Enums.BuildingType) -> Array:
	return _buildings_by_type.get(building_type, []).duplicate()


## Get count of buildings by type
func get_count(building_type: Enums.BuildingType) -> int:
	return _buildings_by_type.get(building_type, []).size()


## Get total building count
func get_total_count() -> int:
	return _buildings.size()


## Find nearest building of type to a position
func find_nearest(building_type: Enums.BuildingType, position: Vector2) -> Node:
	var buildings = get_by_type(building_type)
	if buildings.is_empty():
		return null

	var nearest: Node = null
	var nearest_dist: float = INF

	for building in buildings:
		if building is Node2D:
			var dist = position.distance_squared_to(building.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = building

	return nearest


## Find building with available vacancy (for workers)
func find_available(building_type: Enums.BuildingType, position: Vector2) -> Node:
	var buildings = get_by_type(building_type)
	var available: Array[Node] = []

	for building in buildings:
		if building.has_method("has_vacancy") and building.has_vacancy():
			available.append(building)

	if available.is_empty():
		return null

	# Find nearest available
	var nearest: Node = null
	var nearest_dist: float = INF

	for building in available:
		if building is Node2D:
			var dist = position.distance_squared_to(building.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = building

	return nearest

#endregion
