class_name BTPickRandomNearbyPoint
extends BTAction
## Picks a random point near blackboard["home_position"] and sets it as move_target.
##
## Returns SUCCESS immediately after setting the target.
## Requires blackboard key: "home_position" (Vector2).

var _wander_radius: float


func _init(wander_radius: float = 100.0) -> void:
	_wander_radius = wander_radius


func _execute(_delta: float) -> Enums.BTStatus:
	var home = blackboard.get_value("home_position")
	if not home is Vector2:
		return Enums.BTStatus.FAILURE

	var offset_x = randf_range(-_wander_radius, _wander_radius)
	var target = Vector2(home.x + offset_x, home.y)

	blackboard.set_value("move_target", target)
	return Enums.BTStatus.SUCCESS
