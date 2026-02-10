class_name BTSetTarget
extends BTAction
## Copies a position from one blackboard key to "move_target".
##
## Used to set the move target from a known blackboard position
## (e.g., "home_position" for returning home).
## Returns SUCCESS immediately.

var _source_key: String


func _init(source_key: String = "home_position") -> void:
	_source_key = source_key


func _execute(_delta: float) -> Enums.BTStatus:
	var position = blackboard.get_value(_source_key)
	if not position is Vector2:
		return Enums.BTStatus.FAILURE

	blackboard.set_value("move_target", position)
	return Enums.BTStatus.SUCCESS
