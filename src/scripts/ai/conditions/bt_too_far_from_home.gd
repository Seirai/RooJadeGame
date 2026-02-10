class_name BTTooFarFromHome
extends BTCondition
## Checks if the mob is too far from its home position.
##
## Requires blackboard keys: "roo" (Roo), "home_position" (Vector2).

var _max_distance: float


func _init(max_distance: float = 500.0) -> void:
	_max_distance = max_distance


func _evaluate() -> bool:
	var roo = blackboard.get_value("roo")
	var home = blackboard.get_value("home_position")
	if roo == null or not home is Vector2:
		return false
	return roo.global_position.distance_to(home) > _max_distance
