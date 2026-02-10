class_name BTMoveTo
extends BTAction
## Moves mob toward blackboard["move_target"] via the AIController.
##
## Returns RUNNING while moving, SUCCESS when arrived, FAILURE if no target.
## Requires blackboard keys: "move_target" (Vector2), "ai_controller" (AIController).

var _controller: AIController = null


func _on_start() -> void:
	_controller = blackboard.get_value("ai_controller") as AIController
	var target = blackboard.get_value("move_target")

	if _controller and target is Vector2:
		_controller.move_toward_position(target)


func _execute(_delta: float) -> Enums.BTStatus:
	if _controller == null:
		return Enums.BTStatus.FAILURE

	var target = blackboard.get_value("move_target")
	if not target is Vector2:
		return Enums.BTStatus.FAILURE

	# Update target in case it changed
	_controller.move_toward_position(target)

	if _controller.is_at_target():
		return Enums.BTStatus.SUCCESS

	return Enums.BTStatus.RUNNING


func _on_end(_status: Enums.BTStatus) -> void:
	if _controller:
		_controller.stop()
	_controller = null
