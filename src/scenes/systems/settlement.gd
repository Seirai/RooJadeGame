## Settlement System
##
## Handles tracking of the entire settlement's state, stats, inventory.
## Keeps track of number of inhabitants (Roos), resources, buildings, etc.
## Manages AI Roo profession distribution and territory claims.
##
## Core Responsibilities:
##   - Resource inventory (Wood, Stone, Jade)
##   - Roo population tracking (viewer Roos + AI Roos)
##   - AI Roo profession distribution management
##   - Building/structure registry
##   - Territory/tile management
##   - Settlement progression state

extends Node
class_name Settlement

#region Enums

## Professions available to Roos
enum Profession {
	NONE,       ## Unassigned
	SCOUT,      ## Explores frontier, claims territory, detects threats
	LUMBERJACK, ## Harvests wood from lumber mills
	MINER,      ## Extracts stone and jade from quarries
	BUILDER,    ## Constructs settlement infrastructure
	FIGHTER,    ## Combat unit for hostile encounters
}

## Building types in the settlement
enum BuildingType {
	NONE,
	LIVING_QUARTERS,  ## Housing for Roos
	LUMBER_MILL,      ## Wood production
	STONE_QUARRY,     ## Stone production
	JADE_QUARRY,      ## Jade production (premium)
	DEPOT,            ## Resource storage
	RESEARCH_FACILITY,## Unlocks Scientist profession and tech
	WORKSHOP,         ## Equipment crafting
}

## Settlement progression stages
enum ProgressionStage {
	FOUNDING,     ## Initial stage, minimal buildings
	ESTABLISHED,  ## Basic infrastructure complete
	GROWING,      ## Expanding territory
	THRIVING,     ## Advanced buildings and research
	ADVANCED,     ## Near jade asteroid
}

#endregion

#region Signals

## Resource signals
signal resource_changed(resource_id: int, old_amount: int, new_amount: int)
signal resource_deposited(resource_id: int, amount: int, depositor: Node)
signal resource_withdrawn(resource_id: int, amount: int)

## Roo signals
signal roo_joined(roo: Node, is_viewer: bool)
signal roo_left(roo: Node)
signal roo_profession_changed(roo: Node, old_profession: Profession, new_profession: Profession)
signal ai_profession_distribution_changed()

## Building signals
signal building_placed(building: Node, building_type: BuildingType)
signal building_completed(building: Node, building_type: BuildingType)
signal building_destroyed(building: Node, building_type: BuildingType)
signal building_upgraded(building: Node, old_level: int, new_level: int)

## Territory signals
signal territory_claimed(tile_position: Vector2i)
signal territory_lost(tile_position: Vector2i)
signal threat_detected(position: Vector2, threat_type: String)

## Progression signals
signal progression_stage_changed(old_stage: ProgressionStage, new_stage: ProgressionStage)

#endregion

#region Properties

## Current progression stage
var progression_stage: ProgressionStage = ProgressionStage.FOUNDING

## Resource inventory [ItemsLibrary.Items -> amount]
var _resources: Dictionary = {}

## All Roos in settlement [roo_id -> Roo node]
var _roos: Dictionary = {}

## Viewer Roos (Twitch viewers) [viewer_id -> Roo node]
var _viewer_roos: Dictionary = {}

## AI Roos [ai_id -> Roo node]
var _ai_roos: Dictionary = {}

## AI profession distribution targets [Profession -> target_percentage (0.0-1.0)]
## This is what the streamer/player configures
var _ai_profession_targets: Dictionary = {
	Profession.SCOUT: 0.1,
	Profession.LUMBERJACK: 0.3,
	Profession.MINER: 0.3,
	Profession.BUILDER: 0.2,
	Profession.FIGHTER: 0.1,
}

## All buildings [building_id -> Building node]
var _buildings: Dictionary = {}

## Buildings by type [BuildingType -> Array of Building nodes]
var _buildings_by_type: Dictionary = {}

## Claimed territory tiles (settlement area)
var _claimed_tiles: Dictionary = {}  # Vector2i -> claim_data

## Settlement statistics
var _stats: Dictionary = {
	"total_wood_collected": 0,
	"total_stone_collected": 0,
	"total_jade_collected": 0,
	"buildings_constructed": 0,
	"territory_tiles_claimed": 0,
	"threats_defeated": 0,
}

## Next unique ID for Roos
var _next_roo_id: int = 0

## Next unique ID for buildings
var _next_building_id: int = 0

#endregion

#region Lifecycle

func _ready() -> void:
	_initialize_resources()
	_initialize_building_registry()
	print("Settlement system initialized")


