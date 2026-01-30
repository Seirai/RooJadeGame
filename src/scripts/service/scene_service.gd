extends Node
## Manages scene transitions.
##
## Provides simple scene loading with progress tracking.
## Integrates with GameManager for state persistence.
##

## Emitted when scene loading starts
signal scene_load_started(scene_path: String)
## Emitted during loading with progress (0.0 to 1.0)
signal scene_load_progress(progress: float)
## Emitted when scene loading completes
signal scene_load_completed(scene_path: String)
## Emitted when scene transition finishes
signal scene_transition_finished(scene_path: String)

## Reference to the current active scene
var current_scene: Node = null

## Path to the current scene
var current_scene_path: String = ""

## Loading state tracking
var _is_loading: bool = false

## Background loading status
var _load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
var _scene_being_loaded: String = ""


func _ready() -> void:
	# Capture the initial scene as current_scene
	var root = get_tree().root
	if root.get_child_count() > 0:
		# Last child is typically the main scene
		current_scene = root.get_child(root.get_child_count() - 1)
		if current_scene:
			current_scene_path = current_scene.scene_file_path


func _process(_delta: float) -> void:
	# Poll loading status if we're loading in background
	if _is_loading and _scene_being_loaded != "":
		_load_status = ResourceLoader.load_threaded_get_status(_scene_being_loaded)

		match _load_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Get loading progress
				var progress_array: Array = []
				ResourceLoader.load_threaded_get_status(_scene_being_loaded, progress_array)
				if progress_array.size() > 0:
					scene_load_progress.emit(progress_array[0])

			ResourceLoader.THREAD_LOAD_LOADED:
				# Loading complete
				_on_scene_loaded()

			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				# Loading failed
				push_error("Failed to load scene: " + _scene_being_loaded)
				_cleanup_loading()


## Changes to a new scene with background loading
## @param scene_path: Path to the scene file to load
func change_scene(scene_path: String) -> void:
	if _is_loading:
		push_warning("Scene is already loading. Ignoring request.")
		return

	if scene_path == current_scene_path:
		push_warning("Requested scene is already loaded.")
		return

	_is_loading = true
	_scene_being_loaded = scene_path

	scene_load_started.emit(scene_path)

	# Start threaded loading
	var error = ResourceLoader.load_threaded_request(scene_path)
	if error != OK:
		push_error("Failed to start loading scene: " + scene_path)
		_cleanup_loading()


## Changes to a new scene immediately (blocking)
## @param scene_path: Path to the scene file to load
func change_scene_immediate(scene_path: String) -> void:
	if _is_loading:
		push_warning("Scene is already loading. Ignoring request.")
		return

	scene_load_started.emit(scene_path)

	var new_scene_resource = load(scene_path)
	if new_scene_resource == null:
		push_error("Failed to load scene: " + scene_path)
		return

	_swap_scene(new_scene_resource, scene_path)
	scene_load_completed.emit(scene_path)
	scene_transition_finished.emit(scene_path)


## Reloads the current scene
func reload_current_scene() -> void:
	if current_scene_path != "":
		change_scene(current_scene_path)
	else:
		push_warning("No current scene to reload")


## Gets the current scene node
func get_current_scene() -> Node:
	return current_scene


## Gets the current scene path
func get_current_scene_path() -> String:
	return current_scene_path


## Checks if a scene is currently being loaded
func is_loading() -> bool:
	return _is_loading


## Called when background loading completes
func _on_scene_loaded() -> void:
	var loaded_resource = ResourceLoader.load_threaded_get(_scene_being_loaded)

	if loaded_resource == null:
		push_error("Failed to retrieve loaded scene: " + _scene_being_loaded)
		_cleanup_loading()
		return

	# Swap the scene
	var scene_path = _scene_being_loaded
	_swap_scene(loaded_resource, scene_path)

	scene_load_completed.emit(scene_path)
	_cleanup_loading()
	scene_transition_finished.emit(scene_path)


## Swaps the current scene with a new one
func _swap_scene(new_scene_resource: PackedScene, scene_path: String) -> void:
	# Remove old scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# Instance and add new scene
	var new_scene = new_scene_resource.instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	current_scene = new_scene
	current_scene_path = scene_path


## Cleans up loading state
func _cleanup_loading() -> void:
	_is_loading = false
	_scene_being_loaded = ""
	_load_status = ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
