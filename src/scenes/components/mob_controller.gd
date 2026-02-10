class_name MobController
extends Node
## Abstract base class for all mob controllers.
##
## Defines the interface contract between a controller and its parent Mob.
## Both PlayerController (input-driven) and AIController (BT-driven) extend this.
##
## Controllers are attached as children of a Mob and drive its actions.
## Only one controller should be active at a time per Mob.

#region Properties

## Reference to the parent Mob this controller drives
var mob: Mob = null

## Whether this controller is currently active
var is_active: bool = false

#endregion

#region Lifecycle

func _ready() -> void:
	_bind_to_parent()


## Discover and bind to the parent Mob.
func _bind_to_parent() -> void:
	var parent = get_parent()
	if parent is Mob:
		mob = parent as Mob
		_on_attached()
	elif parent != null:
		push_warning("%s: Parent '%s' is not a Mob. Controller will not function." % [get_class(), parent.name])

#endregion

#region Virtual Hooks

## Called when this controller is attached to a Mob.
## Override to perform setup (register actions, initialize state).
func _on_attached() -> void:
	pass


## Called when this controller is detached from a Mob.
## Override to perform cleanup (stop movement, disconnect signals).
func _on_detached() -> void:
	pass

#endregion

#region Control State

## Activate this controller.
func activate() -> void:
	is_active = true


## Deactivate this controller.
func deactivate() -> void:
	is_active = false

#endregion
