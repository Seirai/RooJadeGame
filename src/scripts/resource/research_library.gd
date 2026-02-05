extends Node
class_name ResearchLibrary
## Central registry for all research/tech definitions.
##
## Following the ItemsLibrary pattern, this provides a static
## registry of all research definitions in the game.
##
## Usage:
##   var tech = ResearchLibrary.get_tech(Enums.ResearchTech.JADE_REFINING)
##   var cost = ResearchLibrary.get_research_cost(Enums.ResearchTech.FORTIFICATIONS)
##   var prereqs = ResearchLibrary.get_prerequisites(Enums.ResearchTech.ADVANCED_MEDICINE)

const ResearchDef = preload("res://src/scripts/resource/research_definition.gd")

## Dictionary of all registered techs [Enums.ResearchTech -> ResearchDefinition]
static var _techs: Dictionary = {}

## Flag to prevent double initialization
static var _initialized: bool = false

## Initialize all tech definitions
static func _static_init() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all_techs()

static func _register_all_techs() -> void:
	register_tech(_create_advanced_tools())
	register_tech(_create_jade_refining())
	register_tech(_create_fortifications())
	register_tech(_create_advanced_medicine())
	register_tech(_create_exploration_gear())

	print("ResearchLibrary: Registered %d techs" % _techs.size())


#region Registration & Lookup

## Register a tech definition
static func register_tech(tech: ResearchDef) -> void:
	if tech:
		_techs[tech.tech_id] = tech


## Get a tech definition by ID
static func get_tech(tech_id: Enums.ResearchTech) -> ResearchDef:
	_ensure_initialized()
	return _techs.get(tech_id, null)


## Check if a tech is registered
static func has_tech(tech_id: Enums.ResearchTech) -> bool:
	_ensure_initialized()
	return _techs.has(tech_id)


## Get research cost for a tech
static func get_research_cost(tech_id: Enums.ResearchTech) -> Dictionary:
	_ensure_initialized()
	var tech = _techs.get(tech_id, null)
	if tech:
		return tech.research_cost.duplicate()
	return {}


## Get prerequisites for a tech
static func get_prerequisites(tech_id: Enums.ResearchTech) -> Array[Enums.ResearchTech]:
	_ensure_initialized()
	var tech = _techs.get(tech_id, null)
	if tech:
		return tech.prerequisites.duplicate()
	return []


## Get all registered tech definitions
static func get_all_techs() -> Array[ResearchDef]:
	_ensure_initialized()
	var result: Array[ResearchDef] = []
	for tech in _techs.values():
		result.append(tech)
	return result


## Get techs available at a given progression stage
static func get_techs_by_stage(stage: Enums.ProgressionStage) -> Array[ResearchDef]:
	_ensure_initialized()
	var result: Array[ResearchDef] = []
	for tech in _techs.values():
		if tech.required_stage <= stage:
			result.append(tech)
	return result


## Ensure the library is initialized before access
static func _ensure_initialized() -> void:
	if not _initialized:
		_static_init()

#endregion


# ============================================================================
# Tech Definitions
# ============================================================================

static func _create_advanced_tools() -> ResearchDef:
	var t = ResearchDef.new()
	t.tech_id = Enums.ResearchTech.ADVANCED_TOOLS
	t.display_name = "Advanced Tools"
	t.description = "Improves worker efficiency across all professions."
	t.research_cost = {
		ItemsLibrary.Items.WOOD: 30,
		ItemsLibrary.Items.STONE: 30,
		ItemsLibrary.Items.JADE: 10,
	}
	t.required_stage = Enums.ProgressionStage.ESTABLISHED
	t.prerequisites = []
	t.duration = 60.0
	return t


static func _create_jade_refining() -> ResearchDef:
	var t = ResearchDef.new()
	t.tech_id = Enums.ResearchTech.JADE_REFINING
	t.display_name = "Jade Refining"
	t.description = "Increases jade extraction rate from quarries."
	t.research_cost = {
		ItemsLibrary.Items.STONE: 50,
		ItemsLibrary.Items.JADE: 25,
	}
	t.required_stage = Enums.ProgressionStage.GROWING
	t.prerequisites = [Enums.ResearchTech.ADVANCED_TOOLS]
	t.duration = 90.0
	return t


static func _create_fortifications() -> ResearchDef:
	var t = ResearchDef.new()
	t.tech_id = Enums.ResearchTech.FORTIFICATIONS
	t.display_name = "Fortifications"
	t.description = "Strengthens settlement defenses against threats."
	t.research_cost = {
		ItemsLibrary.Items.WOOD: 40,
		ItemsLibrary.Items.STONE: 60,
		ItemsLibrary.Items.JADE: 15,
	}
	t.required_stage = Enums.ProgressionStage.ESTABLISHED
	t.prerequisites = []
	t.duration = 75.0
	return t


static func _create_advanced_medicine() -> ResearchDef:
	var t = ResearchDef.new()
	t.tech_id = Enums.ResearchTech.ADVANCED_MEDICINE
	t.display_name = "Advanced Medicine"
	t.description = "Unlocks recovery mechanics for downed Roos."
	t.research_cost = {
		ItemsLibrary.Items.WOOD: 20,
		ItemsLibrary.Items.JADE: 30,
	}
	t.required_stage = Enums.ProgressionStage.GROWING
	t.prerequisites = [Enums.ResearchTech.ADVANCED_TOOLS]
	t.duration = 120.0
	return t


static func _create_exploration_gear() -> ResearchDef:
	var t = ResearchDef.new()
	t.tech_id = Enums.ResearchTech.EXPLORATION_GEAR
	t.display_name = "Exploration Gear"
	t.description = "Scouts can cover more territory and detect threats earlier."
	t.research_cost = {
		ItemsLibrary.Items.WOOD: 35,
		ItemsLibrary.Items.STONE: 20,
		ItemsLibrary.Items.JADE: 10,
	}
	t.required_stage = Enums.ProgressionStage.ESTABLISHED
	t.prerequisites = []
	t.duration = 45.0
	return t
