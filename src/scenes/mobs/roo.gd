extends Mob
class_name Roo
## Roo - A citizen of the settlement.
##
## Roos are the primary workforce of the settlement, performing various
## professions like scouting, lumber harvesting, mining, building, and fighting.

#region Signals

signal profession_changed(new_profession: Enums.Professions)

#endregion

#region Properties

## Reference to the AI brain (if present)
var roo_brain: RooBrain = null

## Current profession assignment
var profession: Enums.Professions = Enums.Professions.NONE:
	set(value):
		if profession != value:
			profession = value
			_update_debug_info()
			profession_changed.emit(value)

## Unique Roo ID (set by PopulationManager)
var roo_id: int = -1:
	set(value):
		roo_id = value
		_update_debug_name()

## Whether this is a viewer-controlled Roo or AI-controlled
var is_viewer_controlled: bool = false

## World position of this Roo's current workplace.
## Set when a profession with a fixed worksite is assigned.
## Falls back to global_position when no worksite has been explicitly set.
var work_position: Vector2:
	get: return _work_position if _work_position != Vector2.ZERO else global_position
	set(v): _work_position = v

var _work_position: Vector2 = Vector2.ZERO

#endregion

#region Stamina

## Stamina drops to this level before the Roo finishes its current task then rests.
const REST_TRIGGER: float = 0.35
## At or above this level the Roo wakes and returns to work.
const RESUME_WORK: float  = 0.90
## Stamina below this triggers a future fatigue debuff.
const CRITICAL: float     = 0.15

## Drain multiplier per profession (applied on top of BASE_DRAIN_PER_SECOND).
## Declared as var because GDScript cannot use autoload enum values as const keys.
var STAMINA_DRAIN_RATES: Dictionary = {
	Enums.Professions.NONE:       0.3,
	Enums.Professions.SCOUT:      0.8,
	Enums.Professions.LUMBERJACK: 1.2,
	Enums.Professions.MINER:      1.4,
	Enums.Professions.BUILDER:    1.1,
	Enums.Professions.FIGHTER:    1.3,
}

## Full drain in 8 real-minutes at 1× debug_speed for a 1.0× profession rate.
const BASE_DRAIN_PER_SECOND: float = 1.0 / 480.0

## Current stamina (1.0 = fully rested, 0.0 = collapsed).
## Staggered at spawn by the settlement so Roos don't all crash simultaneously.
var stamina: float = 1.0

## True while BTRest is regenerating — suppresses the drain tick.
var is_resting: bool = false

## Preferred residential building (null = hot-bunk from any available shelter).
var home_shelter: Node = null

#endregion

#region Lifecycle

func _ready() -> void:
	super._ready()
	roo_brain = get_node_or_null("RooBrain") as RooBrain
	_update_debug_name()
	_update_debug_info()


func _process(delta: float) -> void:
	if not is_resting:
		_drain_stamina(delta)


func _drain_stamina(delta: float) -> void:
	var rate: float = STAMINA_DRAIN_RATES.get(profession, 1.0) * BASE_DRAIN_PER_SECOND
	var speed: float = GameManager.debug_speed if GameManager else 1.0
	stamina = maxf(0.0, stamina - rate * speed * delta)


func _update_debug_name() -> void:
	if debug_overlay:
		var name_str = "Roo"
		if roo_id >= 0:
			name_str = "Roo #%d" % roo_id
		if is_viewer_controlled:
			name_str += " [P]"
		debug_overlay.set_display_name(name_str)


func _update_debug_info() -> void:
	if debug_overlay:
		var prof_name = Enums.Professions.keys()[profession]
		debug_overlay.set_info(prof_name)

#endregion

#region Public API

## Assign a profession to this Roo
func set_profession(new_profession: Enums.Professions) -> void:
	profession = new_profession


## Get the current profession
func get_profession() -> Enums.Professions:
	return profession


## Mark this Roo as viewer-controlled
func set_viewer_controlled(controlled: bool) -> void:
	is_viewer_controlled = controlled
	_update_debug_name()

#endregion
