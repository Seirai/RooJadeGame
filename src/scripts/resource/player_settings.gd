extends Resource
class_name PlayerSettings
## Player settings data that can be saved and loaded.
##
## Contains all configurable game settings that persist between sessions.
## Can be serialized to JSON for saving to disk.

## Audio settings
@export_group("Audio")
## Master volume (0.0 to 1.0)
@export_range(0.0, 1.0) var master_volume: float = 1.0
## Music volume (0.0 to 1.0)
@export_range(0.0, 1.0) var music_volume: float = 0.8
## SFX volume (0.0 to 1.0)
@export_range(0.0, 1.0) var sfx_volume: float = 1.0

## Video settings
@export_group("Video")
## Window mode (0=Windowed, 1=Fullscreen, 2=Borderless)
@export_enum("Windowed", "Fullscreen", "Borderless") var window_mode: int = 0
## Resolution width
@export var resolution_width: int = 1067
## Resolution height
@export var resolution_height: int = 600
## VSync enabled
@export var vsync_enabled: bool = true
## FPS limit (0 = unlimited)
@export var fps_limit: int = 60

## Graphics settings
@export_group("Graphics")
## Graphics quality (0=Low, 1=Medium, 2=High, 3=Ultra)
@export_enum("Low", "Medium", "High", "Ultra") var graphics_quality: int = 2
## Anti-aliasing enabled
@export var antialiasing: bool = true
## Shadow quality (0=Off, 1=Low, 2=Medium, 3=High)
@export_enum("Off", "Low", "Medium", "High") var shadow_quality: int = 2

## Gameplay settings
@export_group("Gameplay")
## Mouse sensitivity (0.1 to 2.0)
@export_range(0.1, 2.0) var mouse_sensitivity: float = 1.0
## Camera shake enabled
@export var camera_shake: bool = true
## Show FPS counter
@export var show_fps: bool = false
## Enable tutorials
@export var tutorials_enabled: bool = true

## Accessibility settings
@export_group("Accessibility")
## Colorblind mode (0=None, 1=Protanopia, 2=Deuteranopia, 3=Tritanopia)
@export_enum("None", "Protanopia", "Deuteranopia", "Tritanopia") var colorblind_mode: int = 0
## Text size multiplier
@export_range(0.5, 2.0) var text_scale: float = 1.0
## Screen shake intensity (0.0 to 1.0)
@export_range(0.0, 1.0) var screen_shake_intensity: float = 1.0

## Language/Locale
@export_group("Localization")
## Current language code (e.g., "en", "es", "fr")
@export var language: String = "en"


## Converts settings to a dictionary for JSON serialization
func to_dict() -> Dictionary:
	return {
		"audio": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume
		},
		"video": {
			"window_mode": window_mode,
			"resolution_width": resolution_width,
			"resolution_height": resolution_height,
			"vsync_enabled": vsync_enabled,
			"fps_limit": fps_limit
		},
		"graphics": {
			"graphics_quality": graphics_quality,
			"antialiasing": antialiasing,
			"shadow_quality": shadow_quality
		},
		"gameplay": {
			"mouse_sensitivity": mouse_sensitivity,
			"camera_shake": camera_shake,
			"show_fps": show_fps,
			"tutorials_enabled": tutorials_enabled
		},
		"accessibility": {
			"colorblind_mode": colorblind_mode,
			"text_scale": text_scale,
			"screen_shake_intensity": screen_shake_intensity
		},
		"localization": {
			"language": language
		}
	}


## Loads settings from a dictionary
func from_dict(data: Dictionary) -> void:
	# Audio
	if data.has("audio"):
		var audio = data.audio
		master_volume = audio.get("master_volume", 1.0)
		music_volume = audio.get("music_volume", 0.8)
		sfx_volume = audio.get("sfx_volume", 1.0)

	# Video
	if data.has("video"):
		var video = data.video
		window_mode = video.get("window_mode", 0)
		resolution_width = video.get("resolution_width", 1920)
		resolution_height = video.get("resolution_height", 1080)
		vsync_enabled = video.get("vsync_enabled", true)
		fps_limit = video.get("fps_limit", 60)

	# Graphics
	if data.has("graphics"):
		var graphics = data.graphics
		graphics_quality = graphics.get("graphics_quality", 2)
		antialiasing = graphics.get("antialiasing", true)
		shadow_quality = graphics.get("shadow_quality", 2)

	# Gameplay
	if data.has("gameplay"):
		var gameplay = data.gameplay
		mouse_sensitivity = gameplay.get("mouse_sensitivity", 1.0)
		camera_shake = gameplay.get("camera_shake", true)
		show_fps = gameplay.get("show_fps", false)
		tutorials_enabled = gameplay.get("tutorials_enabled", true)

	# Accessibility
	if data.has("accessibility"):
		var accessibility = data.accessibility
		colorblind_mode = accessibility.get("colorblind_mode", 0)
		text_scale = accessibility.get("text_scale", 1.0)
		screen_shake_intensity = accessibility.get("screen_shake_intensity", 1.0)

	# Localization
	if data.has("localization"):
		var localization = data.localization
		language = localization.get("language", "en")


## Creates a copy of this settings object
func duplicate_settings() -> PlayerSettings:
	var copy = PlayerSettings.new()
	copy.from_dict(to_dict())
	return copy
