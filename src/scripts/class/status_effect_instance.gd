extends RefCounted
class_name StatusEffectInstance

const StatusEffect = preload("res://src/scripts/class/status_effect.gd")

## Reference to the status effect definition
var effect: StatusEffect

## Remaining duration in seconds
var remaining_duration: float

## How much time has elapsed
var elapsed_time: float = 0.0

## Potency multiplier (affects power, duration, etc.)
var potency: float = 1.0

## Current stack count (if effect can stack)
var stack_count: int = 1

## Source of the effect (e.g., who applied it)
var source: Node = null

## Custom data that can be used by effect implementations
var custom_data: Dictionary = {}

func _init(p_effect: StatusEffect, p_duration: float, p_potency: float = 1.0, p_source: Node = null) -> void:
	effect = p_effect
	remaining_duration = p_duration
	potency = p_potency
	source = p_source

func tick(delta: float) -> void:
	elapsed_time += delta
	remaining_duration -= delta

func is_expired() -> bool:
	return remaining_duration <= 0.0

func refresh_duration(new_duration: float) -> void:
	remaining_duration = max(remaining_duration, new_duration)

func add_stack() -> bool:
	if not effect.can_stack:
		return false

	if effect.max_stacks > 0 and stack_count >= effect.max_stacks:
		return false

	stack_count += 1
	return true

func get_effective_power() -> float:
	return effect.base_power * potency * stack_count