## Initialize resource inventory with zero amounts
func _initialize_resources() -> void:
	_resources[ItemsLibrary.Items.WOOD] = 0
	_resources[ItemsLibrary.Items.STONE] = 0
	_resources[ItemsLibrary.Items.JADE] = 0


## Initialize building type registry
func _initialize_building_registry() -> void:
	for building_type in BuildingType.values():
		_buildings_by_type[building_type] = []

#endregion

#region Resource Management

## Get current amount of a resource
func get_resource(resource_id: int) -> int:
	return _resources.get(resource_id, 0)


## Get all resources as dictionary
func get_all_resources() -> Dictionary:
	return _resources.duplicate()


## Add resources to settlement inventory
func deposit_resource(resource_id: int, amount: int, depositor: Node = null) -> void:
	if amount <= 0:
		return

	var old_amount = _resources.get(resource_id, 0)
	var new_amount = old_amount + amount
	_resources[resource_id] = new_amount

	# Track statistics
	match resource_id:
		ItemsLibrary.Items.WOOD:
			_stats["total_wood_collected"] += amount
		ItemsLibrary.Items.STONE:
			_stats["total_stone_collected"] += amount
		ItemsLibrary.Items.JADE:
			_stats["total_jade_collected"] += amount

	resource_changed.emit(resource_id, old_amount, new_amount)
	resource_deposited.emit(resource_id, amount, depositor)


## Remove resources from settlement inventory
## Returns actual amount withdrawn (may be less if insufficient)
func withdraw_resource(resource_id: int, amount: int) -> int:
	if amount <= 0:
		return 0

	var old_amount = _resources.get(resource_id, 0)
	var actual_withdraw = mini(amount, old_amount)

	if actual_withdraw > 0:
		var new_amount = old_amount - actual_withdraw
		_resources[resource_id] = new_amount
		resource_changed.emit(resource_id, old_amount, new_amount)
		resource_withdrawn.emit(resource_id, actual_withdraw)

	return actual_withdraw


## Check if settlement has enough of a resource
func has_resource(resource_id: int, amount: int) -> bool:
	return get_resource(resource_id) >= amount


## Check if settlement can afford a cost (dictionary of resource_id -> amount)
func can_afford(cost: Dictionary) -> bool:
	for resource_id in cost.keys():
		if not has_resource(resource_id, cost[resource_id]):
			return false
	return true


