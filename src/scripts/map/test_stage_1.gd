extends BaseMap
## Test Stage 1 - Simple test map for player movement testing.

## Player scene to spawn
@export var player_scene: PackedScene

## Radius (in tiles) of initially claimed territory around spawn
@export var initial_territory_radius: int = 3

## Reference to spawned player
var player: Player = null


func _spawn_entities() -> void:
	# Spawn player at the PlayerSpawn marker
	if player_scene:
		player = spawn_at_point(player_scene, "PlayerSpawn") as Player
		if player:
			print("Player spawned at: ", player.global_position)
			_setup_camera_follow()
			_claim_starting_territory(player.global_position)
	else:
		push_error("TestStage1: player_scene not assigned!")


func _setup_camera_follow() -> void:
	# CameraService handles camera management via player.gd
	# Player will find and register the scene camera, or create one if needed
	# No need to remove the scene camera - player uses it
	pass


## Claim a small patch of territory around a world position as the settlement origin
func _claim_starting_territory(origin: Vector2) -> void:
	var world_grid = GameManager.WorldGridService if GameManager else null
	if not world_grid:
		return

	var center = world_grid.world_to_cell(origin)

	for x in range(-initial_territory_radius, initial_territory_radius + 1):
		for y in range(-initial_territory_radius, initial_territory_radius + 1):
			var cell = center + Vector2i(x, y)
			if not world_grid.has_cell(cell):
				continue
			if not world_grid.is_passable(cell):
				continue
			# Mark as scouted then immediately claimed for starting area
			world_grid.set_territory_state(cell, Enums.TileState.CLAIMED)
			world_grid.set_claimed_at(cell)

	var claimed = world_grid.get_cells_by_territory(Enums.TileState.CLAIMED)
	print("Starting territory claimed: %d tiles around %s" % [claimed.size(), center])