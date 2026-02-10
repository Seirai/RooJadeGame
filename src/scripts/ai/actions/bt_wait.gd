class_name BTWait
extends BTAction
## Idles for a specified duration.
##
## Returns RUNNING while waiting, then SUCCESS when the time elapses.

var duration: float
var _elapsed: float = 0.0


func _init(wait_duration: float = 1.0) -> void:
	duration = wait_duration


func _on_start() -> void:
	_elapsed = 0.0


func _execute(delta: float) -> Enums.BTStatus:
	_elapsed += delta
	if _elapsed >= duration:
		return Enums.BTStatus.SUCCESS
	return Enums.BTStatus.RUNNING
