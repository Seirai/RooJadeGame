extends Node

func _ready() -> void:
	pass

func load() -> bool:
	_load_input()
	return true

func _load_input() -> void:
	var default_actions_resource = preload("res://src/scripts/resource/default_actions.tres")
	GameManager.actions = default_actions_resource.default_actions
	print(GameManager.actions)
	pass