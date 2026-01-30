extends Resource
class_name StatusEffect

## The unique identifier for this status effect type (use StatusEffectsLibrary.StatusEffects enum)
@export var effect_id: int = -1

## Display name for UI
@export var display_name: String = ""

## Description of what the effect does
@export_multiline var description: String = ""

## Icon for UI representation
@export var icon: Texture2D

## Base damage/healing per second (can be overridden by potency)
@export var base_power: float = 0.0

## Damage type if this effect deals damage
@export var damage_type: Enums.DamageType = Enums.DamageType.TRUE

## Whether this effect can stack multiple times
@export var can_stack: bool = false

## Maximum number of stacks allowed (0 = unlimited)
@export var max_stacks: int = 1

## Visual effect scene to instantiate when applied
@export var visual_effect: PackedScene

## Sound effect to play when applied
@export var apply_sound: AudioStream

## Whether the effect is beneficial or harmful
@export var is_beneficial: bool = false
