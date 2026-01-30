# GUIDE (Godot Unified Input Detection Engine) - Usage Guide

## Overview

**GUIDE** is an advanced input system for Godot that provides:
- **Context-based input mapping** - Different controls for different game states
- **Action-based input** - Define what actions do, not just which keys trigger them
- **Multi-input support** - Gamepad, keyboard, mouse, touch all work seamlessly
- **Dynamic remapping** - Change controls at runtime
- **Input modifiers & triggers** - Advanced input handling (hold, tap, combos, etc.)
- **Automatic UI prompts** - Shows correct input icons based on active device

## Core Concepts

### 1. Actions (GUIDEAction)
Actions represent **what the player can do** (move, jump, attack, etc.)

```gdscript
# Define in your script
@export var jump_action: GUIDEAction
@export var move_action: GUIDEAction
@export var attack_action: GUIDEAction
```

### 2. Mapping Contexts (GUIDEMappingContext)
Contexts define **which inputs trigger which actions** in different game states

Examples:
- `PlayerMovementContext` - Active during gameplay
- `MenuNavigationContext` - Active in menus
- `VehicleContext` - Active when driving
- `DialogueContext` - Active during conversations

### 3. Input Mappings (GUIDEInputMapping)
Mappings connect **physical inputs to actions** within a context

```
Context: PlayerMovement
├── Move Action → WASD, Left Stick
├── Jump Action → Space, A Button
└── Attack Action → Left Mouse, X Button
```

## Quick Start

### Step 1: Create Resources in Godot Editor

#### Create an Action Resource
1. Right-click in FileSystem → **New Resource**
2. Search for `GUIDEAction`
3. Save as `res://input/actions/jump_action.tres`
4. Configure in Inspector:
   - **Value Type**: Choose input type (Button, Axis1D, Axis2D, etc.)

#### Create a Mapping Context Resource
1. Right-click in FileSystem → **New Resource**
2. Search for `GUIDEMappingContext`
3. Save as `res://input/contexts/player_context.tres`
4. Add mappings in Inspector:
   - Click **Action Mappings** → Add Element
   - Assign your action resource
   - Add **Input Mappings** (keyboard, gamepad, etc.)

### Step 2: Enable Context in Your Scene

```gdscript
# game.gd
extends Node2D

@export var player_context: GUIDEMappingContext

func _ready():
    # Enable the context (priority 0 = highest)
    GUIDE.enable_mapping_context(player_context)
```

### Step 3: Use Actions in Your Player

```gdscript
# player.gd
extends CharacterBody2D

@export var move_action: GUIDEAction
@export var jump_action: GUIDEAction

func _ready():
    # Connect to action signals
    jump_action.triggered.connect(_on_jump)

func _physics_process(delta):
    # Get 2D movement from action
    var move_input = move_action.value_axis_2d
    velocity.x = move_input.x * SPEED

    move_and_slide()

func _on_jump():
    if is_on_floor():
        velocity.y = JUMP_VELOCITY
```

## Action Value Types

### Button (value_bool)
For on/off inputs (jump, shoot, interact)
```gdscript
if action.value_bool:
    shoot()
```

### Axis 1D (value_axis_1d)
For single-axis inputs (-1.0 to 1.0)
```gdscript
# Horizontal movement only
velocity.x = move_action.value_axis_1d * SPEED
```

### Axis 2D (value_axis_2d)
For two-axis inputs (movement, aiming)
```gdscript
# Full 2D movement
velocity = move_action.value_axis_2d * SPEED
```

### Axis 3D (value_axis_3d)
For 3D inputs (flight controls, 3D camera)
```gdscript
# 3D movement
velocity = move_action.value_axis_3d * SPEED
```

## Action Signals

Actions emit signals for different input events:

```gdscript
@export var action: GUIDEAction

func _ready():
    # Fired when action is first activated
    action.started.connect(_on_action_started)

    # Fired every frame while action is active
    action.ongoing.connect(_on_action_ongoing)

    # Fired when action completes (main signal to use)
    action.triggered.connect(_on_action_triggered)

    # Fired when action is canceled/released
    action.canceled.connect(_on_action_canceled)

    # Fired when action completes
    action.completed.connect(_on_action_completed)

func _on_action_triggered():
    print("Action triggered!")
```

## Managing Contexts

### Enable/Disable Contexts

```gdscript
# Enable a context
GUIDE.enable_mapping_context(gameplay_context)

# Enable with priority (lower number = higher priority)
GUIDE.enable_mapping_context(menu_context, false, 10)

# Enable and disable all others
GUIDE.enable_mapping_context(menu_context, true)

# Disable a specific context
GUIDE.disable_mapping_context(gameplay_context)

# Disable all contexts
GUIDE.disable_all_mapping_contexts()
```

### Context Priority

Lower numbers = higher priority. Higher priority contexts override lower ones.

```gdscript
# Game flow example
func _ready():
    # Base gameplay (priority 100)
    GUIDE.enable_mapping_context(player_context, false, 100)

func open_menu():
    # Menu overrides gameplay (priority 0)
    GUIDE.enable_mapping_context(menu_context, false, 0)

func close_menu():
    GUIDE.disable_mapping_context(menu_context)
```

## Practical Example: Sidescroller Game

### Project Structure
```
res://
├── input/
│   ├── actions/
│   │   ├── move_action.tres
│   │   ├── jump_action.tres
│   │   └── attack_action.tres
│   └── contexts/
│       ├── player_context.tres
│       └── menu_context.tres
└── scenes/
    └── player.gd
```

### Create Action: Move (Axis2D)
1. Create `res://input/actions/move_action.tres`
2. Set **Value Type** → `Axis2D`

