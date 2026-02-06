# Debug Sprite Component Design

A placeholder sprite component that displays debug text overlays on a static image, used during development before final animations are ready. **Designed as a drop-in replacement for AnimatedSprite2D** so existing animation code works without modification.

---

## Overview

The DebugSprite component provides visual feedback for entity states during development by rendering text labels over a placeholder image. This allows gameplay systems to be tested and iterated on before art assets and animations are complete.

**Key Design Goal**: DebugSprite must be compatible with the existing animation system where `Mob._find_sprite_node()` auto-detects sprites and `Player._update_animations()` calls `play()` on them. This means DebugSprite needs to implement the same interface as `AnimatedSprite2D`.

---

## Use Cases

- Placeholder visuals for Roo characters before animations
- Debug state display for AI behavior testing
- Quick prototyping of new entity types
- Visual debugging of state machines and profession systems

---

## Component Structure

```
DebugSprite (Node2D)
├── Sprite2D              # Placeholder static image
├── LabelsContainer       # Container for debug labels
│   ├── NameLabel         # Entity name/ID (Label)
│   ├── StateLabel        # Current animation/state text (Label)
│   └── InfoLabel         # Additional debug info (Label)
└── FlashTimer            # For damage flash effect
```

---

## AnimatedSprite2D Compatibility

DebugSprite must implement the following to be a drop-in replacement:

### Required Properties (matching AnimatedSprite2D)

| Property | Type | Description |
|----------|------|-------------|
| `animation` | StringName | Current animation name (read/write) |
| `flip_h` | bool | Horizontal flip state |
| `flip_v` | bool | Vertical flip state |
| `sprite_frames` | SpriteFrames | Optional - for animation name validation |

### Required Methods (matching AnimatedSprite2D)

```gdscript
## Play an animation by name - CRITICAL for compatibility with _update_animations()
func play(anim_name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false) -> void

## Stop the current animation
func stop() -> void

## Check if animation is playing
func is_playing() -> bool

## Get current frame (always 0 for static sprite)
func get_frame() -> int
```

### Required Signals (matching AnimatedSprite2D)

```gdscript
signal animation_changed()
signal animation_finished()
signal animation_looped()
signal frame_changed()
```

---

## Additional Debug Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `placeholder_texture` | Texture2D | null | Static placeholder image |
| `placeholder_color` | Color | Color.WHITE | Tint/modulate color |
| `show_labels` | bool | true | Display debug labels |
| `show_name` | bool | true | Display name label |
| `show_info` | bool | false | Display extra info label |
| `label_offset` | Vector2 | (0, -32) | Offset for labels above sprite |
| `font_size` | int | 12 | Debug text font size |
| `state_colors` | Dictionary | {} | Animation name -> Color mapping |

---

## Full API

```gdscript
extends Node2D
class_name DebugSprite

#region AnimatedSprite2D Compatibility

## Current animation name - updated when play() is called
var animation: StringName = &"idle":
	set(value):
		if animation != value:
			var old = animation
			animation = value
			_update_state_display()
			animation_changed.emit()

## Sprite flipping (affects placeholder sprite)
var flip_h: bool = false:
	set(value):
		flip_h = value
		if _sprite:
			_sprite.flip_h = value

var flip_v: bool = false:
	set(value):
		flip_v = value
		if _sprite:
			_sprite.flip_v = value

## Optional SpriteFrames for animation validation
var sprite_frames: SpriteFrames = null

## Signals matching AnimatedSprite2D
signal animation_changed()
signal animation_finished()
signal animation_looped()
signal frame_changed()

## Play animation - this is called by _update_animations() in player.gd
func play(anim_name: StringName = &"", custom_speed: float = 1.0, from_end: bool = false) -> void:
	if anim_name != &"":
		animation = anim_name
	_is_playing = true
	# Emit finished immediately since we have no frames
	animation_finished.emit()

func stop() -> void:
	_is_playing = false

func is_playing() -> bool:
	return _is_playing

func get_frame() -> int:
	return 0

#endregion

#region Debug-Specific API

## Set the display name shown above sprite
func set_display_name(display_name: String) -> void

## Set additional info text (profession, target, etc.)
func set_info(info: String) -> void

## Set placeholder texture at runtime
func set_placeholder(texture: Texture2D) -> void

## Flash the sprite (for damage, selection, etc.)
func flash(color: Color = Color.WHITE, duration: float = 0.1) -> void

## Set visibility of debug labels
func set_labels_visible(labels_visible: bool) -> void

#endregion
```

