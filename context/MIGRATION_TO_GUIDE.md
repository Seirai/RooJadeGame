# Migration to GUIDE Input System

## What Changed

The project has migrated from a custom action/input service system to **GUIDE (Godot Unified Input Detection Engine)**.

### Removed Services

The following deprecated services have been removed:

- ❌ `action_service.gd` - Replaced by GUIDE's action system
- ❌ `input_service.gd` - Replaced by GUIDE's input management
- ❌ `GameManager.actions` - No longer needed

### Current Services

Your project now has a clean, focused service architecture:

```
src/scripts/service/
├── game_manager.gd      # Service container
├── scene_service.gd     # Scene transitions
└── settings_service.gd  # Settings management
```

## Why GUIDE?

The old custom action system was incomplete (mostly commented out code). GUIDE provides:

✅ **Complete Implementation** - Fully functional input system
✅ **Context-Based** - Different controls for different game states
✅ **Multi-Device** - Keyboard, gamepad, touch support
✅ **Visual Editing** - Configure inputs in Godot Editor
✅ **Runtime Remapping** - Let players customize controls
✅ **Advanced Features** - Combos, holds, taps, chords
✅ **Well Documented** - Active community and examples

## Migration Guide

### Old System (Removed)

```gdscript
# DON'T USE - This is the old system
GameManager.ActionService.subscribe_to_action("jump", "pressed", false, _on_jump)
GameManager.InputService.load()
```

### New System (GUIDE)

**1. Create Action Resources:**
- Right-click → New Resource → `GUIDEAction`
- Save as `res://input/actions/jump_action.tres`

**2. Create Mapping Context:**
- Right-click → New Resource → `GUIDEMappingContext`
- Add action mappings in Inspector
- Save as `res://input/contexts/player_context.tres`

**3. Use in Code:**
```gdscript
@export var jump_action: GUIDEAction
@export var player_context: GUIDEMappingContext

func _ready():
    # Enable context
    GUIDE.enable_mapping_context(player_context)

    # Connect to action
    jump_action.triggered.connect(_on_jump)

func _on_jump():
    # Your jump logic
    pass
```

## Updated Architecture

### GameManager

Now only manages core services:

```gdscript
# game_manager.gd
extends Node

const settings_service = preload("res://src/scripts/service/settings_service.gd")
const scene_service = preload("res://src/scripts/service/scene_service.gd")

var SettingsService: settings_service
var SceneService: scene_service

func _ready():
    # Initialize services
    SettingsService = settings_service.new()
    add_child(SettingsService)
    SettingsService.load()

    SceneService = scene_service.new()
    add_child(SceneService)
```

### Input Handling

Now handled entirely by GUIDE autoload:

```gdscript
# Access GUIDE from anywhere (it's an autoload)
GUIDE.enable_mapping_context(my_context)
GUIDE.disable_mapping_context(my_context)
```

## Benefits of This Change

### 1. Cleaner Codebase
- Removed incomplete/commented code
- Clear separation of concerns
- Less code to maintain

### 2. More Powerful
- Professional input system
- Battle-tested in real games
- Active development and support

### 3. Better Development Experience
- Visual resource editing
- No manual input parsing
- Built-in debugging tools

### 4. Future-Proof
- Easy to add new inputs
- Support for new devices
- Community-driven updates

## Learning Resources

Your project now includes:

- **[GUIDE_USAGE.md](GUIDE_USAGE.md)** - Complete documentation
- **[GUIDE_QUICK_REFERENCE.md](GUIDE_QUICK_REFERENCE.md)** - Quick reference
- **guide_examples/** - Working examples

## Example: Converting Old Code

### Before (Old System - Incomplete)
```gdscript
# This was the intended design but was never completed
var ActionService = GameManager.ActionService
var actions = GameManager.actions

func _ready():
    ActionService.subscribe_to_action("move", "pressed", false, _on_move)
    ActionService.subscribe_to_action("jump", "pressed", false, _on_jump)
```

### After (GUIDE - Complete)
```gdscript
@export var move_action: GUIDEAction
@export var jump_action: GUIDEAction
@export var player_context: GUIDEMappingContext

func _ready():
    GUIDE.enable_mapping_context(player_context)
    jump_action.triggered.connect(_on_jump)

func _physics_process(delta):
    var move_input = move_action.value_axis_2d
    velocity = move_input * SPEED
```

## Project Status

✅ **Migration Complete**

Your project is now using GUIDE for all input handling. The old incomplete services have been removed, leaving a clean, focused architecture.

## Next Steps

1. ✅ Read [GUIDE_QUICK_REFERENCE.md](GUIDE_QUICK_REFERENCE.md)
2. ✅ Explore `guide_examples/quick_start/`
3. ✅ Create your first action and context
4. ✅ Start building your game with GUIDE!

No action required on your part - the migration is complete and your project is ready to use GUIDE!
