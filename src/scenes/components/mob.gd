extends CharacterBody2D
class_name Mob
## Base class for all character entities (players, NPCs, enemies).
##
## Provides movement, jumping, dashing, and action execution.
## Can be controlled by ControllerComponent (player input) or AI.
##
## Action API (for controllers and AI):
##   - set_move_input(direction, delta): Set horizontal movement (-1 to 1)
##   - set_jump_input(held, delta): Set jump state (true = holding jump)
##   - attack(): Trigger attack action
##   - interact(): Trigger interact action
##   - dash(): Trigger dash action
##
## All action methods return bool indicating success and are safe to call every frame.

#region Signals

signal exp_gained(amount: int, new_total: int)
signal leveled_up(new_level: int)
signal action_executed(action_name: String)
signal movement_state_changed(is_grounded: bool)

#endregion

#region Components

var health_component: HealthComponent = null
var stat_container: StatContainer = null
var mana_component: ManaComponent = null
var controller_component: ControllerComponent = null

#endregion

#region Stat Accessors

var level: int:
	get: return stat_container.level if stat_container else 1

var attack_power: float:
	get: return stat_container.attack_power if stat_container else 0.0

var defense: float:
	get: return stat_container.defense if stat_container else 0.0

var crit_chance: float:
	get: return stat_container.crit_chance if stat_container else 0.0

var crit_multiplier: float:
	get: return stat_container.crit_multiplier if stat_container else 1.0

var max_mana: float:
	get: return mana_component.max_mana if mana_component else 0.0

var current_mana: float:
	get: return mana_component.current_mana if mana_component else 0.0

#endregion

#region Exported Properties

@export_group("Movement")
@export var move_speed: float = 200.0
@export var jump_acceleration: float = -800.0
@export var max_jump_velocity: float = -500.0
@export var max_jump_time: float = 0.3
@export var max_fall_speed: float = 1000.0
@export_range(0.0, 1.0) var air_control: float = 0.8
@export var acceleration: float = 10.0
@export var friction: float = 15.0

@export_group("Advanced Movement")
@export var max_jumps: int = 1
@export var can_wall_jump: bool = false
@export var wall_jump_velocity: Vector2 = Vector2(300, -350)
@export var can_dash: bool = false
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

@export_group("Physics")
@export var gravity_scale: float = 1.0
@export var coyote_time: float = 0.1

#endregion

#region State

var jumps_remaining: int = 1
var is_dashing: bool = false
var facing_direction: int = 1
var movement_locked: bool = false
var was_grounded: bool = false
var coyote_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_jumping: bool = false
var jump_hold_timer: float = 0.0
var sprite_node: Node = null

#endregion

#region Lifecycle

func _ready() -> void:
	# Get component references
	health_component = get_node_or_null("Health") as HealthComponent
	stat_container = get_node_or_null("Stats") as StatContainer
	mana_component = get_node_or_null("Mana") as ManaComponent
	controller_component = get_node_or_null("Controller") as ControllerComponent

	jumps_remaining = max_jumps
	_find_sprite_node()

	# Connect health signals
	if health_component:
		health_component.died.connect(_on_health_died)
		health_component.revived.connect(_on_health_revived)

	# Connect stat signals
	if stat_container:
		stat_container.exp_gained.connect(func(amount, new_total): exp_gained.emit(amount, new_total))
		stat_container.leveled_up.connect(func(new_level): leveled_up.emit(new_level))
		stat_container.initialize_components(health_component, mana_component)


func _physics_process(delta: float) -> void:
	if not health_component or not health_component.is_alive():
		return

	_update_timers(delta)
	_update_grounded_state()
	_apply_gravity(delta)
	move_and_slide()


func _update_grounded_state() -> void:
	var currently_grounded = is_on_floor()

	if currently_grounded != was_grounded:
		movement_state_changed.emit(currently_grounded)
		was_grounded = currently_grounded

	if currently_grounded:
		coyote_timer = coyote_time
		jumps_remaining = max_jumps
		if is_jumping:
			is_jumping = false
			jump_hold_timer = 0.0
	else:
		coyote_timer -= get_physics_process_delta_time()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor() and not is_jumping:
		velocity.y += get_gravity().y * gravity_scale * delta
		velocity.y = min(velocity.y, max_fall_speed)


func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

#endregion

#region Controller Registration

## Called by ControllerComponent to get the action map.
## Returns a dictionary mapping action names to callables.
## AI can also use these same methods directly.
func _register_controller(_controller: ControllerComponent) -> Dictionary:
	return {
		# Continuous actions (called every frame with value + delta)
		"move": Callable(self, "set_move_input"),
		# Held actions (called every frame with held state + delta)
		"jump": Callable(self, "set_jump_input"),
		# Trigger actions (called once when activated)
		"attack": Callable(self, "attack"),
		"interact": Callable(self, "interact"),
		"dash": Callable(self, "dash"),
	}

#endregion

#region Action API - Movement

