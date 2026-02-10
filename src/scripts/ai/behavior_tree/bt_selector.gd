class_name BTSelector
extends BTComposite
## Tries children in order until one succeeds.
##
## Returns SUCCESS on first child success.
## Returns RUNNING if a child returns RUNNING (resumes from that child next tick).
## Returns FAILURE only if ALL children fail.

var _running_child_index: int = -1


func tick(delta: float) -> Enums.BTStatus:
	var start_index = _running_child_index if _running_child_index >= 0 else 0

	for i in range(start_index, children.size()):
		var status = children[i].tick(delta)

		match status:
			Enums.BTStatus.SUCCESS:
				# Reset any previously running child if we moved past it
				if _running_child_index >= 0 and _running_child_index != i:
					children[_running_child_index].reset()
				_running_child_index = -1
				return Enums.BTStatus.SUCCESS

			Enums.BTStatus.RUNNING:
				# Reset any previously running child if we moved past it
				if _running_child_index >= 0 and _running_child_index != i:
					children[_running_child_index].reset()
				_running_child_index = i
				return Enums.BTStatus.RUNNING

			Enums.BTStatus.FAILURE:
				continue

	# All children failed
	_running_child_index = -1
	return Enums.BTStatus.FAILURE


func reset() -> void:
	_running_child_index = -1
	super.reset()
