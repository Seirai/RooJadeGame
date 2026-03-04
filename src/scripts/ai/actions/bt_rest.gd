class_name BTRest
extends BTAction
## Rests at the shelter found by BTFindShelter until stamina reaches Roo.RESUME_WORK.
##
## On start: claims an occupant slot in the shelter and sets roo.is_resting = true
##           so Roo._process stops draining stamina.
## Each tick: regenerates stamina at a rate proportional to the shelter tier.
## On end:   releases the occupant slot and clears roo.is_resting regardless of
##           whether the rest was completed or interrupted (e.g., profession change).
##
## Regen rates by building type (multiplier on BASE_REGEN_PER_SECOND):
##   MAKESHIFT_SHELTER  0.6× — cramped, bare minimum
##   LIVING_QUARTERS    1.4× — personal space, good sleep
##   anything else      1.0× — baseline (future Bunkhouse tier)
##
## Full regen at 1.0× takes 4 real-minutes at 1× debug_speed.
##
## Requires blackboard keys: "rest_shelter" (Node), "roo" (Roo).

## Full regen in 4 real-minutes at 1.0× rate and 1× debug_speed.
const BASE_REGEN_PER_SECOND: float = 1.0 / 240.0

var _shelter: Node = null
## True only if assign_roo() succeeded — gates regen and release.
var _assigned: bool = false


func _on_start() -> void:
	var roo: Roo = blackboard.get_value("roo")
	_shelter = blackboard.get_value("rest_shelter")
	_assigned = false
	if is_instance_valid(_shelter) and roo:
		_assigned = _shelter.assign_roo(roo)
		if _assigned:
			roo.is_resting = true
	blackboard.set_value("activity_state", "Resting")


func _execute(delta: float) -> Enums.BTStatus:
	# Shelter was full by the time we arrived — give up and retry next cycle.
	if not _assigned:
		return Enums.BTStatus.FAILURE

	var roo: Roo = blackboard.get_value("roo")
	if not roo or not is_instance_valid(_shelter):
		return Enums.BTStatus.FAILURE

	var speed: float = GameManager.debug_speed if GameManager else 1.0
	var rate: float = _get_shelter_regen_rate() * BASE_REGEN_PER_SECOND * speed
	roo.stamina = minf(1.0, roo.stamina + rate * delta)

	if roo.stamina >= Roo.RESUME_WORK:
		return Enums.BTStatus.SUCCESS
	return Enums.BTStatus.RUNNING


func _on_end(_status: Enums.BTStatus) -> void:
	var roo: Roo = blackboard.get_value("roo")
	if roo:
		roo.is_resting = false
	if _assigned and is_instance_valid(_shelter) and roo:
		_shelter.release_roo(roo)
	_shelter = null
	_assigned = false
	blackboard.erase_key("rest_shelter")
	blackboard.erase_key("activity_state")


## Returns the regen multiplier for the shelter this Roo is occupying.
func _get_shelter_regen_rate() -> float:
	if not is_instance_valid(_shelter):
		return 1.0
	var building_type: int = _shelter.get_meta("building_type", Enums.BuildingType.NONE)
	match building_type:
		Enums.BuildingType.MAKESHIFT_SHELTER:
			return 0.6
		Enums.BuildingType.LIVING_QUARTERS:
			return 1.4
		_:
			return 1.0
