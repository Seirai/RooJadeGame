class_name BTHasTarget
extends BTCondition
## Checks if the blackboard has a valid move_target.

func _evaluate() -> bool:
	return blackboard.has_key("move_target") and blackboard.get_value("move_target") is Vector2
