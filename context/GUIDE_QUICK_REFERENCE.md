# GUIDE Quick Reference Card

## Setup Checklist

- [ ] Create `GUIDEAction` resources in `res://input/actions/`
- [ ] Create `GUIDEMappingContext` resource in `res://input/contexts/`
- [ ] Configure action mappings in context
- [ ] Add input mappings (keyboard, gamepad, etc.)
- [ ] Export actions in your script
- [ ] Export context in game script
- [ ] Enable context with `GUIDE.enable_mapping_context()`

## Code Snippets

### Enable Context
```gdscript
@export var player_context: GUIDEMappingContext

func _ready():
    GUIDE.enable_mapping_context(player_context)
```

### Read Action Value
```gdscript
@export var move_action: GUIDEAction

func _physics_process(delta):
    # Button (bool)
    if jump_action.value_bool:
        jump()

    # Axis 1D (float -1 to 1)
    velocity.x = move_action.value_axis_1d * SPEED

    # Axis 2D (Vector2)
    velocity = move_action.value_axis_2d * SPEED
```

### Connect to Signals
```gdscript
@export var action: GUIDEAction

func _ready():
    action.triggered.connect(_on_action)  # Most common
    action.started.connect(_on_started)
    action.ongoing.connect(_on_ongoing)
    action.canceled.connect(_on_canceled)
```

### Context Switching
```gdscript
# Open menu (disable others)
GUIDE.enable_mapping_context(menu_context, true)

# Close menu (restore gameplay)
GUIDE.enable_mapping_context(gameplay_context, true)

# Multiple contexts with priority
GUIDE.enable_mapping_context(base_context, false, 100)
GUIDE.enable_mapping_context(menu_context, false, 0)
```

## Action Value Types

| Type | Property | Description | Example Use |
|------|----------|-------------|-------------|
| Button | `value_bool` | True/False | Jump, Shoot, Interact |
| Axis 1D | `value_axis_1d` | -1.0 to 1.0 | Horizontal movement, Zoom |
| Axis 2D | `value_axis_2d` | Vector2 | Movement, Aiming |
| Axis 3D | `value_axis_3d` | Vector3 | Flight, 3D camera |

## Signal Flow

```
Input Event
    ↓
started      (first activated)
    ↓
ongoing      (every frame while active)
    ↓
triggered    (when condition met) ← Use this most
    ↓
completed    (action finished)
    ↓
canceled     (if interrupted)
```

## Context Priority

```
Priority 0   ← Highest (Menus, Dialogs)
Priority 10
Priority 50
Priority 100 ← Lowest (Base gameplay)
```

Lower number = Higher priority = Overrides others

## Common Patterns

### Movement (2D)
```gdscript
@export var move_action: GUIDEAction  # Type: Axis2D

func _physics_process(delta):
    var input = move_action.value_axis_2d
    velocity = input * SPEED
    move_and_slide()
```

### Jump
```gdscript
@export var jump_action: GUIDEAction  # Type: Button

func _ready():
    jump_action.triggered.connect(_jump)

func _jump():
    if is_on_floor():
        velocity.y = JUMP_VELOCITY
```

### Shoot
```gdscript
@export var shoot_action: GUIDEAction  # Type: Button

func _ready():
    shoot_action.triggered.connect(_shoot)

func _shoot():
    spawn_bullet()
```

### Aim (with mouse/stick)
```gdscript
@export var aim_action: GUIDEAction  # Type: Axis2D

func _process(delta):
    var aim_dir = aim_action.value_axis_2d
    crosshair.position = position + aim_dir * 100
```

### Pause Menu
```gdscript
@export var pause_action: GUIDEAction
@export var game_context: GUIDEMappingContext
@export var menu_context: GUIDEMappingContext

func _ready():
    pause_action.triggered.connect(_toggle_pause)
    GUIDE.enable_mapping_context(game_context)

func _toggle_pause():
    get_tree().paused = !get_tree().paused
    if get_tree().paused:
        GUIDE.enable_mapping_context(menu_context, true)
    else:
        GUIDE.enable_mapping_context(game_context, true)
```

## Debugging

### Check Active Contexts
```gdscript
# In console or debug script
print(GUIDE._active_contexts)
```

### Check Action Value
```gdscript
# Print action value every frame
func _process(delta):
    print("Move: ", move_action.value_axis_2d)
    print("Jump: ", jump_action.value_bool)
```

### Monitor Signals
```gdscript
func _ready():
    action.triggered.connect(func(): print("TRIGGERED!"))
    action.started.connect(func(): print("STARTED!"))
    action.canceled.connect(func(): print("CANCELED!"))
```

## Resource Organization

Recommended structure:
```
res://
├── input/
│   ├── actions/
│   │   ├── move_action.tres
│   │   ├── jump_action.tres
│   │   ├── attack_action.tres
│   │   └── interact_action.tres
│   └── contexts/
│       ├── player_context.tres
│       ├── menu_context.tres
│       ├── vehicle_context.tres
│       └── dialogue_context.tres
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Action not firing | Check context is enabled |
| Wrong input detected | Check context priority |
| Input not responding | Verify action is in context |
| Conflicts between actions | Use priority or different contexts |
| Can't change controls | Implement remapping config |

## Example: Complete Player Setup

**1. Create Resources:**
- `move_action.tres` (Axis2D)
- `jump_action.tres` (Button)
- `player_context.tres`

**2. Configure Context:**
```
player_context.tres:
  Action Mappings:
    - move_action
        Input: W/A/S/D (as 2D)
        Input: Left Stick
    - jump_action
        Input: Space
        Input: A Button
```

**3. Player Script:**
```gdscript
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

@export var move_action: GUIDEAction
@export var jump_action: GUIDEAction

func _ready():
    jump_action.triggered.connect(_on_jump)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += get_gravity() * delta

    velocity.x = move_action.value_axis_2d.x * SPEED
    move_and_slide()

func _on_jump():
    if is_on_floor():
        velocity.y = JUMP_VELOCITY
```

**4. Game Script:**
```gdscript
extends Node2D

@export var player_context: GUIDEMappingContext

func _ready():
    GUIDE.enable_mapping_context(player_context)
```

**5. In Editor:**
- Assign resources to @export variables in Inspector
- Run and test!

## Quick Tips

- 🎮 **Multiple Inputs**: One action can have keyboard, gamepad, and touch inputs
- 🔄 **Context Switching**: Use for different game states (menu, gameplay, cutscene)
- 📊 **Priority**: Lower number = higher priority
- 🎯 **Triggers**: Use `triggered` signal for most actions
- 🧪 **Test**: Try both keyboard and gamepad to ensure all inputs work
- 📁 **Organize**: Keep all input resources in `res://input/`

## Learn More

See `GUIDE_USAGE.md` for complete documentation and advanced features.
Check `guide_examples/` folder for working examples.
