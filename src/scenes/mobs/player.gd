extends Mob
class_name Player
## Player character class.
##
## Extends Mob with player-specific functionality including camera following,
## animation handling, and any player-specific abilities.

#region Signals

## Emitted when player takes damage (for UI feedback)
signal player_damaged(amount: float, new_health: float)
## Emitted when player collects something
signal item_collected(item_type: String, amount: int)

#endregion

#region Properties

## Reference to camera (optional, for camera following)
var camera: Camera2D = null

#endregion

#region Lifecycle

func _ready() -> void:
	super._ready()

	# Connect to health for player-specific feedback
	if health_component:
		health_component.damage_taken.connect(_on_player_damaged)

	# Find or create camera
	_setup_camera()

	print("Player ready - Controller: ", controller_component != null)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update animations based on state
	_update_animations()

	# Update camera position
	_update_camera()

#endregion

#region Camera

func _setup_camera() -> void:
	# Try to find existing camera in scene
	camera = get_viewport().get_camera_2d()

	if camera == null:
		# Create camera if none exists
		camera = Camera2D.new()
		camera.enabled = true
		get_tree().root.add_child(camera)

	# Register with CameraService
	if GameManager and GameManager.CameraService:
		GameManager.CameraService.register_camera("player", camera)
		GameManager.CameraService.set_follow_target(self)


func _update_camera() -> void:
	# CameraService handles following now
	pass

#endregion

#region Animations

func _update_animations() -> void:
	if not sprite_node or not sprite_node is AnimatedSprite2D:
		return

	var animated_sprite = sprite_node as AnimatedSprite2D

	# Determine animation based on state
	if not health_component or not health_component.is_alive():
		_play_animation(animated_sprite, "death")
		return

	if is_dashing:
		_play_animation(animated_sprite, "dash")
	elif not is_on_floor():
		if velocity.y < 0:
			_play_animation(animated_sprite, "jump")
		else:
			_play_animation(animated_sprite, "fall")
	elif abs(velocity.x) > 10:
		_play_animation(animated_sprite, "run")
	else:
		_play_animation(animated_sprite, "idle")

	# Flip sprite based on facing direction
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0


func _play_animation(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	elif sprite.animation != "idle" and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

#endregion

#region Signal Handlers

func _on_player_damaged(amount: float, _source) -> void:
	if health_component:
		player_damaged.emit(amount, health_component.current_health)

#endregion

#region Player Actions

## Override attack for player-specific behavior
func attack() -> bool:
	if not super.attack():
		return false

	_perform_attack()
	return true


## Override interact for player-specific behavior
func interact() -> bool:
	if not super.interact():
		return false

	_perform_interact()
	return true


func _perform_attack() -> void:
	# TODO: Implement attack logic
	print("Player attack!")


func _perform_interact() -> void:
	# TODO: Implement interaction logic (check for nearby interactables)
	print("Player interact!")

#endregion
