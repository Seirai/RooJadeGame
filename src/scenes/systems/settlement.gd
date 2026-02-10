## Settlement System - Facade
##
## Coordinator for all settlement subsystems. Owns all runtime state
## and delegates logic to specialized managers.
##
## Core Responsibilities:
##   - Owns all settlement state (single source of truth)
##   - Initializes and coordinates managers
##   - Provides public API that delegates to managers
##   - Handles serialization/deserialization
##   - Manages territory and progression

extends Node
class_name Settlement

#region Signals

## Territory signals
signal territory_claimed(tile_position: Vector2i)
signal territory_lost(tile_position: Vector2i)
signal threat_detected(position: Vector2, threat_type: String)

## Progression signals
signal progression_stage_changed(old_stage: Enums.ProgressionStage, new_stage: Enums.ProgressionStage)

#endregion

#region State (Settlement owns all data)

## Current progression stage
var progression_stage: Enums.ProgressionStage = Enums.ProgressionStage.FOUNDING

## Resource inventory [ItemsLibrary.Items -> amount]
var _resources: Dictionary = {}

## All Roos in settlement [roo_id -> Roo node]
var _roos: Dictionary = {}

## Viewer Roos (Twitch viewers) [viewer_id -> Roo node]
var _viewer_roos: Dictionary = {}

## AI Roos [ai_id -> Roo node]
var _ai_roos: Dictionary = {}

## AI profession distribution targets [Enums.Professions -> target_percentage (0.0-1.0)]
var _ai_profession_targets: Dictionary = {
	Enums.Professions.SCOUT: 0.1,
	Enums.Professions.LUMBERJACK: 0.3,
	Enums.Professions.MINER: 0.3,
	Enums.Professions.BUILDER: 0.2,
	Enums.Professions.FIGHTER: 0.1,
}

## All buildings [building_id -> Building node]
var _buildings: Dictionary = {}

## Buildings by type [BuildingType -> Array of Building nodes]
var _buildings_by_type: Dictionary = {}

## Claimed territory tiles [Vector2i -> claim_data]
var _claimed_tiles: Dictionary = {}

## Unlocked research technologies
var _unlocked_techs: Array = []

## Research queue
var _research_queue: Array = []

## Settlement statistics
var _stats: Dictionary = {
	"total_wood_collected": 0,
	"total_stone_collected": 0,
	"total_jade_collected": 0,
	"buildings_constructed": 0,
	"territory_tiles_claimed": 0,
	"threats_defeated": 0,
}

#endregion

#region Managers

var _resource_manager: ResourceManager
var _population_manager: PopulationManager
var _profession_manager: ProfessionManager
var _building_manager: BuildingManager
var _research_manager: ResearchManager
var _territory_manager: TerritoryManager

#endregion

#region Lifecycle

func _ready() -> void:
	add_to_group("settlement")
	_create_managers()
	_init_managers()
	print("Settlement system initialized")


func _process(delta: float) -> void:
	_research_manager.process_research(delta)
	_territory_manager.process_claiming(delta)


func _create_managers() -> void:
	_resource_manager = ResourceManager.new()
	_resource_manager.name = "ResourceManager"

	_population_manager = PopulationManager.new()
	_population_manager.name = "PopulationManager"

	_profession_manager = ProfessionManager.new()
	_profession_manager.name = "ProfessionManager"

	_building_manager = BuildingManager.new()
	_building_manager.name = "BuildingManager"

	_research_manager = ResearchManager.new()
	_research_manager.name = "ResearchManager"

	_territory_manager = TerritoryManager.new()
	_territory_manager.name = "TerritoryManager"

	add_child(_resource_manager)
	add_child(_population_manager)
	add_child(_profession_manager)
	add_child(_building_manager)
	add_child(_research_manager)
	add_child(_territory_manager)


