extends Node
class_name HealthComponent

## Uses centralized enums from Enums autoload:
## - Enums.HealthState (ALIVE, DEAD, RECOVERY, INCAPACITATED)
## - Enums.DamageType (PHYSICAL, FIRE, ICE, LIGHTNING, POISON, MAGIC, TRUE)
## - Enums.Team (NEUTRAL, PLAYER, ENEMY, ENVIRONMENT, DESTRUCTIBLE)

## Core health properties
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var death_behavior: Enums.HealthState = Enums.HealthState.DEAD  # What state to enter when health reaches 0

## Team settings
@export_group("Team")
@export var team: Enums.Team = Enums.Team.NEUTRAL
@export var friendly_fire: bool = false  ## If true, same team can damage this entity
@export var damageable_by_teams: Array[Enums.Team] = []  ## Override: only these teams can damage (empty = use default rules)

## Shield system
@export_group("Shield")
@export var max_shield: float = 0.0
@export var shield_regeneration_rate: float = 0.0
@export var shield_regeneration_delay: float = 3.0

## Regeneration/Poison
@export_group("Regeneration")
@export var health_regeneration_rate: float = 0.0  # Positive = regen, Negative = poison/DoT

## Damage type resistances (0.0 = no resistance, 1.0 = immune, -1.0 = double damage)
@export_group("Damage Resistances")
@export var physical_resistance: float = 0.0
@export var fire_resistance: float = 0.0
@export var ice_resistance: float = 0.0
@export var lightning_resistance: float = 0.0
@export var poison_resistance: float = 0.0
@export var magic_resistance: float = 0.0

## Status effect resistances (0.0 = no resistance, 1.0 = immune)
@export_group("Status Effect Resistances")
@export var stun_resistance: float = 0.0
@export var slow_resistance: float = 0.0
@export var burn_resistance: float = 0.0
@export var freeze_resistance: float = 0.0
@export var bleed_resistance: float = 0.0

## State
var current_shield: float = 0.0
var current_state: Enums.HealthState = Enums.HealthState.ALIVE
var active_status_effects: Array[StatusEffectInstance] = []

## Shield regeneration timer
var shield_regen_timer: float = 0.0

## Signals
signal health_changed(new_health: float, max_health: float)
signal shield_changed(new_shield: float, max_shield: float)
signal damage_taken(amount: float, damage_type: String)
signal healed(amount: float)
signal shield_damaged(amount: float)
signal shield_broken()
signal died()
signal incapacitated()
signal entered_recovery()
signal revived()
signal state_changed(old_state: Enums.HealthState, new_state: Enums.HealthState)
signal status_effect_applied(effect: StatusEffectInstance)
signal status_effect_removed(effect: StatusEffectInstance)
signal status_effect_tick(effect: StatusEffectInstance, delta: float)
signal damage_blocked(amount: float, attacker_team: Enums.Team, reason: String)

func _ready() -> void:
	current_shield = max_shield
	current_state = Enums.HealthState.ALIVE

func _process(delta: float) -> void:
	# Only process if in an active state
	if not _is_active_state():
		return

	# Health regeneration/poison
	if health_regeneration_rate != 0:
		_apply_regeneration(delta)

	# Shield regeneration
	if current_shield < max_shield and shield_regeneration_rate > 0:
		shield_regen_timer += delta
		if shield_regen_timer >= shield_regeneration_delay:
			_regenerate_shield(delta)

	# Process active status effects
	_process_status_effects(delta)

	# Auto-recover from RECOVERY state when health is full
	if current_state == Enums.HealthState.RECOVERY and current_health >= max_health:
		_set_state(Enums.HealthState.ALIVE)

func take_damage(amount: float, damage_type: int = Enums.DamageType.PHYSICAL, attacker_team: Enums.Team = Enums.Team.NEUTRAL) -> void:
	if not _is_active_state() or amount <= 0:
		return

	# Check team-based damage filtering
	if not can_be_damaged_by(attacker_team):
		damage_blocked.emit(amount, attacker_team, "team_immunity")
		return

	# Apply resistance
	var modified_damage = _apply_damage_resistance(amount, damage_type)

	# Shield absorbs damage first
	if current_shield > 0:
		var shield_damage = min(current_shield, modified_damage)
		current_shield -= shield_damage
		shield_damaged.emit(shield_damage)
		shield_changed.emit(current_shield, max_shield)
		modified_damage -= shield_damage
		shield_regen_timer = 0.0  # Reset shield regen delay

		if current_shield <= 0:
			shield_broken.emit()

	# Apply remaining damage to health
	if modified_damage > 0:
		current_health = max(0, current_health - modified_damage)
		damage_taken.emit(modified_damage, Enums.DamageType.keys()[damage_type])
		health_changed.emit(current_health, max_health)

		if current_health <= 0:
			_handle_death()


