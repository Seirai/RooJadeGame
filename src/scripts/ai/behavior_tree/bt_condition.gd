class_name BTCondition
extends BTNode
## Base class for condition checks.
##
## Conditions return SUCCESS or FAILURE (never RUNNING).
## Subclasses override _evaluate() to implement the check.

## Override this to implement the condition check.
## @return: true if condition is met
func _evaluate() -> bool:
	return false


func tick(_delta: float) -> Enums.BTStatus:
	if _evaluate():
		return Enums.BTStatus.SUCCESS
	return Enums.BTStatus.FAILURE
