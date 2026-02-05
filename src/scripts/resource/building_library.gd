extends Node
class_name BuildingLibrary
## Central registry for all building definitions.
##
## Following the ItemsLibrary pattern, this provides a static
## registry of all building definitions in the game.
##
## Usage:
##   var depot = BuildingLibrary.get_building(Enums.BuildingType.DEPOT)
##   var cost = BuildingLibrary.get_construction_cost(Enums.BuildingType.LUMBER_MILL)

const BuildingDef = preload("res://src/scripts/resource/building_definition.gd")

## Dictionary of all registered buildings [Enums.BuildingType -> BuildingDefinition]
static var _buildings: Dictionary = {}

## Flag to prevent double initialization
static var _initialized: bool = false

## Initialize all building definitions
static func _static_init() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all_buildings()

static func _register_all_buildings() -> void:
	register_building(_create_living_quarters())
	register_building(_create_lumber_mill())
	register_building(_create_stone_quarry())
	register_building(_create_jade_quarry())
	register_building(_create_depot())
	register_building(_create_research_facility())
	register_building(_create_workshop())

	print("BuildingLibrary: Registered %d buildings" % _buildings.size())


#region Registration & Lookup

## Register a building definition
static func register_building(building: BuildingDef) -> void:
	if building:
		_buildings[building.building_type] = building


## Get a building definition by type
static func get_building(building_type: Enums.BuildingType) -> BuildingDef:
	_ensure_initialized()
	return _buildings.get(building_type, null)


## Check if a building type is registered
static func has_building(building_type: Enums.BuildingType) -> bool:
	_ensure_initialized()
	return _buildings.has(building_type)


## Get construction cost for a building type
static func get_construction_cost(building_type: Enums.BuildingType) -> Dictionary:
	_ensure_initialized()
	var building = _buildings.get(building_type, null)
	if building:
		return building.construction_cost.duplicate()
	return {}


## Get all registered building definitions
static func get_all_buildings() -> Array[BuildingDef]:
	_ensure_initialized()
	var result: Array[BuildingDef] = []
	for building in _buildings.values():
		result.append(building)
	return result


## Get buildings available at a given progression stage
static func get_buildings_by_stage(stage: Enums.ProgressionStage) -> Array[BuildingDef]:
	_ensure_initialized()
	var result: Array[BuildingDef] = []
	for building in _buildings.values():
		if building.required_stage <= stage:
			result.append(building)
	return result


## Ensure the library is initialized before access
static func _ensure_initialized() -> void:
	if not _initialized:
		_static_init()

#endregion


# ============================================================================
# Building Definitions
# ============================================================================

static func _create_living_quarters() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.LIVING_QUARTERS
	b.display_name = "Living Quarters"
	b.description = "Housing for Roos. Increases population capacity."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 20,
		ItemsLibrary.Items.STONE: 10,
	}
	b.max_count = 0
	b.required_stage = Enums.ProgressionStage.FOUNDING
	b.worker_capacity = 0
	return b


static func _create_lumber_mill() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.LUMBER_MILL
	b.display_name = "Lumber Mill"
	b.description = "Processes wood. Assign Lumberjacks to harvest."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 30,
		ItemsLibrary.Items.STONE: 15,
	}
	b.max_count = 0
	b.required_stage = Enums.ProgressionStage.FOUNDING
	b.worker_capacity = 3
	return b


static func _create_stone_quarry() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.STONE_QUARRY
	b.display_name = "Stone Quarry"
	b.description = "Extracts stone from the earth. Assign Miners to work."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 25,
		ItemsLibrary.Items.STONE: 5,
	}
	b.max_count = 0
	b.required_stage = Enums.ProgressionStage.FOUNDING
	b.worker_capacity = 3
	return b


static func _create_jade_quarry() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.JADE_QUARRY
	b.display_name = "Jade Quarry"
	b.description = "Premium quarry for extracting jade from meteorite deposits."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 50,
		ItemsLibrary.Items.STONE: 50,
	}
	b.max_count = 0
	b.required_stage = Enums.ProgressionStage.GROWING
	b.worker_capacity = 2
	return b


static func _create_depot() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.DEPOT
	b.display_name = "Depot"
	b.description = "Central resource storage for the settlement."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 40,
		ItemsLibrary.Items.STONE: 20,
	}
	b.max_count = 0
	b.required_stage = Enums.ProgressionStage.FOUNDING
	b.worker_capacity = 0
	return b


static func _create_research_facility() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.RESEARCH_FACILITY
	b.display_name = "Research Facility"
	b.description = "Unlocks the Scientist profession and tech research."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 60,
		ItemsLibrary.Items.STONE: 40,
		ItemsLibrary.Items.JADE: 20,
	}
	b.max_count = 1
	b.required_stage = Enums.ProgressionStage.ESTABLISHED
	b.worker_capacity = 2
	return b


static func _create_workshop() -> BuildingDef:
	var b = BuildingDef.new()
	b.building_type = Enums.BuildingType.WORKSHOP
	b.display_name = "Workshop"
	b.description = "Crafting station for equipment and tools."
	b.construction_cost = {
		ItemsLibrary.Items.WOOD: 35,
		ItemsLibrary.Items.STONE: 25,
	}
	b.max_count = 0
	b.required_stage = Enums.ProgressionStage.ESTABLISHED
	b.worker_capacity = 2
	return b
