extends Node 
## Manages core game services.
## 
## Determines load order, minimizes need to have autoload manage several services.
## Also loads in game configuration and consts.
##

const action_service = preload("res://src/scripts/service/action_service.gd")
const settings_service = preload("res://src/scripts/service/settings_service.gd")
const input_service = preload("res://src/scripts/service/input_service.gd")

var ActionService: action_service
var SettingsService: settings_service
var InputService: input_service

## Dictionary holding our current bound action map
## Format: { "action_name": [InputEvent, InputEvent], ...}
## @TODO In the future, we'd want to have a check to load from settings
var actions := {}



func _ready() -> void:

	# Initialize game services in desired order
	SettingsService = settings_service.new()
	add_child(SettingsService)
	# Load local settings data
	SettingsService.load()

	ActionService = action_service.new()
	add_child(ActionService)
	# Load actions
	ActionService.load_actions()

	InputService = input_service.new() # @TODO, fix coupling, requiring InputService to load after ActionService
	add_child(InputService)
	pass