## Spend resources (returns true if successful)
func spend_resources(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false

	for resource_id in cost.keys():
		withdraw_resource(resource_id, cost[resource_id])
	return true

#endregion

#region Roo Management

## Get total Roo population
func get_population() -> int:
	return _roos.size()


## Get viewer Roo count
func get_viewer_count() -> int:
	return _viewer_roos.size()


## Get AI Roo count
func get_ai_count() -> int:
	return _ai_roos.size()


## Register a new Roo in the settlement
func register_roo(roo: Node, is_viewer: bool, viewer_id: String = "") -> int:
	var roo_id = _next_roo_id
	_next_roo_id += 1

	_roos[roo_id] = roo

	if is_viewer and viewer_id != "":
		_viewer_roos[viewer_id] = roo
	else:
		_ai_roos[roo_id] = roo

	roo.set_meta("settlement_roo_id", roo_id)
	roo.set_meta("is_viewer_roo", is_viewer)

	roo_joined.emit(roo, is_viewer)
	return roo_id


## Remove a Roo from the settlement
func unregister_roo(roo: Node) -> void:
	var roo_id = roo.get_meta("settlement_roo_id", -1)
	if roo_id < 0:
		return

	_roos.erase(roo_id)

	if roo.get_meta("is_viewer_roo", false):
		for viewer_id in _viewer_roos.keys():
			if _viewer_roos[viewer_id] == roo:
				_viewer_roos.erase(viewer_id)
				break
	else:
		_ai_roos.erase(roo_id)

	roo_left.emit(roo)


## Get a Roo by viewer ID
func get_viewer_roo(viewer_id: String) -> Node:
	return _viewer_roos.get(viewer_id, null)


## Get all Roos with a specific profession
func get_roos_by_profession(profession: Profession) -> Array[Node]:
	var result: Array[Node] = []
	for roo in _roos.values():
		if roo.has_method("get_profession") and roo.get_profession() == profession:
			result.append(roo)
	return result


## Change a Roo's profession
func set_roo_profession(roo: Node, new_profession: Profession) -> void:
	if not roo.has_method("get_profession") or not roo.has_method("set_profession"):
		push_warning("Settlement: Roo does not support profession methods")
		return

	var old_profession = roo.get_profession()
	if old_profession == new_profession:
		return

	roo.set_profession(new_profession)
	roo_profession_changed.emit(roo, old_profession, new_profession)

#endregion

#region AI Profession Distribution

## Get the target profession distribution for AI Roos
func get_ai_profession_targets() -> Dictionary:
	return _ai_profession_targets.duplicate()


## Set target percentage for a profession (0.0-1.0)
## This is used by streamer/player to manage AI Roo distribution
func set_ai_profession_target(profession: Profession, percentage: float) -> void:
	percentage = clampf(percentage, 0.0, 1.0)
	_ai_profession_targets[profession] = percentage
	_normalize_profession_targets()
	ai_profession_distribution_changed.emit()


## Get current actual distribution of AI Roo professions
func get_ai_profession_actual() -> Dictionary:
	var distribution: Dictionary = {}
	for profession in Profession.values():
		distribution[profession] = 0

	var total_ai = _ai_roos.size()
	if total_ai == 0:
		return distribution

	for roo in _ai_roos.values():
		if roo.has_method("get_profession"):
			var prof = roo.get_profession()
			distribution[prof] = distribution.get(prof, 0) + 1

	# Convert to percentages
	for profession in distribution.keys():
		distribution[profession] = float(distribution[profession]) / float(total_ai)

	return distribution


## Normalize profession targets to sum to 1.0
func _normalize_profession_targets() -> void:
	var total = 0.0
	for percentage in _ai_profession_targets.values():
		total += percentage

	if total > 0.0 and total != 1.0:
		for profession in _ai_profession_targets.keys():
			_ai_profession_targets[profession] /= total


## Rebalance AI Roos to match target distribution
## Called periodically or when targets change
func rebalance_ai_professions() -> void:
	var total_ai = _ai_roos.size()
	if total_ai == 0:
		return

	# Calculate target counts for each profession
	var target_counts: Dictionary = {}
	for profession in _ai_profession_targets.keys():
		target_counts[profession] = roundi(_ai_profession_targets[profession] * total_ai)

	# Get current counts
	var current_counts: Dictionary = {}
	for profession in Profession.values():
		current_counts[profession] = 0

	for roo in _ai_roos.values():
		if roo.has_method("get_profession"):
			var prof = roo.get_profession()
			current_counts[prof] = current_counts.get(prof, 0) + 1

	# Find Roos that need reassignment (excess in current profession)
	var roos_to_reassign: Array[Node] = []
	for roo in _ai_roos.values():
		if roo.has_method("get_profession"):
			var prof = roo.get_profession()
			var target = target_counts.get(prof, 0)
			var current = current_counts.get(prof, 0)

			if current > target:
				roos_to_reassign.append(roo)
				current_counts[prof] -= 1

	# Assign to professions that need more
	for roo in roos_to_reassign:
		var best_profession = Profession.NONE
		var best_deficit = 0

		for profession in target_counts.keys():
			var deficit = target_counts[profession] - current_counts.get(profession, 0)
			if deficit > best_deficit:
				best_deficit = deficit
				best_profession = profession

		if best_profession != Profession.NONE:
			set_roo_profession(roo, best_profession)
			current_counts[best_profession] = current_counts.get(best_profession, 0) + 1

#endregion

#region Building Management

## Register a building in the settlement
func register_building(building: Node, building_type: BuildingType) -> int:
	var building_id = _next_building_id
	_next_building_id += 1

	_buildings[building_id] = building
	_buildings_by_type[building_type].append(building)

	building.set_meta("settlement_building_id", building_id)
	building.set_meta("building_type", building_type)

	building_placed.emit(building, building_type)
	_stats["buildings_constructed"] += 1

	return building_id


## Remove a building from the settlement
func unregister_building(building: Node) -> void:
	var building_id = building.get_meta("settlement_building_id", -1)
	var building_type = building.get_meta("building_type", BuildingType.NONE)

	if building_id < 0:
		return

	_buildings.erase(building_id)
	_buildings_by_type[building_type].erase(building)

	building_destroyed.emit(building, building_type)


## Get all buildings of a type
func get_buildings_by_type(building_type: BuildingType) -> Array:
	return _buildings_by_type.get(building_type, []).duplicate()


## Get count of buildings by type
func get_building_count(building_type: BuildingType) -> int:
	return _buildings_by_type.get(building_type, []).size()


## Get total building count
func get_total_building_count() -> int:
	return _buildings.size()


## Find nearest building of type to a position
func find_nearest_building(building_type: BuildingType, position: Vector2) -> Node:
	var buildings = get_buildings_by_type(building_type)
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
func find_available_building(building_type: BuildingType, position: Vector2) -> Node:
	var buildings = get_buildings_by_type(building_type)
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

#region Territory Management

## Claim a tile as part of the settlement
func claim_tile(tile_position: Vector2i) -> void:
	if _claimed_tiles.has(tile_position):
		return

	_claimed_tiles[tile_position] = {
		"claimed_at": Time.get_unix_time_from_system(),
		"claimed_by": null,  # Roo reference if applicable
	}

	_stats["territory_tiles_claimed"] += 1
	territory_claimed.emit(tile_position)


## Check if a tile is claimed
func is_tile_claimed(tile_position: Vector2i) -> bool:
	return _claimed_tiles.has(tile_position)


## Get all claimed tile positions
func get_claimed_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for pos in _claimed_tiles.keys():
		tiles.append(pos)
	return tiles


## Get settlement territory bounds
func get_territory_bounds() -> Rect2i:
	if _claimed_tiles.is_empty():
		return Rect2i()

	var min_pos = Vector2i(999999, 999999)
	var max_pos = Vector2i(-999999, -999999)

	for pos in _claimed_tiles.keys():
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
		max_pos.x = maxi(max_pos.x, pos.x)
		max_pos.y = maxi(max_pos.y, pos.y)

	return Rect2i(min_pos, max_pos - min_pos + Vector2i.ONE)


## Report a threat detected by scouts
func report_threat(position: Vector2, threat_type: String) -> void:
	threat_detected.emit(position, threat_type)

#endregion

#region Progression

## Get current progression stage
func get_progression_stage() -> ProgressionStage:
	return progression_stage


## Advance to next progression stage
func advance_progression() -> void:
	var old_stage = progression_stage
	var new_stage = mini(progression_stage + 1, ProgressionStage.ADVANCED) as ProgressionStage

	if new_stage != old_stage:
		progression_stage = new_stage
		progression_stage_changed.emit(old_stage, new_stage)


## Check progression requirements and advance if met
func check_progression() -> void:
	match progression_stage:
		ProgressionStage.FOUNDING:
			# Advance when basic buildings exist
			if get_building_count(BuildingType.LIVING_QUARTERS) >= 1 and get_building_count(BuildingType.DEPOT) >= 1:
				advance_progression()

		ProgressionStage.ESTABLISHED:
			# Advance when production buildings exist
			if get_building_count(BuildingType.LUMBER_MILL) >= 1 and get_building_count(BuildingType.STONE_QUARRY) >= 1:
				advance_progression()

		ProgressionStage.GROWING:
			# Advance when territory and population grow
			if get_population() >= 10 and _stats["territory_tiles_claimed"] >= 20:
				advance_progression()

		ProgressionStage.THRIVING:
			# Advance when research facility exists and jade collected
			if get_building_count(BuildingType.RESEARCH_FACILITY) >= 1 and _stats["total_jade_collected"] >= 100:
				advance_progression()

#endregion

#region Statistics

## Get settlement statistics
func get_stats() -> Dictionary:
	return _stats.duplicate()


## Get a specific statistic
func get_stat(stat_name: String) -> int:
	return _stats.get(stat_name, 0)


## Increment a statistic
func increment_stat(stat_name: String, amount: int = 1) -> void:
	_stats[stat_name] = _stats.get(stat_name, 0) + amount

#endregion

#region Serialization

## Save settlement state to dictionary
func save_state() -> Dictionary:
	return {
		"progression_stage": progression_stage,
		"resources": _resources.duplicate(),
		"stats": _stats.duplicate(),
		"ai_profession_targets": _ai_profession_targets.duplicate(),
		"claimed_tiles": _serialize_tiles(),
	}


## Load settlement state from dictionary
func load_state(state: Dictionary) -> void:
	progression_stage = state.get("progression_stage", ProgressionStage.FOUNDING)
	_resources = state.get("resources", {}).duplicate()
	_stats = state.get("stats", {}).duplicate()
	_ai_profession_targets = state.get("ai_profession_targets", {}).duplicate()
	_deserialize_tiles(state.get("claimed_tiles", []))

	# Ensure all resources are initialized
	_initialize_resources()


## Serialize tiles to array format
func _serialize_tiles() -> Array:
	var tiles: Array = []
	for pos in _claimed_tiles.keys():
		tiles.append({"x": pos.x, "y": pos.y})
	return tiles


## Deserialize tiles from array format
func _deserialize_tiles(tiles: Array) -> void:
	_claimed_tiles.clear()
	for tile in tiles:
		var pos = Vector2i(tile.get("x", 0), tile.get("y", 0))
		claim_tile(pos)

#endregion

