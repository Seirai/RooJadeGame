extends Node 
## This will create all actions and manage them.
## 
## Allows creation of actions, then allows for various functions to subscribe to them.
## Maintains a stack of functions subscribed to actions with the feature of being able
## soak inputs past a certain point in the stack if needed.
var actions = {}
var signals = {}
var ActionCallback = preload("res://src/scripts/class/action_callback.gd")

func _ready():
	pass

func load_actions() -> void:
	var loaded_actions = GameManager.actions	
	for action in loaded_actions:
		actions[action] = []

func subscribe_to_action(_action_name: String, _event_name: String, _is_floor: bool, _callback: Callable) -> void:
	var action_callback = ActionCallback.new(_event_name, _is_floor, _callback)
	actions[_action_name].push_front(action_callback)

func unsubscribe_from_action(_action_name, _callback_name) -> void:
	var search = func(callback) -> bool:
		return callback.callback_name == _callback_name 
	var index = actions[_action_name].find_custom(search)
	actions[_action_name].remove_at(index)

func fire_action(_action_name: String, _args: Dictionary) -> void:
	for i in range(actions[_action_name].size()-1):
		var callback = actions[_action_name][i]
		callback.call(_args)
		if (callback.is_floor):
			break