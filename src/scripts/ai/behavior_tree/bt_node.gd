class_name BTNode
extends RefCounted
## Base class for all behavior tree nodes.
##
## Each node receives a shared Blackboard reference and implements tick().
## tick() returns an Enums.BTStatus indicating the result of this frame's execution.

var blackboard: Blackboard


## Called once when the tree is built to propagate the blackboard reference.
func initialize(bb: Blackboard) -> void:
	blackboard = bb


## Execute this node for one tick. Override in subclasses.
## @return: Enums.BTStatus (SUCCESS, FAILURE, or RUNNING)
func tick(delta: float) -> Enums.BTStatus:
	return Enums.BTStatus.FAILURE


## Called when a parent node aborts this node (e.g., selector moves on).
## Override to clean up any in-progress state.
func reset() -> void:
	pass
