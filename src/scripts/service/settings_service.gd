extends Node
## Manages player settings persistence and runtime modification.
##
## Handles loading, saving, and applying game settings. Settings are stored
## in JSON format in the user data directory. Provides signals for settings
## changes so other systems can react.

const PlayerSettings = preload("res://src/scripts/resource/player_settings.gd")

## Emitted when any setting changes
signal settings_changed(settings: PlayerSettings)
## Emitted when audio settings change
signal audio_settings_changed(master: float, music: float, sfx: float)
## Emitted when video settings change
signal video_settings_changed()
## Emitted when graphics settings change
signal graphics_settings_changed()

## Path where settings are saved
const SETTINGS_PATH = "user://settings.json"

## Current player settings
var settings: PlayerSettings = null


func _ready() -> void:
	# Settings are loaded by GameManager via load()
	pass


## Loads settings from disk or creates default if none exist
## @return: true if loaded successfully, false otherwise
func load() -> bool:
	if FileAccess.file_exists(SETTINGS_PATH):
		return _load_from_file()
	else:
		_create_default_settings()
		save()  # Save the defaults
		return true


## Saves current settings to disk
## @return: true if saved successfully, false otherwise
func save() -> bool:
	if settings == null:
		push_error("Cannot save: settings is null")
		return false

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open settings file for writing: " + SETTINGS_PATH)
		return false

	var settings_dict = settings.to_dict()
	var json_string = JSON.stringify(settings_dict, "\t")
	file.store_string(json_string)
	file.close()

	print("Settings saved to: ", SETTINGS_PATH)
	return true


## Applies all settings to the game engine
func apply_settings() -> void:
	if settings == null:
		push_warning("Cannot apply settings: settings is null")
		return

	_apply_audio_settings()
	_apply_video_settings()
	_apply_graphics_settings()
	_apply_gameplay_settings()

	settings_changed.emit(settings)


## Gets the current settings
## @return: Current PlayerSettings instance
func get_settings() -> PlayerSettings:
	return settings


## Updates a specific setting and optionally saves
## @param category: Settings category (e.g., "audio", "video")
## @param key: Setting key (e.g., "master_volume")
## @param value: New value for the setting
## @param save_immediately: Whether to save to disk immediately
func set_setting(category: String, key: String, value, save_immediately: bool = false) -> void:
	if settings == null:
		push_error("Cannot set setting: settings is null")
		return

	match category:
		"audio":
			_set_audio_setting(key, value)
		"video":
			_set_video_setting(key, value)
		"graphics":
			_set_graphics_setting(key, value)
		"gameplay":
			_set_gameplay_setting(key, value)
		"accessibility":
			_set_accessibility_setting(key, value)
		"localization":
			_set_localization_setting(key, value)
		_:
			push_error("Unknown settings category: " + category)
			return

	if save_immediately:
		save()

	settings_changed.emit(settings)


## Resets all settings to defaults
func reset_to_defaults() -> void:
	_create_default_settings()
	apply_settings()
	save()


## Audio Settings Methods

## Sets master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	settings.master_volume = clamp(volume, 0.0, 1.0)
	_apply_audio_settings()
	audio_settings_changed.emit(settings.master_volume, settings.music_volume, settings.sfx_volume)


## Sets music volume (0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	settings.music_volume = clamp(volume, 0.0, 1.0)
	_apply_audio_settings()
	audio_settings_changed.emit(settings.master_volume, settings.music_volume, settings.sfx_volume)


## Sets SFX volume (0.0 to 1.0)
func set_sfx_volume(volume: float) -> void:
	settings.sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_audio_settings()
	audio_settings_changed.emit(settings.master_volume, settings.music_volume, settings.sfx_volume)


## Video Settings Methods

## Sets window mode (0=Windowed, 1=Fullscreen, 2=Borderless)
func set_window_mode(mode: int) -> void:
	settings.window_mode = mode
	_apply_video_settings()
	video_settings_changed.emit()


