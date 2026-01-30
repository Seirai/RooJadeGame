# RooJadeGame

A Godot 4.5 game project with a service-based architecture.

## Project Structure

```
RooJadeGame/
├── addons/
│   └── guide/                       # GUIDE input system plugin
├── guide_examples/                  # Example scenes for GUIDE
├── src/
│   ├── scripts/
│   │   └── service/
│   │       ├── game_manager.gd      # Core service manager (Autoload)
│   │       ├── scene_service.gd     # Scene transition system
│   │       └── settings_service.gd  # Settings management
│   └── ui/
│       └── start_menu.tscn          # Main menu scene
└── project.godot
```

## Architecture

### GameManager (Autoload)
Central service container that initializes and manages all game services:
- **SettingsService**: Handles player settings persistence and runtime modification
- **SceneService**: Manages scene transitions with threaded loading

### SceneService
Provides scene management with:
- Background/threaded scene loading
- Progress tracking via signals
- Scene state management
- Simple API for scene transitions

### SettingsService
Provides settings management with:
- Automatic JSON persistence
- Default settings creation on first launch
- Runtime modification via API
- Signal-based change notifications
- Auto-application to engine (audio, video, graphics)

## Usage

### Scene Transitions

```gdscript
# Load a scene with background loading
GameManager.SceneService.change_scene("res://path/to/scene.tscn")

# Load a scene immediately (blocking)
GameManager.SceneService.change_scene_immediate("res://path/to/scene.tscn")

# Reload current scene
GameManager.SceneService.reload_current_scene()

# Get current scene info
var current_scene = GameManager.SceneService.get_current_scene()
var current_path = GameManager.SceneService.get_current_scene_path()
```

### Scene Loading Signals

```gdscript
func _ready():
    GameManager.SceneService.scene_load_started.connect(_on_load_started)
    GameManager.SceneService.scene_load_progress.connect(_on_load_progress)
    GameManager.SceneService.scene_load_completed.connect(_on_load_completed)
    GameManager.SceneService.scene_transition_finished.connect(_on_transition_finished)

func _on_load_started(scene_path: String):
    print("Loading: ", scene_path)

func _on_load_progress(progress: float):
    print("Progress: ", progress * 100, "%")

func _on_load_completed(scene_path: String):
    print("Loaded: ", scene_path)

func _on_transition_finished(scene_path: String):
    print("Transition complete: ", scene_path)
```

## Getting Started

1. **Open in Godot 4.5+**
2. **Run the project** (F5) - Opens start menu
3. **Add your game scenes** to `src/scenes/`
4. **Use SceneService** for scene transitions

## Service Architecture Benefits

- ✅ **Centralized Management**: All services accessible via GameManager
- ✅ **Clear Load Order**: Services initialize in defined sequence
- ✅ **Decoupled Systems**: Services can be modified independently
- ✅ **Easy to Extend**: Add new services to GameManager as needed
- ✅ **Persistent State**: GameManager persists across scene changes

## Adding New Services

To add a new service:

1. Create service script in `src/scripts/service/`
2. Add to GameManager:
```gdscript
# In game_manager.gd
const my_service = preload("res://src/scripts/service/my_service.gd")
var MyService: my_service

func _ready():
    MyService = my_service.new()
    add_child(MyService)
    # Initialize service
```

3. Access from anywhere:
```gdscript
GameManager.MyService.do_something()
```

## Input System (GUIDE)

This project uses **GUIDE (Godot Unified Input Detection Engine)** for advanced input handling.

### Features
- Context-based input mapping (gameplay, menus, etc.)
- Multi-device support (keyboard, gamepad, touch)
- Dynamic remapping
- Action-based input system

### Quick Start
See **[GUIDE_QUICK_REFERENCE.md](GUIDE_QUICK_REFERENCE.md)** for quick setup.
See **[GUIDE_USAGE.md](GUIDE_USAGE.md)** for complete documentation.

### Examples
Working examples available in `guide_examples/` folder:
- `quick_start/` - Basic usage
- `input_contexts/` - Context switching
- `remapping/` - Runtime control remapping
- `combos/` - Combo system

## Requirements

- Godot 4.5 or later
- GUIDE input plugin (included in addons/)

## Documentation

- **[README.md](README.md)** - This file, project overview
- **[SETTINGS_SYSTEM.md](SETTINGS_SYSTEM.md)** - Settings system documentation
- **[GUIDE_USAGE.md](GUIDE_USAGE.md)** - Complete GUIDE documentation
- **[GUIDE_QUICK_REFERENCE.md](GUIDE_QUICK_REFERENCE.md)** - Quick reference card

## License

[Add your license here]
