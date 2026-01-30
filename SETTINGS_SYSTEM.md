# Settings System Documentation

## Overview

The SettingsService provides a complete player settings management system with:
- ✅ **Automatic persistence** - Settings saved to JSON file
- ✅ **Default creation** - Auto-creates settings on first launch
- ✅ **Runtime modification** - Change settings during gameplay
- ✅ **Signal-based** - React to setting changes
- ✅ **Auto-apply** - Settings automatically applied to engine

## Architecture

### Components

**PlayerSettings** (`src/scripts/resource/player_settings.gd`)
- Resource class containing all settings data
- Serializes to/from JSON
- Organized in categories (Audio, Video, Graphics, etc.)

**SettingsService** (`src/scripts/service/settings_service.gd`)
- Manages settings lifecycle
- Handles file I/O
- Applies settings to Godot engine
- Provides API for runtime modification

## Settings Categories

### Audio
- `master_volume` (0.0 - 1.0) - Master volume level
- `music_volume` (0.0 - 1.0) - Music volume level
- `sfx_volume` (0.0 - 1.0) - Sound effects volume level

### Video
- `window_mode` (0=Windowed, 1=Fullscreen, 2=Borderless)
- `resolution_width` - Window width in pixels
- `resolution_height` - Window height in pixels
- `vsync_enabled` - VSync on/off
- `fps_limit` - FPS cap (0 = unlimited)

### Graphics
- `graphics_quality` (0=Low, 1=Medium, 2=High, 3=Ultra)
- `antialiasing` - Anti-aliasing enabled
- `shadow_quality` (0=Off, 1=Low, 2=Medium, 3=High)

### Gameplay
- `mouse_sensitivity` (0.1 - 2.0) - Mouse sensitivity multiplier
- `camera_shake` - Camera shake enabled
- `show_fps` - Show FPS counter
- `tutorials_enabled` - Enable tutorial hints

### Accessibility
- `colorblind_mode` (0=None, 1=Protanopia, 2=Deuteranopia, 3=Tritanopia)
- `text_scale` (0.5 - 2.0) - Text size multiplier
- `screen_shake_intensity` (0.0 - 1.0) - Screen shake strength

### Localization
- `language` - Language code (e.g., "en", "es", "fr")

## Usage

### Accessing Settings

```gdscript
# Get the current settings object
var settings = GameManager.SettingsService.get_settings()

# Read a specific value
var volume = settings.master_volume
var sensitivity = settings.mouse_sensitivity
```

### Modifying Settings

**Method 1: Direct Setter Methods (Recommended)**
```gdscript
# Audio
GameManager.SettingsService.set_master_volume(0.8)
GameManager.SettingsService.set_music_volume(0.6)
GameManager.SettingsService.set_sfx_volume(1.0)

# Video
GameManager.SettingsService.set_window_mode(1)  # Fullscreen
GameManager.SettingsService.set_resolution(1920, 1080)
GameManager.SettingsService.set_vsync(true)

# Graphics
GameManager.SettingsService.set_graphics_quality(2)  # High

# Gameplay
GameManager.SettingsService.set_mouse_sensitivity(1.5)
```

**Method 2: Generic Setter**
```gdscript
# Category and key-based setting
GameManager.SettingsService.set_setting("audio", "master_volume", 0.8)
GameManager.SettingsService.set_setting("video", "window_mode", 1)
GameManager.SettingsService.set_setting("gameplay", "mouse_sensitivity", 1.5)

# Save immediately
GameManager.SettingsService.set_setting("audio", "master_volume", 0.8, true)
```

### Saving Settings

```gdscript
# Save current settings to disk
GameManager.SettingsService.save()

# Settings are auto-saved when using setter methods with save_immediately=true
GameManager.SettingsService.set_setting("audio", "master_volume", 0.8, true)
```

### Resetting to Defaults

