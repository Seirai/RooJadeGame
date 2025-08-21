extends RefCounted
## Action Callback
## 
## For enforcing what's in the input action stack. 

class_name ActionCallback

var event_name: String = ""
var is_floor := false
var callback: Callable

func _init(_event_name: String, _is_floor: bool, _callback: Callable):
	event_name = _event_name
	is_floor = _is_floor
	callback = _callback