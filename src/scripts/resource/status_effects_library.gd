extends Node
class_name StatusEffectsLibrary

## Central registry for all status effect definitions

const StatusEffect = preload("res://src/scripts/class/status_effect.gd")

## All status effect IDs in the game
enum StatusEffects {
	BURN,
	BLEED,
	POISON,
	REGENERATION,
	STUN,
	SLOW,
	FREEZE,
}

## Dictionary of all registered status effects [StatusEffects -> StatusEffect]
static var _effects: Dictionary = {}

## Initialize all status effect definitions
static func _static_init() -> void:
	_register_all_effects()

static func _register_all_effects() -> void:
	# Damage over time effects
	register_effect(_create_burn())
	register_effect(_create_bleed())
	register_effect(_create_poison())

	# Healing/Regeneration effects
	register_effect(_create_regeneration())

	# Crowd control effects
	register_effect(_create_stun())
	register_effect(_create_slow())
	register_effect(_create_freeze())

## Register a status effect in the library
static func register_effect(effect: StatusEffect) -> void:
	if effect and effect.effect_id >= 0:
		_effects[effect.effect_id] = effect

## Get a status effect by its ID
static func get_effect(effect_id: StatusEffects) -> StatusEffect:
	return _effects.get(effect_id, null)

## Check if an effect exists
static func has_effect(effect_id: StatusEffects) -> bool:
	return _effects.has(effect_id)

## Get all registered effect IDs
static func get_all_effect_ids() -> Array[int]:
	var ids: Array[int] = []
	for id in _effects.keys():
		ids.append(id)
	return ids

## Get all effects
static func get_all_effects() -> Array[StatusEffect]:
	var effects_array: Array[StatusEffect] = []
	for effect in _effects.values():
		effects_array.append(effect)
	return effects_array

# ============================================================================
# Effect Definitions
# ============================================================================

static func _create_burn() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.BURN
	effect.display_name = "Burn"
	effect.description = "Deals fire damage over time"
	effect.base_power = 5.0
	effect.damage_type = HealthComponent.DamageType.FIRE
	effect.can_stack = false
	effect.max_stacks = 1
	effect.is_beneficial = false
	return effect

static func _create_bleed() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.BLEED
	effect.display_name = "Bleed"
	effect.description = "Causes bleeding, dealing physical damage over time"
	effect.base_power = 3.0
	effect.damage_type = HealthComponent.DamageType.PHYSICAL
	effect.can_stack = true
	effect.max_stacks = 5
	effect.is_beneficial = false
	return effect

static func _create_poison() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.POISON
	effect.display_name = "Poison"
	effect.description = "Poisoned, taking damage over time"
	effect.base_power = 4.0
	effect.damage_type = HealthComponent.DamageType.POISON
	effect.can_stack = false
	effect.max_stacks = 1
	effect.is_beneficial = false
	return effect

static func _create_regeneration() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.REGENERATION
	effect.display_name = "Regeneration"
	effect.description = "Restores health over time"
	effect.base_power = 2.0
	effect.damage_type = HealthComponent.DamageType.TRUE
	effect.can_stack = false
	effect.max_stacks = 1
	effect.is_beneficial = true
	return effect

static func _create_stun() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.STUN
	effect.display_name = "Stunned"
	effect.description = "Unable to act"
	effect.base_power = 0.0
	effect.damage_type = HealthComponent.DamageType.TRUE
	effect.can_stack = false
	effect.max_stacks = 1
	effect.is_beneficial = false
	return effect

static func _create_slow() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.SLOW
	effect.display_name = "Slowed"
	effect.description = "Movement speed reduced"
	effect.base_power = 0.0
	effect.damage_type = HealthComponent.DamageType.TRUE
	effect.can_stack = false
	effect.max_stacks = 1
	effect.is_beneficial = false
	return effect

static func _create_freeze() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.effect_id = StatusEffects.FREEZE
	effect.display_name = "Frozen"
	effect.description = "Frozen solid, unable to move"
	effect.base_power = 0.0
	effect.damage_type = HealthComponent.DamageType.ICE
	effect.can_stack = false
	effect.max_stacks = 1
	effect.is_beneficial = false
	return effect