func _init_managers() -> void:
	# Init order matters - match dependency order
	_resource_manager.init(_resources, _stats)
	_population_manager.init(_roos, _viewer_roos, _ai_roos)
	_profession_manager.init(_ai_profession_targets, _population_manager)
	_building_manager.init(_buildings, _buildings_by_type, _stats)
	_research_manager.init(_unlocked_techs, _research_queue, _resource_manager)
	_territory_manager.init(_claimed_tiles, _stats)
	_territory_manager.tile_claimed.connect(_on_tile_claimed)
	_territory_manager.tile_scouted.connect(_on_tile_scouted)

#endregion

#region Resource API (delegates to ResourceManager)

func get_resource(resource_id: int) -> int:
	return _resource_manager.get_resource(resource_id)

func get_all_resources() -> Dictionary:
	return _resource_manager.get_all_resources()

func deposit_resource(resource_id: int, amount: int, depositor: Node = null) -> void:
	_resource_manager.deposit(resource_id, amount, depositor)

func withdraw_resource(resource_id: int, amount: int) -> int:
	return _resource_manager.withdraw(resource_id, amount)

func has_resource(resource_id: int, amount: int) -> bool:
	return _resource_manager.has_resource(resource_id, amount)

func can_afford(cost: Dictionary) -> bool:
	return _resource_manager.can_afford(cost)

func spend_resources(cost: Dictionary) -> bool:
	return _resource_manager.spend(cost)

#endregion

#region Population API (delegates to PopulationManager)

func get_population() -> int:
	return _population_manager.get_population()

func get_viewer_count() -> int:
	return _population_manager.get_viewer_count()

func get_ai_count() -> int:
	return _population_manager.get_ai_count()

func register_roo(roo: Node, is_viewer: bool, viewer_id: String = "") -> int:
	return _population_manager.register_roo(roo, is_viewer, viewer_id)

func unregister_roo(roo: Node) -> void:
	_population_manager.unregister_roo(roo)

func get_viewer_roo(viewer_id: String) -> Node:
	return _population_manager.get_viewer_roo(viewer_id)

func get_roos_by_profession(profession: Enums.Professions) -> Array[Node]:
	return _population_manager.get_roos_by_profession(profession)

func set_roo_profession(roo: Node, new_profession: Enums.Professions) -> void:
	_population_manager.set_roo_profession(roo, new_profession)

#endregion

#region Profession API (delegates to ProfessionManager)

func get_ai_profession_targets() -> Dictionary:
	return _profession_manager.get_targets()

func set_ai_profession_target(profession: Enums.Professions, percentage: float) -> void:
	_profession_manager.set_target(profession, percentage)

func get_ai_profession_actual() -> Dictionary:
	return _profession_manager.get_distribution()

func rebalance_ai_professions() -> void:
	_profession_manager.rebalance_ai()

#endregion

#region Building API (delegates to BuildingManager)

func register_building(building: Node, building_type: Enums.BuildingType) -> int:
	return _building_manager.register(building, building_type)

func unregister_building(building: Node) -> void:
	_building_manager.unregister(building)

func get_buildings_by_type(building_type: Enums.BuildingType) -> Array:
	return _building_manager.get_by_type(building_type)

func get_building_count(building_type: Enums.BuildingType) -> int:
	return _building_manager.get_count(building_type)

func get_total_building_count() -> int:
	return _building_manager.get_total_count()

func find_nearest_building(building_type: Enums.BuildingType, position: Vector2) -> Node:
	return _building_manager.find_nearest(building_type, position)

func find_available_building(building_type: Enums.BuildingType, position: Vector2) -> Node:
	return _building_manager.find_available(building_type, position)

#endregion

#region Research API (delegates to ResearchManager)

func is_tech_unlocked(tech_id: Enums.ResearchTech) -> bool:
	return _research_manager.is_unlocked(tech_id)

func can_research(tech_id: Enums.ResearchTech) -> bool:
	return _research_manager.can_research(tech_id)

func start_research(tech_id: Enums.ResearchTech) -> bool:
	return _research_manager.start_research(tech_id)

func get_available_research() -> Array[Enums.ResearchTech]:
	return _research_manager.get_available()

func get_research_progress() -> float:
	return _research_manager.get_progress()

#endregion

#region Territory API (delegates to TerritoryManager)

