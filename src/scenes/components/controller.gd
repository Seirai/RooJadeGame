extends Node
class_name ControllerComponent
## Component that translates GUIDE input actions into parent entity actions.
##
## Attach this to any entity that can be controlled (Player, NPCs, vehicles).
## The parent entity must implement `_register_controller(controller)` which
## returns an ActionMap dictionary mapping action names to callables.
##
## Action Map Structure:
##   The parent returns a dictionary where keys are action names and values
##   are either Callables or sub-dictionaries with metadata:
##
##   Simple: { "attack": Callable(self, "attack") }
##   With metadata: { "attack": { "call": Callable(self, "attack"), "type": "trigger" } }
##
## Action Types:
##   - "continuous": Called every frame with (value, delta) - for movement, aiming
##   - "held": Called every frame while held with (is_held, delta) - for jumping, charging
##   - "trigger": Called once when triggered - for attack, dash, interact

#region GUIDE Resources

@export_group("Mapping Contexts")
## Main gameplay context for this entity
@export var gameplay_context: GUIDEMappingContext
## Dialogue context (overrides gameplay when in dialogue)
@export var dialogue_context: GUIDEMappingContext

@export_group("Gameplay Actions")
## Movement action (Axis2D)
@export var move_action: GUIDEAction
## Jump action (Button)
@export var jump_action: GUIDEAction
## Attack action (Button)
@export var attack_action: GUIDEAction
## Interact action (Button)
@export var interact_action: GUIDEAction
## Dash action (Button)
@export var dash_action: GUIDEAction

#endregion

#region State

var _is_enabled: bool = false
## Action map from parent - maps action names to callables/metadata
var _action_map: Dictionary = {}
## Cached callable references for performance
var _move_action_call: Callable
var _jump_action_call: Callable
var _attack_action_call: Callable
var _interact_action_call: Callable
var _dash_action_call: Callable

#endregion

#region Lifecycle

func _ready() -> void:
	# Register with parent if it supports controller registration
	_register_with_parent()

	# Connect GUIDE action signals for trigger-type actions
	_connect_guide_actions()


func _physics_process(delta: float) -> void:
	if not _is_enabled:
		return

	# Process continuous actions (movement)
	if move_action and _move_action_call.is_valid():
		_move_action_call.call(move_action.value_axis_2d.x, delta)

	# Process held actions (jump)
	if jump_action and _jump_action_call.is_valid():
		_jump_action_call.call(jump_action.value_bool, delta)

#endregion

#region Registration

## Attempts to register with parent entity
func _register_with_parent() -> void:
	var parent = get_parent()
	if parent == null:
		return

	if not parent.has_method("_register_controller"):
		push_warning("ControllerComponent: Parent '%s' does not implement _register_controller(). Controller disabled." % parent.name)
		return

	# Call parent's registration function - it returns the action map
	_action_map = parent._register_controller(self)

	if _action_map.is_empty():
		push_warning("ControllerComponent: Parent returned empty action map.")
		return

	# Cache callable references for performance
	_cache_action_callables()

	# Auto-enable if gameplay context is assigned
	if gameplay_context:
		enable_control()


## Extracts and caches callable references from action map
func _cache_action_callables() -> void:
	_move_action_call = _get_callable("move")
	_jump_action_call = _get_callable("jump")
	_attack_action_call = _get_callable("attack")
	_interact_action_call = _get_callable("interact")
	_dash_action_call = _get_callable("dash")


## Gets a callable from the action map (handles both simple and metadata formats)
func _get_callable(action_name: String) -> Callable:
	if not _action_map.has(action_name):
		return Callable()

	var entry = _action_map[action_name]

	# Simple format: directly a Callable
	if entry is Callable:
		return entry

	# Metadata format: { "call": Callable, "type": "trigger", ... }
	if entry is Dictionary and entry.has("call") and entry["call"] is Callable:
		return entry["call"]

	return Callable()

#endregion

#region GUIDE Connections

## Connects GUIDE action signals for trigger-type actions
func _connect_guide_actions() -> void:
	if attack_action:
		attack_action.triggered.connect(_on_attack_triggered)

	if interact_action:
		interact_action.triggered.connect(_on_interact_triggered)

	if dash_action:
		dash_action.triggered.connect(_on_dash_triggered)


func _on_attack_triggered() -> void:
	if _is_enabled and _attack_action_call.is_valid():
		_attack_action_call.call()


func _on_interact_triggered() -> void:
	if _is_enabled and _interact_action_call.is_valid():
		_interact_action_call.call()


func _on_dash_triggered() -> void:
	if _is_enabled and _dash_action_call.is_valid():
		_dash_action_call.call()

#endregion

#region Control State

## Enables input processing
func enable_control() -> void:
	if gameplay_context and not _is_enabled:
		GUIDE.enable_mapping_context(gameplay_context)
		_is_enabled = true


## Disables input processing
func disable_control() -> void:
	if gameplay_context and _is_enabled:
		GUIDE.disable_mapping_context(gameplay_context)
		_is_enabled = false


## Switches to dialogue context (disables gameplay)
func enable_dialogue_mode() -> void:
	if dialogue_context and gameplay_context:
		GUIDE.disable_mapping_context(gameplay_context)
		GUIDE.enable_mapping_context(dialogue_context)


## Returns to gameplay from dialogue
func disable_dialogue_mode() -> void:
	if dialogue_context and gameplay_context and _is_enabled:
		GUIDE.disable_mapping_context(dialogue_context)
		GUIDE.enable_mapping_context(gameplay_context)


## Checks if this controller is currently enabled
func is_enabled() -> bool:
	return _is_enabled

#endregion
