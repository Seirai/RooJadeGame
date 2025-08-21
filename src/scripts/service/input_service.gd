extends Node
## This will manage the translation layer between all forms of input into action events.
##
## Depending on the bind, we'll need to translate specific things like whether it was a key release, key press, or key hold event that
## translates to specific actions
var ActionService = GameManager.ActionService
var actions: Dictionary = GameManager.actions
var _input_poll_map := {}

func _ready():
	print(actions)
	pass

func _process(delta):
	pass

func load():
	pass

func _input(event):
	for action in actions:
		for input in actions[action]:
			if event is InputEventKey and input is InputEventKey: 
				if(event.keycode == input.keycode):
					print(event.keycode, " was pressed")
					ActionService.fire_action(action, {})
			if event is InputEventMouseButton and input is InputEventMouseButton:
				if(event.button_index == input.button_index):
					print(input, " was pressed")
					ActionService.fire_action(action, {})