---

## State/Animation Colors

Default color mapping for animation names (matching player.gd animations and common AI states):

| Animation | Color | Hex | Notes |
|-----------|-------|-----|-------|
| `idle` | Gray | `#888888` | Default standing |
| `run` | Green | `#44AA44` | Movement |
| `jump` | Cyan | `#44AAAA` | Ascending |
| `fall` | Blue | `#4466AA` | Descending |
| `dash` | Yellow | `#DDDD44` | Dash action |
| `death` | Dark Red | `#662222` | Dead state |
| `attack` | Red | `#DD4444` | Combat |
| `working` | Blue | `#4488DD` | AI work state |
| `scouting` | Yellow | `#DDDD44` | Scout profession |
| `building` | Orange | `#DD8844` | Builder profession |
| `harvesting` | Lime | `#88DD44` | Lumberjack/Miner |

Custom colors can be added via `state_colors` dictionary. Unknown animations default to white.

---

## Label Layout

```
        ┌─────────────┐
        │  NameLabel  │  <- Entity name/ID
        ├─────────────┤
        │ StateLabel  │  <- Current state (colored)
        ├─────────────┤
        │  InfoLabel  │  <- Extra debug info
        └─────────────┘
              │
        ┌─────┴─────┐
        │           │
        │  Sprite   │  <- Placeholder image
        │           │
        └───────────┘
```

Labels are centered above the sprite, stacked vertically.

---

## Integration

### Drop-In Replacement for AnimatedSprite2D

The key integration point is that `Mob._find_sprite_node()` auto-detects child sprites:

```gdscript
# In mob.gd (existing code)
func _find_sprite_node() -> void:
    for child in get_children():
        if child is AnimatedSprite2D or child is Sprite2D:
            sprite_node = child
            return
```

**For DebugSprite to be detected**, it must either:
1. Be added to this check: `if child is AnimatedSprite2D or child is Sprite2D or child is DebugSprite:`
2. Or extend Sprite2D (recommended - see Implementation Notes)

### With Player/Mob (No Code Changes Needed)

Once detected as `sprite_node`, the existing animation code works automatically:

```gdscript
# In player.gd (existing code - works unchanged)
func _update_animations() -> void:
    if not sprite_node:
        return
    # ...
    _play_animation(sprite_node, "run")  # Calls sprite_node.play("run")

func _play_animation(sprite, anim_name: String) -> void:
    # This check works because DebugSprite.animation property exists
    if sprite.animation != anim_name:
        sprite.play(anim_name)
```

### With Roo Entity

```gdscript
# In roo.gd - DebugSprite picked up automatically by Mob._find_sprite_node()
# Animation calls work via play() compatibility

# For profession display, add:
func _on_profession_changed(profession: Enums.Professions) -> void:
    if sprite_node is DebugSprite:
        sprite_node.set_info(Enums.Professions.keys()[profession])
```

### With Health Component

```gdscript
# React to damage for flash effect
func _on_damage_taken(amount: int, _type) -> void:
    if sprite_node is DebugSprite:
        sprite_node.flash(Color.RED, 0.15)
```

### With AI State Machine

```gdscript
# AI behavior can set custom animation names
# These will display as text on the DebugSprite
func _enter_state(state_name: String) -> void:
    if sprite_node:
        sprite_node.play(state_name)  # Works for both AnimatedSprite2D and DebugSprite
```

---

## Default Placeholder

When no texture is assigned, the component should render a simple colored rectangle or circle shape as a fallback. Size should be configurable.

```gdscript
@export var fallback_shape: int = 0  # 0 = rect, 1 = circle
@export var fallback_size: Vector2 = Vector2(32, 32)
@export var fallback_color: Color = Color.MAGENTA
```

---

## Scene Structure

`res://src/scenes/components/debug_sprite.tscn`:

```
DebugSprite (Node2D) [debug_sprite.gd]
├── Sprite2D
│   └── texture: null (set via export or code)
├── LabelsContainer (Control)
│   ├── NameLabel (Label)
│   │   └── horizontal_alignment: CENTER
│   ├── StateLabel (Label)
│   │   └── horizontal_alignment: CENTER
│   └── InfoLabel (Label)
│       └── horizontal_alignment: CENTER
└── FlashTimer (Timer)
    └── one_shot: true
```

---

## Configuration

### Project-Wide Defaults

Consider adding to `GameManager` or a debug settings singleton:

```gdscript
# In debug_settings.gd or game_manager.gd
var debug_sprites_enabled: bool = true
var debug_sprites_show_state: bool = true
var debug_sprites_show_name: bool = true
var debug_sprites_show_info: bool = false
```

### Toggle via Input

```gdscript
# Toggle all debug sprites with a key
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_debug_sprites"):
        DebugSettings.debug_sprites_enabled = !DebugSettings.debug_sprites_enabled
```

---

## Implementation Notes

1. **Extend Sprite2D**: DebugSprite should `extend Sprite2D` rather than Node2D. This ensures:
   - Auto-detection by `Mob._find_sprite_node()` which checks `child is Sprite2D`
   - Inherited `flip_h`, `flip_v`, `texture` properties
   - No changes needed to existing Mob code

2. **Animation Property**: The `animation` property must be a `StringName` for compatibility with existing animation checks like `sprite.animation != anim_name`.

3. **Immediate Animation Finished**: Since DebugSprite has no frames, emit `animation_finished` immediately after `play()`. This matches behavior for single-frame animations.

4. **Performance**: Labels should use `Label` nodes (not `Label3D`) since this is 2D. Consider pooling or hiding labels when offscreen.

5. **Z-Index**: Labels should render above all game sprites. Set appropriate z_index on LabelsContainer.

6. **Camera Zoom**: Font size should optionally scale inversely with camera zoom to maintain readability.

7. **Production Build**: Use `@export var debug_mode: bool = true` to disable labels in release. Or strip entirely via feature tags.

8. **Visibility Culling**: Disable processing when not visible to camera (use `VisibleOnScreenNotifier2D`).

9. **Direction Flipping**: The base Mob class calls `sprite_node.flip_h = facing_direction < 0`. This works automatically if DebugSprite extends Sprite2D.

---

## File Location

```
src/scenes/components/debug_sprite.tscn
src/scenes/components/debug_sprite.gd
```

---

## Swapping Between DebugSprite and AnimatedSprite2D

The scene structure allows easy swapping:

```
# Development: Use DebugSprite
Roo (Mob)
└── DebugSprite  <- sprite_node auto-detected

# Production: Swap to AnimatedSprite2D
Roo (Mob)
└── AnimatedSprite2D  <- sprite_node auto-detected
```

Both support:
- `play(anim_name)`
- `animation` property
- `flip_h` / `flip_v`
- Animation signals

No code changes required when swapping - just replace the scene node.

---

## Minimal Implementation Example

```gdscript
extends Sprite2D
class_name DebugSprite

## AnimatedSprite2D compatibility
var animation: StringName = &"idle":
    set(value):
        if animation != value:
            animation = value
            _state_label.text = str(animation).to_upper()
            _update_color()
            animation_changed.emit()

var sprite_frames: SpriteFrames = null
var _is_playing: bool = false

signal animation_changed()
signal animation_finished()

@onready var _state_label: Label = $StateLabel

func play(anim_name: StringName = &"", _speed: float = 1.0, _from_end: bool = false) -> void:
    if anim_name != &"":
        animation = anim_name
    _is_playing = true
    animation_finished.emit()

func stop() -> void:
    _is_playing = false

func is_playing() -> bool:
    return _is_playing

func _update_color() -> void:
    var colors = {
        &"idle": Color.GRAY,
        &"run": Color.GREEN,
        &"jump": Color.CYAN,
        &"fall": Color.BLUE,
        &"death": Color.DARK_RED,
    }
    _state_label.modulate = colors.get(animation, Color.WHITE)
```

---

## Future Extensions

- Health bar overlay
- Target indicator (line to current target)
- Pathfinding visualization
- Clickable for inspector popup
- Screenshot capture of entity state
- Frame counter when using sprite_frames for validation
