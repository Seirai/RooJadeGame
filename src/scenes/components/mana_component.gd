extends Node
class_name ManaComponent
## Component that manages mana/energy resources for entities.
##
## This component provides mana management functionality similar to how
## HealthComponent manages health. Attach this to any entity that uses mana.

#region Signals

## Emitted when mana changes
signal mana_changed(new_mana: float, max_mana: float)

#endregion

#region Properties

@export_group("Mana")
## Maximum mana/energy points
@export var max_mana: float = 100.0
## Current mana/energy points
@export var current_mana: float = 100.0

#endregion

func _ready() -> void:
	# Initialize mana to max
	current_mana = max_mana


#region Mana Management

## Restores mana
## @param amount: Amount of mana to restore
func restore_mana(amount: float) -> void:
	if amount <= 0:
		return

	var old_mana = current_mana
	current_mana = min(current_mana + amount, max_mana)

	var actual_restore = current_mana - old_mana
	if actual_restore > 0:
		mana_changed.emit(current_mana, max_mana)


## Consumes mana
## @param amount: Amount of mana to consume
## @return: true if mana was consumed successfully
func consume_mana(amount: float) -> bool:
	if current_mana < amount:
		return false

	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true


## Gets the current mana percentage
## @return: Mana as percentage (0-1)
func get_mana_percent() -> float:
	return current_mana / max_mana if max_mana > 0 else 0.0


## Sets mana to maximum
func refill_mana() -> void:
	current_mana = max_mana
	mana_changed.emit(current_mana, max_mana)


## Sets mana to a specific value without emitting restore signal
## Only emits mana_changed signal
## @param new_mana: New mana value (will be clamped to 0-max_mana)
func set_mana(new_mana: float) -> void:
	current_mana = clamp(new_mana, 0, max_mana)
	mana_changed.emit(current_mana, max_mana)

#endregion