## Check if this entity can be damaged by the given team
func can_be_damaged_by(attacker_team: Enums.Team) -> bool:
	# If custom damageable_by_teams is set, use that exclusively
	if damageable_by_teams.size() > 0:
		return attacker_team in damageable_by_teams

	# Check friendly fire
	if attacker_team == team and not friendly_fire:
		return false

	# Default team damage rules
	match team:
		Enums.Team.NEUTRAL:
			# Neutral can be damaged by anyone
			return true

		Enums.Team.PLAYER:
			# Player is damaged by ENEMY and ENVIRONMENT
			return attacker_team in [Enums.Team.ENEMY, Enums.Team.ENVIRONMENT]

		Enums.Team.ENEMY:
			# Enemy is damaged by PLAYER and ENVIRONMENT
			return attacker_team in [Enums.Team.PLAYER, Enums.Team.ENVIRONMENT]

		Enums.Team.ENVIRONMENT:
			# Environment typically can't be damaged
			return false

		Enums.Team.DESTRUCTIBLE:
			# Destructible is damaged by PLAYER, ENEMY, and ENVIRONMENT
			return attacker_team in [Enums.Team.PLAYER, Enums.Team.ENEMY, Enums.Team.ENVIRONMENT]

	return true


## Check if this entity can damage the target team
func can_damage(target_team: Enums.Team) -> bool:
	# Check if target would accept damage from our team
	# This is a convenience method for pre-checking
	match team:
		Enums.Team.NEUTRAL:
			# Neutral doesn't deal damage by default
			return false

		Enums.Team.PLAYER:
			# Player damages ENEMY, DESTRUCTIBLE, and NEUTRAL
			return target_team in [Enums.Team.ENEMY, Enums.Team.DESTRUCTIBLE, Enums.Team.NEUTRAL]

		Enums.Team.ENEMY:
			# Enemy damages PLAYER, DESTRUCTIBLE, and NEUTRAL
			return target_team in [Enums.Team.PLAYER, Enums.Team.DESTRUCTIBLE, Enums.Team.NEUTRAL]

		Enums.Team.ENVIRONMENT:
			# Environment damages everyone except ENVIRONMENT
			return target_team != Enums.Team.ENVIRONMENT

		Enums.Team.DESTRUCTIBLE:
			# Destructible doesn't deal damage
			return false

	return false


## Set the team for this entity
func set_team(new_team: Enums.Team) -> void:
	team = new_team


## Get the team for this entity
func get_team() -> Enums.Team:
	return team

func heal(amount: float) -> void:
	if amount <= 0:
		return

	# Allow healing in RECOVERY state
	if current_state != Enums.HealthState.ALIVE and current_state != Enums.HealthState.RECOVERY:
		return

	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var actual_heal = current_health - old_health

	if actual_heal > 0:
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)

