extends Node

func _ready():
	pass

func _on_start_button_pressed():
	# Load test stage
	GameManager.SceneService.change_scene("res://src/maps/test_stage_1.tscn")


func _on_settings_button_pressed():
	print("Not yet implemented")
	pass


func _on_exit_button_pressed():
	print("Not yet implemented")
	pass

#func _on_debug_local_start_pressed():
#	print("Not yet implemented")
#	pass

#func _on_debug_dedi_start_pressed():
#	print("Not yet implemented")
#	pass