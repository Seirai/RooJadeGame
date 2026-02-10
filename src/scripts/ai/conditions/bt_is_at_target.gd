class_name BTIsAtTarget
extends BTCondition
## Checks if the mob has arrived at the current move target.
##
## Requires blackboard key: "ai_controller" (AIController).

func _evaluate() -> bool:
	var controller = blackboard.get_value("ai_controller") as AIController
	if controller == null:
		return false
	return controller.is_at_target()
