class_name MakeshiftShelter
extends Node2D
## Makeshift Shelter — lowest-tier residential building.
##
## A cheap, fast-to-build resting spot placed near worksites to reduce commute
## time for Roos that operate far from the settlement core.
##
## Capacity and occupancy are tracked here so BuildingManager.find_available()
## can call has_vacancy() to locate a shelter with a free slot.
##
## Happiness bonuses are stored for future use by the happiness system.

#region Properties

## Number of grid cells this shelter occupies horizontally from its anchor.
const FOOTPRINT_WIDTH: int = 9

## Maximum Roos that can be assigned to this shelter.
@export var capacity: int = 2

## Happiness regeneration bonus per second for assigned Roos (future use).
@export var happiness_bonus: float = 2.0

#endregion

#region State

var _occupants: Array[Node] = []

#endregion

#region Public API

## Returns true if this shelter has at least one free slot.
func has_vacancy() -> bool:
	return _occupants.size() < capacity


## Assign a Roo to this shelter.  Returns false if already full or already assigned.
func assign_roo(roo: Node) -> bool:
	if not has_vacancy() or _occupants.has(roo):
		return false
	_occupants.append(roo)
	return true


## Release a Roo's assignment from this shelter.
func release_roo(roo: Node) -> void:
	_occupants.erase(roo)


## Current number of assigned Roos.
func get_occupant_count() -> int:
	return _occupants.size()


## Returns all grid cells occupied by this shelter given its left-most anchor cell.
static func get_footprint(anchor: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(FOOTPRINT_WIDTH):
		cells.append(anchor + Vector2i(dx, 0))
	return cells

#endregion