func set_health(new_health: float) -> void:
	## Sets health to a specific value without emitting healed signal
	## Only emits health_changed signal
	## @param new_health: New health value (will be clamped to 0-max_health)
	current_health = clamp(new_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func restore_shield(amount: float) -> void:
	if not _is_active_state() or amount <= 0:
		return

	current_shield = min(max_shield, current_shield + amount)
	shield_changed.emit(current_shield, max_shield)

func apply_status_effect(effect: StatusEffect, duration: float, potency: float = 1.0, source: Node = null) -> bool:
	if not effect:
		return false

	# Check resistance
	var resistance = _get_status_resistance(effect.effect_id)
	if randf() < resistance:
		return false  # Resisted

	# Check if effect already exists
	for existing in active_status_effects:
		if existing.effect.effect_id == effect.effect_id:
			# Handle stacking or refreshing
			if effect.can_stack and existing.add_stack():
				existing.refresh_duration(duration)
				return true
			else:
				# Refresh duration and update potency if higher
				existing.refresh_duration(duration)
				existing.potency = max(existing.potency, potency)
				return true

	# Add new effect instance
	var instance = StatusEffectInstance.new(effect, duration, potency, source)
	active_status_effects.append(instance)
	status_effect_applied.emit(instance)
	return true

func remove_status_effect(effect_id: int) -> void:
	for i in range(active_status_effects.size() - 1, -1, -1):
		if active_status_effects[i].effect.effect_id == effect_id:
			var instance = active_status_effects[i]
			active_status_effects.remove_at(i)
			status_effect_removed.emit(instance)

func remove_status_effect_instance(instance: StatusEffectInstance) -> void:
	var index = active_status_effects.find(instance)
	if index >= 0:
		active_status_effects.remove_at(index)
		status_effect_removed.emit(instance)

func clear_all_status_effects() -> void:
	for effect_instance in active_status_effects:
		status_effect_removed.emit(effect_instance)
	active_status_effects.clear()

func has_status_effect(effect_id: int) -> bool:
	for instance in active_status_effects:
		if instance.effect.effect_id == effect_id:
			return true
	return false

func get_status_effect(effect_id: int) -> StatusEffectInstance:
	for instance in active_status_effects:
		if instance.effect.effect_id == effect_id:
			return instance
	return null

func revive(health_percentage: float = 1.0) -> void:
	# Can only revive if not already alive
	if current_state == Enums.HealthState.ALIVE:
		return

	current_health = max_health * clamp(health_percentage, 0.0, 1.0)
	current_shield = max_shield
	clear_all_status_effects()
	_set_state(Enums.HealthState.ALIVE)
	revived.emit()
	health_changed.emit(current_health, max_health)
	shield_changed.emit(current_shield, max_shield)

func _handle_death() -> void:
	clear_all_status_effects()

	# Determine which state to enter based on death_behavior
	var new_state = death_behavior

	# If set to RECOVERY, start regenerating
	if new_state == Enums.HealthState.RECOVERY:
		_set_state(Enums.HealthState.RECOVERY)
		entered_recovery.emit()
	else:
		_set_state(new_state)

		# Emit appropriate signal based on state
		match new_state:
			Enums.HealthState.DEAD:
				died.emit()
			Enums.HealthState.INCAPACITATED:
				incapacitated.emit()

func _apply_damage_resistance(damage: float, damage_type: int) -> float:
	if damage_type == Enums.DamageType.TRUE:
		return damage

	var resistance: float = 0.0
	match damage_type:
		Enums.DamageType.PHYSICAL:
			resistance = physical_resistance
		Enums.DamageType.FIRE:
			resistance = fire_resistance
		Enums.DamageType.ICE:
			resistance = ice_resistance
		Enums.DamageType.LIGHTNING:
			resistance = lightning_resistance
		Enums.DamageType.POISON:
			resistance = poison_resistance
		Enums.DamageType.MAGIC:
			resistance = magic_resistance

	return damage * (1.0 - resistance)

func _apply_regeneration(delta: float) -> void:
	if health_regeneration_rate > 0:
		heal(health_regeneration_rate * delta)
	elif health_regeneration_rate < 0:
		# Poison/DoT bypasses shield and resistances
		current_health = max(0, current_health + health_regeneration_rate * delta)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			_handle_death()

func _regenerate_shield(delta: float) -> void:
	current_shield = min(max_shield, current_shield + shield_regeneration_rate * delta)
	shield_changed.emit(current_shield, max_shield)

func _process_status_effects(delta: float) -> void:
	for i in range(active_status_effects.size() - 1, -1, -1):
		var instance = active_status_effects[i]
		instance.tick(delta)

		# Apply effect logic
		_apply_status_effect_tick(instance, delta)

		# Emit signal for external listeners
		status_effect_tick.emit(instance, delta)

		# Remove expired effects
		if instance.is_expired():
			status_effect_removed.emit(instance)
			active_status_effects.remove_at(i)

func _apply_status_effect_tick(instance: StatusEffectInstance, delta: float) -> void:
	# Apply default behavior based on effect type
	var power = instance.get_effective_power()

	if power != 0.0:
		if instance.effect.is_beneficial:
			# Beneficial effects heal
			heal(power * delta)
		else:
			# Harmful effects deal damage
			take_damage(power * delta, instance.effect.damage_type)

func _get_status_resistance(effect_id: int) -> float:
	# Map effect IDs to resistance values
	match effect_id:
		StatusEffectsLibrary.StatusEffects.STUN:
			return stun_resistance
		StatusEffectsLibrary.StatusEffects.SLOW:
			return slow_resistance
		StatusEffectsLibrary.StatusEffects.BURN:
			return burn_resistance
		StatusEffectsLibrary.StatusEffects.FREEZE:
			return freeze_resistance
		StatusEffectsLibrary.StatusEffects.BLEED:
			return bleed_resistance
		_:
			return 0.0

func _set_state(new_state: Enums.HealthState) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

func _is_active_state() -> bool:
	return current_state == Enums.HealthState.ALIVE or current_state == Enums.HealthState.RECOVERY

## Public state query functions
func get_state() -> Enums.HealthState:
	return current_state

func is_alive() -> bool:
	return current_state == Enums.HealthState.ALIVE

func is_dead() -> bool:
	return current_state == Enums.HealthState.DEAD

func is_in_recovery() -> bool:
	return current_state == Enums.HealthState.RECOVERY

func is_incapacitated() -> bool:
	return current_state == Enums.HealthState.INCAPACITATED
