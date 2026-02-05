extends Node
class_name ResearchManager
## Manages the tech tree and research progression.
##
## Handles starting research, tracking progress, and unlocking techs.
## Operates on Settlement's _unlocked_techs and _research_queue data.
## Does not own data - receives references via init().

#region Signals

signal tech_unlocked(tech_id: Enums.ResearchTech)
signal research_started(tech_id: Enums.ResearchTech)
signal research_complete(tech_id: Enums.ResearchTech)

#endregion

#region State References

var _unlocked_techs: Array
var _research_queue: Array
var _resource_manager: ResourceManager

## Currently researching tech (-1 if none)
var _current_research: int = -1
var _research_progress: float = 0.0

#endregion

#region Initialization

func init(unlocked_techs: Array, research_queue: Array, resource_manager: ResourceManager) -> void:
	_unlocked_techs = unlocked_techs
	_research_queue = research_queue
	_resource_manager = resource_manager

#endregion

#region Public API

## Check if a tech is unlocked
func is_unlocked(tech_id: Enums.ResearchTech) -> bool:
	return _unlocked_techs.has(tech_id)


## Check if a tech can be researched (prerequisites met, not already unlocked)
func can_research(tech_id: Enums.ResearchTech) -> bool:
	if is_unlocked(tech_id):
		return false

	var prereqs = ResearchLibrary.get_prerequisites(tech_id)
	for prereq in prereqs:
		if not is_unlocked(prereq):
			return false

	var cost = ResearchLibrary.get_research_cost(tech_id)
	return _resource_manager.can_afford(cost)


## Start researching a tech (spends resources immediately)
func start_research(tech_id: Enums.ResearchTech) -> bool:
	if not can_research(tech_id):
		return false

	var cost = ResearchLibrary.get_research_cost(tech_id)
	if not _resource_manager.spend(cost):
		return false

	_research_queue.append(tech_id)
	research_started.emit(tech_id)

	# If nothing is currently being researched, start this one
	if _current_research < 0:
		_start_next_research()

	return true


## Directly unlock a tech (bypasses cost and prerequisites)
func unlock_tech(tech_id: Enums.ResearchTech) -> void:
	if is_unlocked(tech_id):
		return
	_unlocked_techs.append(tech_id)
	tech_unlocked.emit(tech_id)


## Get all available techs that can be researched
func get_available() -> Array[Enums.ResearchTech]:
	var result: Array[Enums.ResearchTech] = []
	for tech_id in Enums.ResearchTech.values():
		if can_research(tech_id):
			result.append(tech_id)
	return result


## Get all unlocked techs
func get_unlocked() -> Array:
	return _unlocked_techs.duplicate()


## Get current research progress (0.0 to 1.0)
func get_progress() -> float:
	if _current_research < 0:
		return 0.0
	var tech = ResearchLibrary.get_tech(_current_research)
	if tech and tech.duration > 0.0:
		return clampf(_research_progress / tech.duration, 0.0, 1.0)
	return 0.0


## Get currently researching tech ID (-1 if none)
func get_current_research() -> int:
	return _current_research

#endregion

#region Process

## Call this from Settlement._process() to advance research
func process_research(delta: float) -> void:
	if _current_research < 0:
		return

	_research_progress += delta

	var tech = ResearchLibrary.get_tech(_current_research)
	if tech and _research_progress >= tech.duration:
		_complete_current_research()

#endregion

#region Internal

func _start_next_research() -> void:
	if _research_queue.is_empty():
		_current_research = -1
		_research_progress = 0.0
		return

	_current_research = _research_queue[0]
	_research_progress = 0.0


func _complete_current_research() -> void:
	var completed_tech = _current_research
	unlock_tech(completed_tech)

	_research_queue.erase(completed_tech)
	research_complete.emit(completed_tech)

	# Start next in queue
	_start_next_research()

#endregion