## Sets resolution
func set_resolution(width: int, height: int) -> void:
	settings.resolution_width = width
	settings.resolution_height = height
	_apply_video_settings()
	video_settings_changed.emit()


## Sets VSync enabled
func set_vsync(enabled: bool) -> void:
	settings.vsync_enabled = enabled
	_apply_video_settings()
	video_settings_changed.emit()


## Graphics Settings Methods

## Sets graphics quality (0=Low, 1=Medium, 2=High, 3=Ultra)
func set_graphics_quality(quality: int) -> void:
	settings.graphics_quality = clamp(quality, 0, 3)
	_apply_graphics_settings()
	graphics_settings_changed.emit()


## Gameplay Settings Methods

## Sets mouse sensitivity (0.1 to 2.0)
func set_mouse_sensitivity(sensitivity: float) -> void:
	settings.mouse_sensitivity = clamp(sensitivity, 0.1, 2.0)


## Private Methods

## Loads settings from file
func _load_from_file() -> bool:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open settings file: " + SETTINGS_PATH)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse settings JSON: " + json.get_error_message())
		_create_default_settings()
		return false

	settings = PlayerSettings.new()
	settings.from_dict(json.data)

	print("Settings loaded from: ", SETTINGS_PATH)
	apply_settings()
	return true


## Creates default settings
func _create_default_settings() -> void:
	settings = PlayerSettings.new()
	print("Created default settings")
	apply_settings()


## Applies audio settings to the engine
func _apply_audio_settings() -> void:
	var master_bus_idx = AudioServer.get_bus_index("Master")

	if master_bus_idx != -1:
		var db = linear_to_db(settings.master_volume)
		AudioServer.set_bus_volume_db(master_bus_idx, db)


## Applies video settings to the engine
func _apply_video_settings() -> void:
	var window = get_window()
	if not window:
		return

	match settings.window_mode:
		0:  # Windowed
			window.mode = Window.MODE_WINDOWED
		1:  # Fullscreen
			window.mode = Window.MODE_FULLSCREEN
		2:  # Borderless
			window.mode = Window.MODE_FULLSCREEN
			window.borderless = true

	if settings.window_mode == 0:
		#window.size = Vector2i(settings.resolution_width, settings.resolution_height)
		pass

	if settings.vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	if settings.fps_limit > 0:
		Engine.max_fps = settings.fps_limit
	else:
		Engine.max_fps = 0


## Applies graphics settings to the engine
func _apply_graphics_settings() -> void:
	if settings.antialiasing:
		get_viewport().msaa_3d = Viewport.MSAA_2X
	else:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED


## Applies gameplay settings
func _apply_gameplay_settings() -> void:
	pass


## Setting category helpers

func _set_audio_setting(key: String, value) -> void:
	match key:
		"master_volume":
			set_master_volume(value)
		"music_volume":
			set_music_volume(value)
		"sfx_volume":
			set_sfx_volume(value)


func _set_video_setting(key: String, value) -> void:
	match key:
		"window_mode":
			set_window_mode(value)
		"vsync_enabled":
			set_vsync(value)
		"resolution_width", "resolution_height":
			set_resolution(settings.resolution_width, settings.resolution_height)


func _set_graphics_setting(key: String, value) -> void:
	match key:
		"graphics_quality":
			set_graphics_quality(value)
		"antialiasing":
			settings.antialiasing = value
			_apply_graphics_settings()


func _set_gameplay_setting(key: String, value) -> void:
	match key:
		"mouse_sensitivity":
			set_mouse_sensitivity(value)
		"camera_shake":
			settings.camera_shake = value
		"show_fps":
			settings.show_fps = value
		"tutorials_enabled":
			settings.tutorials_enabled = value


func _set_accessibility_setting(key: String, value) -> void:
	match key:
		"colorblind_mode":
			settings.colorblind_mode = value
		"text_scale":
			settings.text_scale = value
		"screen_shake_intensity":
			settings.screen_shake_intensity = value


func _set_localization_setting(key: String, value) -> void:
	match key:
		"language":
			settings.language = value


## Helper: Convert linear volume (0-1) to decibels
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
