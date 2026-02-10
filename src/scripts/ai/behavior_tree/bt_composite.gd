class_name BTComposite
extends BTNode
## Base class for composite nodes that have ordered children.
##
## Provides child management and propagates initialize/reset to children.
## Subclasses (BTSelector, BTSequence) define the execution strategy.

var children: Array[BTNode] = []


## Add a child node. Returns self for chaining.
func add_child_node(child: BTNode) -> BTComposite:
	children.append(child)
	return self


## Propagate blackboard to all children.
func initialize(bb: Blackboard) -> void:
	super.initialize(bb)
	for child in children:
		child.initialize(bb)


## Reset all children.
func reset() -> void:
	for child in children:
		child.reset()