## Scout a tile (transition UNKNOWN -> SCOUTED)
func scout_tile(tile_position: Vector2i, scout_roo_id: int = -1) -> void:
	_territory_manager.scout_tile(tile_position, scout_roo_id)


## Attempt to claim a tile (checks adjacency, threat, delay rules)
func try_claim_tile(tile_position: Vector2i) -> bool:
	return _territory_manager.try_claim_tile(tile_position)


## Get the territory state of a tile
func get_tile_state(tile_position: Vector2i) -> Enums.TileState:
	return _territory_manager.get_tile_state(tile_position)


## Check if a tile is claimed
func is_tile_claimed(tile_position: Vector2i) -> bool:
	return _claimed_tiles.has(tile_position)


## Get all claimed tile positions
func get_claimed_tiles() -> Array[Vector2i]:
	return _territory_manager.get_claimed_tiles()


## Get frontier tiles for scout AI
func get_frontier_tiles() -> Array[Vector2i]:
	return _territory_manager.get_frontier_tiles()


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


## Report a threat at a cell position
func report_threat_at_cell(cell_pos: Vector2i, threat_level: int) -> void:
	_territory_manager.set_threat(cell_pos, threat_level)


## Report a threat detected by scouts (world-space)
func report_threat(position: Vector2, threat_type: String) -> void:
	threat_detected.emit(position, threat_type)

#endregion

#region Progression

## Get current progression stage
func get_progression_stage() -> Enums.ProgressionStage:
	return progression_stage


## Advance to next progression stage
func advance_progression() -> void:
	var old_stage = progression_stage
	var new_stage = mini(progression_stage + 1, Enums.ProgressionStage.ADVANCED) as Enums.ProgressionStage

	if new_stage != old_stage:
		progression_stage = new_stage
		progression_stage_changed.emit(old_stage, new_stage)


## Check progression requirements and advance if met
func check_progression() -> void:
	match progression_stage:
		Enums.ProgressionStage.FOUNDING:
			if get_building_count(Enums.BuildingType.LIVING_QUARTERS) >= 1 and get_building_count(Enums.BuildingType.DEPOT) >= 1:
				advance_progression()

		Enums.ProgressionStage.ESTABLISHED:
			if get_building_count(Enums.BuildingType.LUMBER_MILL) >= 1 and get_building_count(Enums.BuildingType.STONE_QUARRY) >= 1:
				advance_progression()

		Enums.ProgressionStage.GROWING:
			if get_population() >= 10 and _stats["territory_tiles_claimed"] >= 20:
				advance_progression()

		Enums.ProgressionStage.THRIVING:
			if get_building_count(Enums.BuildingType.RESEARCH_FACILITY) >= 1 and _stats["total_jade_collected"] >= 100:
				advance_progression()

#endregion

#region Territory Callbacks

func _on_tile_claimed(cell_pos: Vector2i) -> void:
	territory_claimed.emit(cell_pos)


func _on_tile_scouted(_cell_pos: Vector2i) -> void:
	pass  # Hook for future UI/audio feedback

#endregion

#region Statistics

func get_stats() -> Dictionary:
	return _stats.duplicate()

func get_stat(stat_name: String) -> int:
	return _stats.get(stat_name, 0)

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
		"unlocked_techs": _unlocked_techs.duplicate(),
		"research_queue": _research_queue.duplicate(),
	}


## Load settlement state from dictionary
func load_state(state: Dictionary) -> void:
	progression_stage = state.get("progression_stage", Enums.ProgressionStage.FOUNDING)
	_resources = state.get("resources", {}).duplicate()
	_stats = state.get("stats", {}).duplicate()
	_ai_profession_targets = state.get("ai_profession_targets", {}).duplicate()
	_unlocked_techs = state.get("unlocked_techs", []).duplicate()
	_research_queue = state.get("research_queue", []).duplicate()
	_deserialize_tiles(state.get("claimed_tiles", []))

	# Re-init managers with loaded data
	_init_managers()


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
		_claimed_tiles[pos] = {
			"claimed_at": tile.get("claimed_at", 0.0),
		}

#endregion