## Sets horizontal movement input. Call every frame.
## @param direction: -1 (left) to 1 (right), 0 = no input
## @param delta: Frame delta time
func set_move_input(direction: float, delta: float) -> void:
	if movement_locked or is_dashing:
		return
	if not health_component or not health_component.is_alive():
		return

	var dir = clamp(direction, -1.0, 1.0)

	# Update facing direction
	if abs(dir) > 0.1:
		facing_direction = 1 if dir > 0 else -1
		_update_sprite_direction()

	# Calculate target velocity
	var target_velocity = dir * move_speed
	var control_factor = air_control if not is_on_floor() else 1.0

	if abs(dir) > 0.1:
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * move_speed * delta * control_factor)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * move_speed * delta * control_factor)

#endregion

#region Action API - Jump

## Sets jump input state. Call every frame.
## @param held: true if jump button is held
## @param delta: Frame delta time
func set_jump_input(held: bool, delta: float) -> void:
	if movement_locked:
		return
	if not health_component or not health_component.is_alive():
		return

	var grounded = is_on_floor()

	# Start jump
	if held and not is_jumping:
		if grounded or coyote_timer > 0 or jumps_remaining > 0:
			is_jumping = true
			jump_hold_timer = 0.0
			if grounded or coyote_timer > 0:
				coyote_timer = 0
				jumps_remaining = max_jumps - 1
			else:
				jumps_remaining -= 1

	# Continue jump (apply acceleration)
	if is_jumping and held and jump_hold_timer < max_jump_time:
		jump_hold_timer += delta
		velocity.y += jump_acceleration * delta
		velocity.y = max(velocity.y, max_jump_velocity)
	elif is_jumping and (not held or jump_hold_timer >= max_jump_time):
		is_jumping = false

#endregion

#region Action API - Abilities

## Triggers an attack action.
## @return: true if attack was executed
func attack() -> bool:
	if movement_locked:
		return false
	if not health_component or not health_component.is_alive():
		return false

	action_executed.emit("attack")
	return true


## Triggers an interact action.
## @return: true if interact was executed
func interact() -> bool:
	if movement_locked:
		return false
	if not health_component or not health_component.is_alive():
		return false

	action_executed.emit("interact")
	return true


## Triggers a dash in the current facing direction.
## @return: true if dash was executed
func dash() -> bool:
	if not can_dash or is_dashing or movement_locked or dash_cooldown_timer > 0:
		return false
	if not health_component or not health_component.is_alive():
		return false

	is_dashing = true
	movement_locked = true
	velocity.x = facing_direction * dash_speed
	velocity.y = 0
	dash_cooldown_timer = dash_cooldown

	get_tree().create_timer(dash_duration).timeout.connect(_on_dash_ended)
	action_executed.emit("dash")
	return true


## Performs a wall jump if touching a wall.
## @return: true if wall jump was executed
func wall_jump() -> bool:
	if not can_wall_jump or movement_locked:
		return false
	if not health_component or not health_component.is_alive():
		return false
	if is_on_floor() or not is_on_wall():
		return false

	var wall_normal = get_wall_normal()
	velocity.x = wall_normal.x * wall_jump_velocity.x
	velocity.y = wall_jump_velocity.y
	facing_direction = int(sign(wall_normal.x))
	_update_sprite_direction()
	jumps_remaining = max_jumps - 1
	return true


## Applies knockback force.
## @param direction: Knockback direction (will be normalized)
## @param force: Knockback strength
func apply_knockback(direction: Vector2, force: float) -> void:
	if not health_component or not health_component.is_alive():
		return
	velocity = direction.normalized() * force

#endregion

#region Movement Lock

## Locks all movement for a duration (or indefinitely if duration = 0).
func lock_movement(duration: float = 0.0) -> void:
	movement_locked = true
	if duration > 0:
		get_tree().create_timer(duration).timeout.connect(unlock_movement)


## Unlocks movement.
func unlock_movement() -> void:
	movement_locked = false

#endregion

#region Mana

func restore_mana(amount: float) -> void:
	if mana_component:
		mana_component.restore_mana(amount)


func consume_mana(amount: float) -> bool:
	return mana_component.consume_mana(amount) if mana_component else false


func get_mana_percent() -> float:
	return mana_component.get_mana_percent() if mana_component else 0.0

#endregion

#region State Queries

func is_grounded() -> bool:
	return is_on_floor()


func is_airborne() -> bool:
	return not is_on_floor()


func is_alive() -> bool:
	return health_component != null and health_component.is_alive()


func get_health_percent() -> float:
	if health_component == null:
		return 0.0
	return health_component.current_health / health_component.max_health if health_component.max_health > 0 else 0.0


func is_jump_active() -> bool:
	return is_jumping


func is_dash_on_cooldown() -> bool:
	return dash_cooldown_timer > 0


func get_dash_cooldown_remaining() -> float:
	return max(dash_cooldown_timer, 0.0)

#endregion

#region Internal

func _find_sprite_node() -> void:
	for child in get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			sprite_node = child
			return


func _update_sprite_direction() -> void:
	if sprite_node and (sprite_node is AnimatedSprite2D or sprite_node is Sprite2D):
		sprite_node.flip_h = facing_direction < 0


func _on_dash_ended() -> void:
	is_dashing = false
	movement_locked = false


func _on_health_died() -> void:
	movement_locked = true
	velocity = Vector2.ZERO


func _on_health_revived() -> void:
	movement_locked = false
	if mana_component:
		mana_component.refill_mana()

#endregion
