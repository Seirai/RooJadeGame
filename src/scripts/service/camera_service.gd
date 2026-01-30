extends Node
## Manages camera registration, switching, and behavior.
##
## Provides centralized camera management including:
## - Multiple camera registration with unique names
## - Easy switching between cameras
## - Follow target support for player cameras
## - Camera bounds enforcement

#region Signals

signal camera_changed(camera_name: String, camera: Camera2D)
signal camera_registered(camera_name: String)
signal camera_unregistered(camera_name: String)

#endregion

#region State

## Registered cameras by name
var _cameras: Dictionary = {}  # { "name": Camera2D }

## Currently active camera name
var _current_camera_name: String = ""

## Follow target for follow-mode cameras
var _follow_target: Node2D = null

## Follow smoothing factor (lower = smoother)
var follow_smoothness: float = 0.1

## Default camera zoom level (higher = more zoomed in)
var default_zoom: Vector2 = Vector2(2.0, 2.0)

#endregion

#region Lifecycle

func _physics_process(_delta: float) -> void:
	# Cleanup invalid cameras periodically
	cleanup_invalid_cameras()
	_update_follow_camera()

#endregion

#region Camera Registration

## Register a camera with a unique name
func register_camera(camera_name: String, camera: Camera2D) -> void:
	if _cameras.has(camera_name):
		push_warning("CameraService: Camera '%s' already registered, replacing." % camera_name)

	_cameras[camera_name] = camera

	# Apply default zoom to newly registered cameras
	camera.zoom = default_zoom

	camera_registered.emit(camera_name)
	print("CameraService: Registered camera '%s' with zoom %s" % [camera_name, default_zoom])

	# If no active camera, make this one active
	if _current_camera_name == "":
		switch_to(camera_name)


## Unregister a camera
func unregister_camera(camera_name: String) -> void:
	if not _cameras.has(camera_name):
		return

	var was_current = (_current_camera_name == camera_name)
	_cameras.erase(camera_name)
	camera_unregistered.emit(camera_name)
	print("CameraService: Unregistered camera '%s'" % camera_name)

	# If we removed the current camera, switch to another
	if was_current and _cameras.size() > 0:
		switch_to(_cameras.keys()[0])
	elif was_current:
		_current_camera_name = ""

#endregion

#region Camera Switching

## Switch to a camera by name
func switch_to(camera_name: String) -> bool:
	if not _cameras.has(camera_name):
		push_error("CameraService: Camera '%s' not found." % camera_name)
		return false

	var camera = _cameras[camera_name] as Camera2D
	# Check if camera was freed
	if not is_instance_valid(camera):
		_cameras.erase(camera_name)
		push_error("CameraService: Camera '%s' was freed." % camera_name)
		return false

	camera.make_current()  # Godot 4: use make_current() instead of setting .current
	_current_camera_name = camera_name
	camera_changed.emit(camera_name, camera)
	print("CameraService: Switched to camera '%s'" % camera_name)
	return true


## Get the current active camera
func get_current_camera() -> Camera2D:
	if _current_camera_name == "" or not _cameras.has(_current_camera_name):
		return null
	var camera = _cameras[_current_camera_name]
	# Check if camera was freed
	if not is_instance_valid(camera):
		_cameras.erase(_current_camera_name)
		_current_camera_name = ""
		return null
	return camera


## Get current camera name
func get_current_camera_name() -> String:
	return _current_camera_name


## Get all registered camera names
func get_camera_names() -> Array[String]:
	var names: Array[String] = []
	for key in _cameras.keys():
		names.append(key)
	return names


## Check if a camera is registered
func has_camera(camera_name: String) -> bool:
	return _cameras.has(camera_name)


