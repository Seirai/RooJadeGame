class_name BTAction
extends BTNode
## Base class for action nodes that can span multiple ticks.
##
## Provides lifecycle hooks: _on_start(), _execute(), _on_end().
## Tracks running state and handles cleanup on abort.

var _is_running: bool = false


func tick(delta: float) -> Enums.BTStatus:
	if not _is_running:
		_on_start()
		_is_running = true

	var status = _execute(delta)

	if status != Enums.BTStatus.RUNNING:
		_is_running = false
		_on_end(status)

	return status


## Called once when the action begins executing.
func _on_start() -> void:
	pass


## Called each tick while the action is running.
## @return: Enums.BTStatus indicating progress
func _execute(_delta: float) -> Enums.BTStatus:
	return Enums.BTStatus.FAILURE


## Called when the action completes (SUCCESS or FAILURE) or is aborted.
func _on_end(_status: Enums.BTStatus) -> void:
	pass


## Reset the action if it was running (e.g., parent selector moved on).
func reset() -> void:
	if _is_running:
		_on_end(Enums.BTStatus.FAILURE)
		_is_running = false
