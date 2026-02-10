class_name BTInverter
extends BTDecorator
## Inverts child result: SUCCESS becomes FAILURE, FAILURE becomes SUCCESS.
## RUNNING passes through unchanged.

func tick(delta: float) -> Enums.BTStatus:
	if child == null:
		return Enums.BTStatus.FAILURE

	var status = child.tick(delta)

	match status:
		Enums.BTStatus.SUCCESS:
			return Enums.BTStatus.FAILURE
		Enums.BTStatus.FAILURE:
			return Enums.BTStatus.SUCCESS
		_:
			return status
