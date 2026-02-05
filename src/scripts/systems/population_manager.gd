extends Node
class_name PopulationManager
## Manages Roo population tracking for the settlement.
##
## Handles registration/unregistration of viewer and AI Roos.
## Operates on Settlement's _roos, _viewer_roos, and _ai_roos dictionaries.
## Does not own data - receives references via init().

#region Signals

signal roo_joined(roo: Node, is_viewer: bool)
signal roo_left(roo: Node)
signal roo_profession_changed(roo: Node, old_profession: Enums.Professions, new_profession: Enums.Professions)

#endregion

#region State References

var _roos: Dictionary
var _viewer_roos: Dictionary
var _ai_roos: Dictionary
var _next_roo_id: int = 0

#endregion

#region Initialization

func init(roos: Dictionary, viewer_roos: Dictionary, ai_roos: Dictionary) -> void:
	_roos = roos
	_viewer_roos = viewer_roos
	_ai_roos = ai_roos

#endregion

#region Public API

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
func get_roos_by_profession(profession: Enums.Professions) -> Array[Node]:
	var result: Array[Node] = []
	for roo in _roos.values():
		if roo.has_method("get_profession") and roo.get_profession() == profession:
			result.append(roo)
	return result


## Change a Roo's profession
func set_roo_profession(roo: Node, new_profession: Enums.Professions) -> void:
	if not roo.has_method("get_profession") or not roo.has_method("set_profession"):
		push_warning("PopulationManager: Roo does not support profession methods")
		return

	var old_profession = roo.get_profession()
	if old_profession == new_profession:
		return

	roo.set_profession(new_profession)
	roo_profession_changed.emit(roo, old_profession, new_profession)

#endregion
