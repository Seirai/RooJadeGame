extends BaseMap
## Test Stage 1 - Simple test map for player movement testing.

## Player scene to spawn
@export var player_scene: PackedScene

## Reference to spawned player
var player: Player = null


func _spawn_entities() -> void:
	# Spawn player at the PlayerSpawn marker
	if player_scene:
		player = spawn_at_point(player_scene, "PlayerSpawn") as Player
		if player:
			print("Player spawned at: ", player.global_position)
			_setup_camera_follow()
	else:
		push_error("TestStage1: player_scene not assigned!")


func _setup_camera_follow() -> void:
	# CameraService handles camera management via player.gd
	# Player will find and register the scene camera, or create one if needed
	# No need to remove the scene camera - player uses it
	pass