```gdscript
# Reset all settings to default values
GameManager.SettingsService.reset_to_defaults()
```

## Signals

Connect to signals to react to setting changes:

```gdscript
func _ready():
	# Listen for any setting change
	GameManager.SettingsService.settings_changed.connect(_on_settings_changed)

	# Listen for specific category changes
	GameManager.SettingsService.audio_settings_changed.connect(_on_audio_changed)
	GameManager.SettingsService.video_settings_changed.connect(_on_video_changed)
	GameManager.SettingsService.graphics_settings_changed.connect(_on_graphics_changed)

func _on_settings_changed(settings: PlayerSettings):
	print("Settings changed!")
	# Update UI, etc.

func _on_audio_changed(master: float, music: float, sfx: float):
	print("Audio settings changed: ", master, music, sfx)
	# Update audio UI sliders

func _on_video_changed():
	print("Video settings changed")
	# Update video options UI

func _on_graphics_changed():
	print("Graphics settings changed")
	# Update graphics options UI
```

## Example: Settings Menu

### Settings Menu Script

```gdscript
# settings_menu.gd
extends Control

@onready var master_slider: HSlider = $Audio/MasterSlider
@onready var music_slider: HSlider = $Audio/MusicSlider
@onready var sfx_slider: HSlider = $Audio/SFXSlider
@onready var fullscreen_checkbox: CheckBox = $Video/FullscreenCheck
@onready var vsync_checkbox: CheckBox = $Video/VsyncCheck

func _ready():
	_load_current_settings()
	_connect_signals()

func _load_current_settings():
	var settings = GameManager.SettingsService.get_settings()

	# Load audio settings
	master_slider.value = settings.master_volume
	music_slider.value = settings.music_volume
	sfx_slider.value = settings.sfx_volume

	# Load video settings
	fullscreen_checkbox.button_pressed = (settings.window_mode == 1)
	vsync_checkbox.button_pressed = settings.vsync_enabled

func _connect_signals():
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)

func _on_master_volume_changed(value: float):
	GameManager.SettingsService.set_master_volume(value)

func _on_music_volume_changed(value: float):
	GameManager.SettingsService.set_music_volume(value)

func _on_sfx_volume_changed(value: float):
	GameManager.SettingsService.set_sfx_volume(value)

func _on_fullscreen_toggled(enabled: bool):
	GameManager.SettingsService.set_window_mode(1 if enabled else 0)

func _on_vsync_toggled(enabled: bool):
	GameManager.SettingsService.set_vsync(enabled)

func _on_save_button_pressed():
	GameManager.SettingsService.save()
	print("Settings saved!")

func _on_reset_button_pressed():
	GameManager.SettingsService.reset_to_defaults()
	_load_current_settings()  # Refresh UI
```

## File Storage

Settings are stored in:
- **Path**: `user://settings.json`
- **Format**: JSON (human-readable)
- **Location** (varies by platform):
  - **Windows**: `%APPDATA%\Godot\app_userdata\[ProjectName]\settings.json`
  - **Linux**: `~/.local/share/godot/app_userdata/[ProjectName]/settings.json`
  - **macOS**: `~/Library/Application Support/Godot/app_userdata/[ProjectName]/settings.json`

### Example settings.json

```json
{
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0
	},
	"video": {
		"window_mode": 0,
		"resolution_width": 1920,
		"resolution_height": 1080,
		"vsync_enabled": true,
		"fps_limit": 60
	},
	"graphics": {
		"graphics_quality": 2,
		"antialiasing": true,
		"shadow_quality": 2
	},
	"gameplay": {
		"mouse_sensitivity": 1.0,
		"camera_shake": true,
		"show_fps": false,
		"tutorials_enabled": true
	},
	"accessibility": {
		"colorblind_mode": 0,
		"text_scale": 1.0,
		"screen_shake_intensity": 1.0
	},
	"localization": {
		"language": "en"
	}
}
```

## How It Works

