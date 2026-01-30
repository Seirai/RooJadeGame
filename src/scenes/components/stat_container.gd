extends Node
class_name StatContainer
## Component that manages stats, leveling, and experience for entities.
##
## This component handles experience gain, leveling, and stat growth.
## Attach this to any entity that needs progression systems.

## @TODO Ensure stats are not free strings and instead use an enum or constants for better performance and safety.

#region Signals

## Emitted when experience is gained
signal exp_gained(amount: int, new_total: int)
## Emitted when the entity levels up
signal leveled_up(new_level: int)
## Emitted when stats are modified
signal stats_changed()

#endregion

#region Experience & Leveling

@export_group("Experience")
## Current level
@export var level: int = 1
## Current experience points
@export var experience: int = 0
## Experience needed for next level
@export var exp_to_next_level: int = 100
## EXP curve multiplier (how much harder each level gets)
@export var exp_curve: float = 1.5

#endregion

#region Combat Stats

@export_group("Combat Stats")
## Base attack power
@export var attack_power: float = 10.0
## Base defense
@export var defense: float = 5.0
## Critical hit chance (0-1)
@export_range(0.0, 1.0) var crit_chance: float = 0.1
## Critical hit damage multiplier
@export var crit_multiplier: float = 2.0

#endregion

#region Stat Growth

@export_group("Stat Growth")
## Stat growth on level up
@export var stats_per_level: Dictionary = {
	"max_health": 20.0,
	"max_mana": 10.0,
	"attack_power": 2.0,
	"defense": 1.0
}

#endregion

#region Component References

## Reference to health component for level up stat increases
var _health_component: HealthComponent = null
## Reference to mana component for level up stat increases
var _mana_component: ManaComponent = null

## Initialize component references
## @param health: HealthComponent reference
## @param mana: ManaComponent reference
func initialize_components(health: HealthComponent, mana: ManaComponent) -> void:
	_health_component = health
	_mana_component = mana

#endregion

#region Experience & Leveling

## Grants experience to the entity
## @param amount: Amount of experience to grant
func gain_exp(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	exp_gained.emit(amount, experience)

	# Check for level up (can level up multiple times)
	while experience >= exp_to_next_level:
		level_up()


## Handles leveling up
func level_up() -> void:
	experience -= exp_to_next_level
	level += 1

	# Increase stats based on stats_per_level
	if _health_component:
		_health_component.max_health += stats_per_level.get("max_health", 20.0)
		_health_component.set_health(_health_component.max_health)

	if _mana_component:
		_mana_component.max_mana += stats_per_level.get("max_mana", 10.0)
		_mana_component.set_mana(_mana_component.max_mana)

	attack_power += stats_per_level.get("attack_power", 2.0)
	defense += stats_per_level.get("defense", 1.0)

	# Scale exp requirement
	exp_to_next_level = int(exp_to_next_level * exp_curve)

	stats_changed.emit()
	leveled_up.emit(level)


## Gets current experience as a percentage toward next level
## @return: Percentage (0-1)
func get_exp_percent() -> float:
	return float(experience) / float(exp_to_next_level) if exp_to_next_level > 0 else 0.0

#endregion

#region Stat Modification

## Modifies a stat by a delta amount
## @param stat_name: Name of the stat (attack_power, defense, crit_chance, crit_multiplier)
## @param delta: Amount to add (can be negative)
func modify_stat(stat_name: String, delta: float) -> void:
	match stat_name:
		"attack_power":
			attack_power += delta
		"defense":
			defense += delta
		"crit_chance":
			crit_chance = clamp(crit_chance + delta, 0.0, 1.0)
		"crit_multiplier":
			crit_multiplier = max(1.0, crit_multiplier + delta)

	stats_changed.emit()


## Sets a stat to a specific value
## @param stat_name: Name of the stat
## @param value: New value
func set_stat(stat_name: String, value: float) -> void:
	match stat_name:
		"attack_power":
			attack_power = value
		"defense":
			defense = value
		"crit_chance":
			crit_chance = clamp(value, 0.0, 1.0)
		"crit_multiplier":
			crit_multiplier = max(1.0, value)

	stats_changed.emit()


## Gets a stat value by name
## @param stat_name: Name of the stat
## @return: Stat value, or 0.0 if not found
func get_stat(stat_name: String) -> float:
	match stat_name:
		"attack_power":
			return attack_power
		"defense":
			return defense
		"crit_chance":
			return crit_chance
		"crit_multiplier":
			return crit_multiplier
		"level":
			return float(level)
		"experience":
			return float(experience)
		_:
			return 0.0

#endregion
