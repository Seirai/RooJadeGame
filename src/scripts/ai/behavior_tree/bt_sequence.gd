class_name BTSequence
extends BTComposite
## Runs children in order until one fails.
##
## Returns FAILURE on first child failure.
## Returns RUNNING if a child returns RUNNING (resumes from that child next tick).
## Returns SUCCESS only if ALL children succeed.

var _running_child_index: int = -1


func tick(delta: float) -> Enums.BTStatus:
	var start_index = _running_child_index if _running_child_index >= 0 else 0

	for i in range(start_index, children.size()):
		var status = children[i].tick(delta)

		match status:
			Enums.BTStatus.FAILURE:
				_running_child_index = -1
				return Enums.BTStatus.FAILURE

			Enums.BTStatus.RUNNING:
				_running_child_index = i
				return Enums.BTStatus.RUNNING

			Enums.BTStatus.SUCCESS:
				continue

	# All children succeeded
	_running_child_index = -1
	return Enums.BTStatus.SUCCESS


func reset() -> void:
	_running_child_index = -1
	super.reset()
