class_name AIController
extends MobController
## Receives movement commands from RooBrain/BehaviorTree and translates
## them into Mob method calls.
##
## Does NOT make decisions — that is RooBrain/BT's job.
## This controller drives Mob movement in _physics_process based on
## the last command issued by the behavior tree.

#region Properties

## How close the mob must be to the target to count as "arrived" (in pixels)
@export var arrival_distance: float = 16.0

#endregion

#region State

var _move_target: Vector2 = Vector2.ZERO
var _has_move_target: bool = false

#endregion

#region Lifecycle

func _physics_process(delta: float) -> void:
	if not is_active or mob == null:
		return

	if _has_move_target:
		var distance_x = _move_target.x - mob.global_position.x

		if abs(distance_x) < arrival_distance:
			# Arrived at target
			_has_move_target = false
			mob.set_move_input(0.0, delta)
		else:
			# Move toward target
			var direction = sign(distance_x)
			mob.set_move_input(direction, delta)
	else:
		# No target — apply friction to stop
		mob.set_move_input(0.0, delta)

#endregion

#region Controller Hooks

func _on_attached() -> void:
	pass


func _on_detached() -> void:
	stop()

#endregion

#region Command API

## Command the mob to move toward a world position.
func move_toward_position(target: Vector2) -> void:
	_move_target = target
	_has_move_target = true


## Stop all movement.
func stop() -> void:
	_has_move_target = false


## Check if the mob has arrived at the current target.
func is_at_target() -> bool:
	if not _has_move_target or mob == null:
		return not _has_move_target
	return abs(mob.global_position.x - _move_target.x) < arrival_distance


## Check if a move target is set.
func has_move_target() -> bool:
	return _has_move_target

#endregion