## Remove all invalid (freed) cameras from registry
func cleanup_invalid_cameras() -> void:
	var to_remove: Array[String] = []
	for camera_name in _cameras.keys():
		if not is_instance_valid(_cameras[camera_name]):
			to_remove.append(camera_name)

	for camera_name in to_remove:
		_cameras.erase(camera_name)
		camera_unregistered.emit(camera_name)
		print("CameraService: Cleaned up invalid camera '%s'" % camera_name)

	# Clear current if it was removed
	if _current_camera_name != "" and not _cameras.has(_current_camera_name):
		_current_camera_name = ""
		# Switch to first available camera
		if _cameras.size() > 0:
			switch_to(_cameras.keys()[0])


## Clear all cameras (useful on scene change)
func clear_all_cameras() -> void:
	_cameras.clear()
	_current_camera_name = ""
	_follow_target = null
	print("CameraService: Cleared all cameras")

#endregion

#region Follow Target

## Set a follow target (for follow-mode cameras)
func set_follow_target(target: Node2D) -> void:
	_follow_target = target
	print("CameraService: Follow target set to '%s'" % (target.name if target else "null"))


## Clear the follow target
func clear_follow_target() -> void:
	_follow_target = null
	print("CameraService: Follow target cleared")


## Get the current follow target
func get_follow_target() -> Node2D:
	return _follow_target


## Update camera position to follow target
func _update_follow_camera() -> void:
	if _follow_target == null or _current_camera_name == "":
		return

	# Check if target is still valid
	if not is_instance_valid(_follow_target):
		_follow_target = null
		return

	var camera = get_current_camera()
	if camera == null:
		return

	# Only follow if camera is not a child of the target
	if camera.get_parent() != _follow_target:
		camera.global_position = camera.global_position.lerp(
			_follow_target.global_position,
			follow_smoothness
		)

#endregion

#region Camera Bounds

## Set camera bounds (limit rectangle)
func set_camera_bounds(bounds: Rect2, camera_name: String = "") -> void:
	var camera: Camera2D
	if camera_name == "":
		camera = get_current_camera()
	else:
		camera = _cameras.get(camera_name)

	if camera == null:
		push_warning("CameraService: Cannot set bounds, camera not found.")
		return

	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	print("CameraService: Set bounds for camera '%s': %s" % [camera_name if camera_name != "" else _current_camera_name, bounds])


## Clear camera bounds (set to very large values)
func clear_camera_bounds(camera_name: String = "") -> void:
	var camera: Camera2D
	if camera_name == "":
		camera = get_current_camera()
	else:
		camera = _cameras.get(camera_name)

	if camera == null:
		return

	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000


## Get current camera bounds as Rect2
func get_camera_bounds(camera_name: String = "") -> Rect2:
	var camera: Camera2D
	if camera_name == "":
		camera = get_current_camera()
	else:
		camera = _cameras.get(camera_name)

	if camera == null:
		return Rect2()

	return Rect2(
		camera.limit_left,
		camera.limit_top,
		camera.limit_right - camera.limit_left,
		camera.limit_bottom - camera.limit_top
	)

#endregion

#region Camera Zoom

## Set zoom for a specific camera or current camera
func set_zoom(zoom: Vector2, camera_name: String = "") -> void:
	var camera: Camera2D
	if camera_name == "":
		camera = get_current_camera()
	else:
		camera = _cameras.get(camera_name)

	if camera == null:
		push_warning("CameraService: Cannot set zoom, camera not found.")
		return

	camera.zoom = zoom
	print("CameraService: Set zoom for camera '%s': %s" % [camera_name if camera_name != "" else _current_camera_name, zoom])


## Get zoom for a specific camera or current camera
func get_zoom(camera_name: String = "") -> Vector2:
	var camera: Camera2D
	if camera_name == "":
		camera = get_current_camera()
	else:
		camera = _cameras.get(camera_name)

	if camera == null:
		return Vector2.ONE

	return camera.zoom


## Set the default zoom applied to new cameras
func set_default_zoom(zoom: Vector2) -> void:
	default_zoom = zoom

#endregion
