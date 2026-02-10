class_name RooBrain
extends Node
## Main AI controller for a Roo entity.
##
## Holds the behavior tree, blackboard, and ticks the BT at a fixed rate.
## Listens to profession_changed to swap profession subtrees.
## Creates and manages the AIController on the parent Roo.

#region Properties

## Behavior tree tick rate (ticks per second)
@export var tick_rate: float = 5.0

#endregion

#region State

var roo: Roo = null
var ai_controller: AIController = null
var blackboard: Blackboard = Blackboard.new()

var _behavior_tree: BTNode = null
var _tick_interval: float = 0.2
var _tick_accumulator: float = 0.0
var _current_state_name: String = "Init"
var _settlement_resolved: bool = false

#endregion

#region Lifecycle

func _ready() -> void:
	_tick_interval = 1.0 / tick_rate

	roo = get_parent() as Roo
	if roo == null:
		push_error("RooBrain: Parent is not a Roo. Disabling.")
		set_process(false)
		return

	# Create and attach AIController
	ai_controller = AIController.new()
	ai_controller.name = "AIController"
	roo.set_controller(ai_controller)

	# Initialize blackboard with common references
	blackboard.set_value("roo", roo)
	blackboard.set_value("ai_controller", ai_controller)
	blackboard.set_value("home_position", roo.global_position)

	# Connect to profession changes
	roo.profession_changed.connect(_on_profession_changed)

	# Build initial tree based on current profession
	_build_tree(roo.profession)


func _process(delta: float) -> void:
	if _behavior_tree == null:
		return

	# Lazily resolve references on first tick
	if not _settlement_resolved:
		_resolve_deferred_references()

	_tick_accumulator += delta
	while _tick_accumulator >= _tick_interval:
		_tick_accumulator -= _tick_interval
		_behavior_tree.tick(_tick_interval)

	# Update debug display
	_update_debug_display()

#endregion

#region Profession Management

func _on_profession_changed(new_profession: Enums.Professions) -> void:
	# Clear profession-specific data but keep common references
	blackboard.clear_profession_data()

	# Rebuild the behavior tree
	_build_tree(new_profession)


func _build_tree(profession: Enums.Professions) -> void:
	# Reset old tree if it exists
	if _behavior_tree:
		_behavior_tree.reset()

	match profession:
		Enums.Professions.SCOUT:
			_behavior_tree = _build_scout_tree()
		_:
			_behavior_tree = _build_idle_tree()

	_behavior_tree.initialize(blackboard)

#endregion

#region Tree Builders

## NONE/fallback: Wander randomly near home.
## Sequence loops: pick random point -> move to it -> wait.
func _build_idle_tree() -> BTNode:
	_current_state_name = "Idle"
	var root = BTSequence.new()
	root.add_child_node(BTPickRandomNearbyPoint.new(100.0))
	root.add_child_node(BTMoveTo.new())
	root.add_child_node(BTWait.new(randf_range(2.0, 5.0)))
	return root


## SCOUT: Explore frontier tiles, return home if too far, idle fallback.
func _build_scout_tree() -> BTNode:
	_current_state_name = "Scouting"

	# Sequence 1: Explore frontier
	var explore = BTSequence.new()
	explore.add_child_node(BTFindFrontierTile.new())
	explore.add_child_node(BTHasTarget.new())
	explore.add_child_node(BTMoveTo.new())
	explore.add_child_node(BTScoutTile.new())

	# Sequence 2: Return home if too far
	var return_home = BTSequence.new()
	return_home.add_child_node(BTTooFarFromHome.new(500.0))
	return_home.add_child_node(BTSetTarget.new("home_position"))
	return_home.add_child_node(BTMoveTo.new())

	# Sequence 3: Idle fallback (no frontier tiles available)
	var idle_fallback = BTSequence.new()
	idle_fallback.add_child_node(BTPickRandomNearbyPoint.new(80.0))
	idle_fallback.add_child_node(BTMoveTo.new())
	idle_fallback.add_child_node(BTWait.new(3.0))

	# Root selector: try explore, then return home, then idle
	var root = BTSelector.new()
	root.add_child_node(explore)
	root.add_child_node(return_home)
	root.add_child_node(idle_fallback)
	return root

#endregion

#region Settlement Resolution

## Lazily resolve references that may not be available during _ready().
## Called once on the first process tick.
func _resolve_deferred_references() -> void:
	# Update home_position now that the Roo has been positioned by the spawner
	blackboard.set_value("home_position", roo.global_position)

	# Resolve settlement via group lookup
	var settlement = get_tree().get_first_node_in_group("settlement")
	if settlement:
		blackboard.set_value("settlement", settlement)

	# Resolve world grid service
	if GameManager and GameManager.WorldGridService:
		blackboard.set_value("world_grid", GameManager.WorldGridService)

	_settlement_resolved = true

#endregion

#region Debug Display

func _update_debug_display() -> void:
	if roo == null or roo.sprite_node == null:
		return
	if not roo.sprite_node is DebugSprite:
		return

	var prof_name = Enums.Professions.keys()[roo.profession]
	roo.sprite_node.set_info("%s: %s" % [prof_name, _current_state_name])

#endregion
