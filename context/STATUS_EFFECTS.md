# Status Effects

All status effects are defined in the centralized **StatusEffectsLibrary** (`status_effects_library.gd`).

## How to Use Status Effects

### Applying Effects

```gdscript
# Get an effect from the library using the enum
var burn_effect = StatusEffectsLibrary.get_effect(StatusEffectsLibrary.StatusEffects.BURN)

# Apply to a health component
health_component.apply_status_effect(burn_effect, 5.0, 1.5)  # 5 second duration, 1.5x potency
```

### Checking for Effects

```gdscript
# Check if entity has a specific effect
if health_component.has_status_effect(StatusEffectsLibrary.StatusEffects.BURN):
	print("Entity is burning!")

# Get the effect instance for details
var burn_instance = health_component.get_status_effect(StatusEffectsLibrary.StatusEffects.BURN)
if burn_instance:
	print("Burn has %s seconds remaining" % burn_instance.remaining_duration)
	print("Burn has %d stacks" % burn_instance.stack_count)
```

### Removing Effects

```gdscript
# Remove a specific effect
health_component.remove_status_effect(StatusEffectsLibrary.StatusEffects.BURN)

# Remove all effects
health_component.clear_all_status_effects()
```

## Adding New Status Effects

To add a new status effect, edit `status_effects_library.gd`:

1. Add the effect to the `StatusEffects` enum:

```gdscript
enum StatusEffects {
	BURN,
	BLEED,
	POISON,
	REGENERATION,
	STUN,
	SLOW,
	FREEZE,
	MY_EFFECT,  # Add your new effect here
}
```

2. Create a new static function (e.g., `_create_my_effect()`):

```gdscript
static func _create_my_effect() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.MY_EFFECT  # Use the enum value
	effect.display_name = "My Effect"
	effect.description = "Does something cool"
	effect.base_power = 10.0
	effect.damage_type = Enums.DamageType.MAGIC
	effect.can_stack = true
	effect.max_stacks = 3
	effect.is_beneficial = false
	return effect
```

3. Register it in `_register_all_effects()`:

```gdscript
static func _register_all_effects() -> void:
	# ... existing effects ...
	register_effect(_create_my_effect())
```

4. (Optional) Add resistance support in `HealthComponent._get_status_resistance()`:

```gdscript
func _get_status_resistance(effect_id: int) -> float:
	match effect_id:
		StatusEffectsLibrary.StatusEffects.MY_EFFECT:
			return my_effect_resistance
		# ... other effects ...
```

## Built-in Status Effects

All effects are accessed via `StatusEffectsLibrary.StatusEffects` enum:

### Damage Over Time
- **BURN** - Fire damage over time (5 DPS, non-stacking)
- **BLEED** - Physical damage over time (3 DPS, stacks up to 5x)
- **POISON** - Poison damage over time (4 DPS, non-stacking)

### Healing
- **REGENERATION** - Restores health over time (2 HPS, non-stacking)

### Crowd Control
- **STUN** - Unable to act (no damage)
- **SLOW** - Movement speed reduced (no damage)
- **FREEZE** - Frozen solid (no damage)

## Built-in Effect Resistances

The following effects have corresponding resistances in HealthComponent:
- `StatusEffects.BURN` → `burn_resistance`
- `StatusEffects.FREEZE` → `freeze_resistance`
- `StatusEffects.BLEED` → `bleed_resistance`
- `StatusEffects.STUN` → `stun_resistance`
- `StatusEffects.SLOW` → `slow_resistance`

Resistance values range from 0.0 (no resistance) to 1.0 (immune).

## Why Enums Instead of Strings?

The status effect system uses integer enums instead of string IDs for several benefits:
- **Compile-time checking**: Typos are caught by the editor/compiler
- **Autocomplete support**: IDE shows available effects when typing
- **Refactoring safety**: Renaming an effect updates all usages
- **Performance**: Integer comparisons are faster than string comparisons
