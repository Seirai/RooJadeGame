extends Node 
## Manages core game services.
## 
## Determines load order, minimizes need to have autoload manage several services.
## Also loads in game configuration and consts.
##

const settings_service = preload("res://src/scripts/service/settings_service.gd")
const scene_service = preload("res://src/scripts/service/scene_service.gd")
const mob_service = preload("res://src/scripts/service/mob_service.gd")
const camera_service = preload("res://src/scripts/service/camera_service.gd")
const item_service = preload("res://src/scripts/service/item_service.gd")
const world_grid_service = preload("res://src/scripts/service/world_grid.gd")

var SettingsService: settings_service
var SceneService: scene_service
var MobService: mob_service
var CameraService: camera_service
var ItemService: item_service
var WorldGridService: world_grid_service

## Multiplier applied to all time-based gameplay durations (scouting, building, etc.).
## 1.0 = real-game speed. Increased by the DevConsole in debug builds.
var debug_speed: float = 1.0



func _ready() -> void:
	# Initialize game services in desired order
	SettingsService = settings_service.new()
	add_child(SettingsService)
	# Load local settings data
	SettingsService.load()

	# Initialize scene service
	SceneService = scene_service.new()
	add_child(SceneService)

	# Initialize mob service
	MobService = mob_service.new()
	add_child(MobService)

	# Initialize camera service
	CameraService = camera_service.new()
	add_child(CameraService)

	# Initialize item service
	ItemService = item_service.new()
	add_child(ItemService)

	# Initialize world grid service
	WorldGridService = world_grid_service.new()
	add_child(WorldGridService)

	_maybe_init_dev_console()


## Instantiate the dev console in debug builds only.
## Uses load() so no static reference to the scene survives a production export.
## Strip from builds via Export > Resources > Filters to Exclude:
##   src/scenes/components/debug/*
func _maybe_init_dev_console() -> void:
	const PATH = "res://src/scenes/components/debug/dev_console.tscn"
	if not OS.is_debug_build():
		return
	if not ResourceLoader.exists(PATH):
		return
	var scene := load(PATH) as PackedScene
	if scene:
		add_child(scene.instantiate())
	# Start debug builds at 60× speed so timed actions complete in seconds.
	debug_speed = 60.0