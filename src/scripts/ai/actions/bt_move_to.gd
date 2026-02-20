class_name BTMoveTo
extends BTAction
## Moves mob toward blackboard["move_target"] via the AIController.
##
## Returns RUNNING while moving, SUCCESS when arrived, FAILURE if no target.
## Returns FAILURE if the mob appears stuck (no significant movement within
## STUCK_CHECK_INTERVAL seconds), preventing permanent hangs against walls.
## Requires blackboard keys: "move_target" (Vector2), "ai_controller" (AIController).

## Seconds between stuck position checks.
const STUCK_CHECK_INTERVAL: float = 3.0
## Minimum pixels the mob must travel between checks to be considered moving.
const STUCK_MIN_MOVEMENT: float = 16.0

var _controller: AIController = null
var _stuck_timer: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO


func _on_start() -> void:
	_controller = blackboard.get_value("ai_controller") as AIController
	var target = blackboard.get_value("move_target")
	if _controller and target is Vector2:
		_controller.move_toward_position(target)
	var roo = blackboard.get_value("roo")
	_last_pos = roo.global_position if roo else Vector2.ZERO
	_stuck_timer = 0.0


func _execute(delta: float) -> Enums.BTStatus:
	if _controller == null:
		return Enums.BTStatus.FAILURE

	var target = blackboard.get_value("move_target")
	if not target is Vector2:
		return Enums.BTStatus.FAILURE

	_controller.move_toward_position(target)

	if _controller.is_at_target():
		return Enums.BTStatus.SUCCESS

	# Stuck detection: fail if the mob hasn't moved meaningfully in the window.
	var roo = blackboard.get_value("roo")
	if roo:
		_stuck_timer += delta
		if _stuck_timer >= STUCK_CHECK_INTERVAL:
			if roo.global_position.distance_to(_last_pos) < STUCK_MIN_MOVEMENT:
				return Enums.BTStatus.FAILURE
			_last_pos = roo.global_position
			_stuck_timer = 0.0

	return Enums.BTStatus.RUNNING


func _on_end(_status: Enums.BTStatus) -> void:
	if _controller:
		_controller.stop()
	_controller = null
