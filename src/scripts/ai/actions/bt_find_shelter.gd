class_name BTFindShelter
extends BTAction
## Locates the nearest available residential building and prepares the blackboard
## for the rest sequence (move_target + rest_shelter).
##
## Priority order:
##   1. roo.home_shelter — if assigned and has a vacancy.
##   2. Hot-bunk   — nearest available residential building via settlement.
##
## Returns SUCCESS immediately when a shelter is found, FAILURE if none are
## available (all shelters full or no shelters exist yet).
##
## Requires blackboard keys: "roo" (Roo), "settlement" (Settlement).
## Sets blackboard keys:     "move_target" (Vector2), "rest_shelter" (Node).


func _execute(_delta: float) -> Enums.BTStatus:
	var roo: Roo = blackboard.get_value("roo")
	var settlement = blackboard.get_value("settlement")
	if not roo:
		return Enums.BTStatus.FAILURE

	# Try the Roo's assigned home shelter first.
	var shelter: Node = null
	if is_instance_valid(roo.home_shelter) \
			and roo.home_shelter.has_method("has_vacancy") \
			and roo.home_shelter.has_vacancy():
		shelter = roo.home_shelter

	# Fall back to any available residential building (hot-bunk).
	if shelter == null and settlement and settlement.has_method("find_available_residential"):
		shelter = settlement.find_available_residential(roo.global_position)

	if shelter == null:
		return Enums.BTStatus.FAILURE

	blackboard.set_value("move_target", (shelter as Node2D).global_position)
	blackboard.set_value("rest_shelter", shelter)
	return Enums.BTStatus.SUCCESS
