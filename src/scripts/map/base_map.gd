extends Node2D
class_name BaseMap
## Base class for all game maps/levels.
##
## Provides common functionality for maps including spawn points,
## camera bounds, entity management, and initialization.

## Map metadata
@export_group("Map Info")
@export var map_id: String = ""
@export var map_name: String = ""
@export var default_spawn: String = "PlayerSpawn"
@export_file("*.ogg", "*.mp3", "*.wav") var bgm_path: String = ""

@export_group("Map Settings")
@export var camera_bounds: Rect2 = Rect2(0, 0, 1920, 1080)
@export var gravity_multiplier: float = 1.0

## Node references
@onready var tilemaps: Node2D = $TileMaps
@onready var map_objects: Node2D = $MapObjects
@onready var spawn_points: Node2D = $MapObjects/SpawnPoints
@onready var entities: Node2D = $Entities


func _ready() -> void:
	_initialize_map()
	_spawn_entities()


## Initialize map settings
func _initialize_map() -> void:
	_setup_world_grid()
	_setup_camera_bounds()
	_setup_physics()
	_play_bgm()

	print("Map initialized: ", map_name, " (", map_id, ")")


## Initialize WorldGrid from the map's terrain TileMapLayer
func _setup_world_grid() -> void:
	if not GameManager or not GameManager.WorldGridService:
		push_warning("WorldGrid service not available")
		return
	var terrain_layer = tilemaps.get_node_or_null("TileMapLayer")
	if terrain_layer and terrain_layer is TileMapLayer:
		GameManager.WorldGridService.load_from_tilemap(terrain_layer)
	else:
		push_warning("BaseMap: No TileMapLayer found under TileMaps node")


## Set up camera bounds
func _setup_camera_bounds() -> void:
	# Use CameraService if available
	if GameManager and GameManager.CameraService:
		GameManager.CameraService.set_camera_bounds(camera_bounds)
		print("Camera bounds set via CameraService: ", camera_bounds)
	else:
		# Fallback to direct camera manipulation
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.limit_left = int(camera_bounds.position.x)
			camera.limit_top = int(camera_bounds.position.y)
			camera.limit_right = int(camera_bounds.end.x)
			camera.limit_bottom = int(camera_bounds.end.y)
			print("Camera bounds set (direct): ", camera_bounds)


## Set up physics settings
func _setup_physics() -> void:
	if gravity_multiplier != 1.0:
		var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		PhysicsServer2D.area_set_param(
			get_viewport().find_world_2d().space,
			PhysicsServer2D.AREA_PARAM_GRAVITY,
			default_gravity * gravity_multiplier
		)


## Play background music
func _play_bgm() -> void:
	if not bgm_path.is_empty():
		# TODO: Integrate with AudioService when available
		print("BGM: ", bgm_path, " (AudioService integration pending)")


## Spawn entities at marked positions
func _spawn_entities() -> void:
	# Override in child classes to spawn enemies, collectibles, etc.
	pass


## Get spawn point position by name
func get_spawn_point(spawn_name: String = "") -> Vector2:
	var target = spawn_name if spawn_name != "" else default_spawn
	var spawn = spawn_points.get_node_or_null(target)

	if spawn == null:
		push_warning("Spawn point not found: ", target, ", using (0, 0)")
		return Vector2.ZERO

	return spawn.global_position


## Spawn a scene at a specific spawn point
func spawn_at_point(scene, spawn_name: String = "") -> Node:
	var spawn_pos = get_spawn_point(spawn_name)

	# Load scene if path string provided
	var scene_to_spawn: PackedScene = null
	if scene is String:
		scene_to_spawn = load(scene)
	elif scene is PackedScene:
		scene_to_spawn = scene
	else:
		push_error("spawn_at_point: scene must be PackedScene or String path")
		return null

	if scene_to_spawn == null:
		push_error("Failed to load scene for spawning")
		return null

	# Instance the scene
	var instance = scene_to_spawn.instantiate()

	# Set position if Node2D
	if instance is Node2D:
		instance.global_position = spawn_pos
	elif instance is Node3D:
		instance.global_position = Vector3(spawn_pos.x, 0, spawn_pos.y)

	# Add to entities node
	entities.add_child(instance)

	return instance
