class_name Blackboard
extends RefCounted
## Dictionary wrapper for shared behavior tree context data.
##
## Provides typed access helpers and key existence checks.
## All BT nodes in a tree share the same Blackboard instance.

var _data: Dictionary = {}


## Get a value from the blackboard
func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


## Set a value on the blackboard
func set_value(key: String, value: Variant) -> void:
	_data[key] = value


## Check if a key exists
func has_key(key: String) -> bool:
	return _data.has(key)


## Remove a key from the blackboard
func erase_key(key: String) -> void:
	_data.erase(key)


## Clear all data
func clear() -> void:
	_data.clear()


## Clear only profession-specific keys, keeping common references
func clear_profession_data() -> void:
	var keys_to_keep: Array[String] = [
		"roo", "ai_controller", "home_position",
		"settlement", "world_grid",
	]
	var keys_to_erase: Array[String] = []
	for key in _data.keys():
		if key not in keys_to_keep:
			keys_to_erase.append(key)
	for key in keys_to_erase:
		_data.erase(key)
