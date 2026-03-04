class_name BTNeedsRest
extends BTCondition
## Returns SUCCESS when the Roo's stamina is at or below Roo.REST_TRIGGER.
##
## Placed as the first child of the rest-priority selector in the BT root so
## the Roo seeks shelter before the profession subtree runs on each tick cycle.
##
## Requires blackboard key: "roo" (Roo).


func _evaluate() -> bool:
	var roo: Roo = blackboard.get_value("roo")
	if not roo:
		return false
	return roo.stamina <= Roo.REST_TRIGGER
