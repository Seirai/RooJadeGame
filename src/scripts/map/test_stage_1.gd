extends BaseMap
## Test Stage 1 - Simple test map for player movement testing.

## Player scene to spawn
@export var player_scene: PackedScene

## Roo scene to spawn for AI testing
@export var roo_scene: PackedScene

## Number of test Roos to spawn
@export var test_roo_count: int = 3

## Reference to spawned player
var player: Player = null


func _spawn_entities() -> void:
	# Spawn player at the PlayerSpawn marker
	if player_scene:
		player = spawn_at_point(player_scene, "PlayerSpawn") as Player
		if player:
			print("Player spawned at: ", player.global_position)
			_setup_camera_follow()
			_spawn_test_roos()
	else:
		push_error("TestStage1: player_scene not assigned!")


func _setup_camera_follow() -> void:
	# CameraService handles camera management via player.gd
	# Player will find and register the scene camera, or create one if needed
	# No need to remove the scene camera - player uses it
	pass


## Spawn test Roos near the player for AI behavior testing
func _spawn_test_roos() -> void:
	if not roo_scene or not player:
		return

	for i in range(test_roo_count):
		var roo = roo_scene.instantiate() as Roo
		if roo == null:
			continue

		# Spread Roos around player spawn
		var offset_x = randf_range(-80, 80)
		add_child(roo)
		roo.global_position = player.global_position + Vector2(offset_x, 0)

		# Register with settlement — assigns roo_id and tracks population
		if player_settlement:
			var id = player_settlement.register_roo(roo, false)
			roo.roo_id = id

		# First Roo idles, the rest scout
		if i == 0:
			roo.set_profession(Enums.Professions.NONE)
		else:
			roo.set_profession(Enums.Professions.SCOUT)

		print("Test Roo #%d spawned as %s at %s" % [i, Enums.Professions.keys()[roo.profession], roo.global_position])