### Startup Flow

```
Game Starts
	↓
GameManager._ready()
	↓
SettingsService.load()
	↓
Check if settings.json exists
	├─ YES → Load from file
	│         Parse JSON
	│         Create PlayerSettings
	│         Apply to engine
	│
	└─ NO  → Create default settings
			  Apply to engine
			  Save to disk
```

### Modification Flow

```
User changes setting
	↓
Call setter method
(e.g., set_master_volume(0.8))
	↓
Update settings object
	↓
Apply to engine immediately
(e.g., set AudioServer volume)
	↓
Emit signal
(notify listeners)
	↓
Save to disk
(optional, can be deferred)
```

## Advanced Usage

### Accessing Settings in Gameplay

```gdscript
# In player controller
func _process(delta):
	var settings = GameManager.SettingsService.get_settings()

	# Use mouse sensitivity
	var mouse_delta = Input.get_last_mouse_velocity()
	var adjusted_delta = mouse_delta * settings.mouse_sensitivity

	# Check if camera shake enabled
	if settings.camera_shake:
		apply_camera_shake()
```

### Temporary Settings Preview

```gdscript
# Preview a setting without saving
var original_volume = GameManager.SettingsService.get_settings().master_volume

# Change temporarily
GameManager.SettingsService.set_master_volume(0.5)

# User testing...

# Restore or save
if user_confirms:
	GameManager.SettingsService.save()
else:
	GameManager.SettingsService.set_master_volume(original_volume)
```

### Batch Settings Update

```gdscript
# Update multiple settings without saving each time
var settings = GameManager.SettingsService.get_settings()
settings.master_volume = 0.8
settings.music_volume = 0.6
settings.sfx_volume = 1.0

# Apply and save once
GameManager.SettingsService.apply_settings()
GameManager.SettingsService.save()
```

## Adding New Settings

### Step 1: Add to PlayerSettings

```gdscript
# In player_settings.gd
@export_group("MyCategory")
@export var my_new_setting: bool = true
```

### Step 2: Update to_dict()

```gdscript
func to_dict() -> Dictionary:
	return {
		# ... existing categories ...
		"my_category": {
			"my_new_setting": my_new_setting
		}
	}
```

### Step 3: Update from_dict()

```gdscript
func from_dict(data: Dictionary) -> void:
	# ... existing categories ...
	if data.has("my_category"):
		var my_cat = data.my_category
		my_new_setting = my_cat.get("my_new_setting", true)
```

### Step 4: Add Setter in SettingsService

```gdscript
func set_my_new_setting(value: bool) -> void:
	settings.my_new_setting = value
	# Apply if needed
```

### Step 5: Add to Category Helper

```gdscript
func _set_my_category_setting(key: String, value) -> void:
	match key:
		"my_new_setting":
			set_my_new_setting(value)
```

## Best Practices

1. **Always use setter methods** - They handle validation and application
2. **Save strategically** - Don't save after every single change
3. **Use signals** - Keep UI in sync with setting changes
4. **Validate inputs** - Settings use clamping for safety
5. **Test defaults** - Ensure first-launch experience is good
6. **Handle errors gracefully** - Settings system has fallbacks

## Troubleshooting

### Settings not persisting
- Check console for file write errors
- Verify `user://` path permissions
- Ensure `save()` is called

### Settings not applying
- Check `apply_settings()` is called after load
- Verify setting category helpers are implemented
- Check for engine-specific requirements (audio buses, etc.)

### JSON parse errors
- Delete `user://settings.json` to regenerate
- Check for manual file edits
- Verify JSON structure matches to_dict()

## Complete Example

See the implementation files:
- [src/scripts/resource/player_settings.gd](src/scripts/resource/player_settings.gd) - Settings data
- [src/scripts/service/settings_service.gd](src/scripts/service/settings_service.gd) - Settings service

Settings are automatically loaded on game start via GameManager!