### Create Action: Jump (Button)
1. Create `res://input/actions/jump_action.tres`
2. Set **Value Type** → `Button`

### Create Mapping Context
1. Create `res://input/contexts/player_context.tres`
2. In Inspector → **Action Mappings**:

**Move Action:**
- Action: `move_action.tres`
- Input Mappings:
  - Type: Keyboard → Keys: W, A, S, D (configure as 2D axis)
  - Type: Gamepad → Left Stick

**Jump Action:**
- Action: `jump_action.tres`
- Input Mappings:
  - Type: Keyboard → Key: Space
  - Type: Gamepad → Button: A/Cross

### Player Script

```gdscript
# player.gd
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

@export var move_action: GUIDEAction
@export var jump_action: GUIDEAction

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
    jump_action.triggered.connect(_on_jump)

func _physics_process(delta):
    # Apply gravity
    if not is_on_floor():
        velocity.y += gravity * delta

    # Get movement input from action
    var move_input = move_action.value_axis_2d

    # Horizontal movement
    velocity.x = move_input.x * SPEED

    # Flip sprite based on direction
    if move_input.x != 0:
        $Sprite2D.flip_h = move_input.x < 0

    move_and_slide()

func _on_jump():
    if is_on_floor():
        velocity.y = JUMP_VELOCITY
```

### Game Manager Script

```gdscript
# game.gd
extends Node2D

@export var player_context: GUIDEMappingContext

func _ready():
    # Enable player controls
    GUIDE.enable_mapping_context(player_context)
```

## Advanced Features

### Input Modifiers
Modify input values before they reach actions:

- **Negate**: Invert input
- **Scale**: Multiply input by factor
- **Dead Zone**: Ignore small inputs
- **Smooth**: Smooth input over time

### Input Triggers
Define when an action should fire:

- **Pressed**: When input first activated
- **Released**: When input released
- **Hold**: When held for duration
- **Tap**: Quick press and release
- **Chord**: Requires multiple inputs together
- **Combo**: Sequence of inputs

### Example: Hold to Charge Attack

```gdscript
# In mapping context resource:
# - Action: charge_attack
# - Trigger: Hold (2.0 seconds)

@export var charge_attack: GUIDEAction

func _ready():
    charge_attack.triggered.connect(_on_charge_complete)
    charge_attack.ongoing.connect(_on_charging)

func _on_charging():
    # Show charging effect
    charge_bar.value = charge_attack.elapsed_time / 2.0

func _on_charge_complete():
    # Release powerful attack
    fire_charged_shot()
```

## Remapping at Runtime

Allow players to customize controls:

```gdscript
# Create remapping config
var config = GUIDERemappingConfig.new()

# Remap jump to different key
config.set_mapping(jump_action, new_input_event)

# Apply config
GUIDE.set_remapping_config(config)
```

## UI Prompts

Show the correct button icon based on active input device:

```gdscript
# Get the current input for an action
var input_events = GUIDE.get_inputs_for_action(jump_action)

# Display appropriate icon
if input_events.size() > 0:
    var event = input_events[0]
    prompt_label.text = event.as_text()  # Shows "Space" or "A Button"
```

## Integration with Your Services

### Add to GameManager

```gdscript
# game_manager.gd
var input_context: GUIDEMappingContext = null

func enable_gameplay_input():
    if input_context:
        GUIDE.enable_mapping_context(input_context)

func disable_gameplay_input():
    if input_context:
        GUIDE.disable_mapping_context(input_context)
```

### Context Switching with Scenes

```gdscript
# In scene script
func _ready():
    GUIDE.enable_mapping_context(this_scene_context)

func _exit_tree():
    GUIDE.disable_mapping_context(this_scene_context)
```

## Best Practices

1. **One Context per Game State**: Menu, Gameplay, Dialogue, etc.
2. **Use Priorities Wisely**: Higher-level contexts (menus) have higher priority (lower numbers)
3. **Connect Signals in _ready()**: Don't miss initialization
4. **Use Axis2D for Movement**: More flexible than separate actions
5. **Handle Context Cleanup**: Disable contexts when scenes change
6. **Test with Multiple Devices**: Keyboard, gamepad, touch

## Example Files Location

Your project includes examples in `guide_examples/`:
- `quick_start/` - Basic usage
- `input_contexts/` - Context switching
- `remapping/` - Runtime remapping
- `combos/` - Combo system
- `action_priority/` - Priority handling

## Common Patterns

### Menu Navigation
```gdscript
@export var navigate_action: GUIDEAction
@export var select_action: GUIDEAction
@export var back_action: GUIDEAction

func _ready():
    select_action.triggered.connect(_on_select)
    back_action.triggered.connect(_on_back)

func _process(_delta):
    var nav = navigate_action.value_axis_2d
    if nav.y < 0:
        select_previous_option()
    elif nav.y > 0:
        select_next_option()
```

### Pause Menu
```gdscript
@export var pause_action: GUIDEAction
@export var gameplay_context: GUIDEMappingContext
@export var menu_context: GUIDEMappingContext

func _ready():
    pause_action.triggered.connect(toggle_pause)

func toggle_pause():
    get_tree().paused = !get_tree().paused
    if get_tree().paused:
        GUIDE.enable_mapping_context(menu_context, true)
    else:
        GUIDE.enable_mapping_context(gameplay_context, true)
```

## Resources

- **Examples**: `guide_examples/` folder in your project
- **Plugin Source**: `addons/guide/`
- **GitHub**: https://github.com/Nolkaloid/guide (likely)
- **Godot Asset Library**: Search for "GUIDE"

GUIDE is already set up as an autoload (`GUIDE`) in your project, so you can access it from anywhere!
