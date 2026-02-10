class_name BTDecorator
extends BTNode
## Wraps a single child node. Base class for inverters, repeaters, etc.
##
## By default, passes through the child's tick result.
## Subclasses modify the behavior (invert, repeat, guard, etc.).

var child: BTNode = null


## Set the child node. Returns self for chaining.
func set_child(node: BTNode) -> BTDecorator:
	child = node
	return self


func initialize(bb: Blackboard) -> void:
	super.initialize(bb)
	if child:
		child.initialize(bb)


func tick(delta: float) -> Enums.BTStatus:
	if child == null:
		return Enums.BTStatus.FAILURE
	return child.tick(delta)


func reset() -> void:
	if child:
		child.reset()
