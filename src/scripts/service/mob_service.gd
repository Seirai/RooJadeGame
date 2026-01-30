extends Node
## Manages all character entities (mobs) in the game.
##
## Provides centralized management for playable characters, NPCs, enemies, and allies.
## Handles spawning, tracking, despawning, and lifecycle management of all character entities.
## Uses a team bitmask system for flexible team allegiances that can change at runtime.

## Emitted when a mob is spawned
signal mob_spawned(mob: Node, mob_id: String, team: int)
## Emitted when a mob is despawned/removed
signal mob_despawned(mob_id: String, team: int)
## Emitted when a mob dies
signal mob_died(mob: Node, mob_id: String, team: int)
## Emitted when a mob changes team
signal mob_team_changed(mob: Node, mob_id: String, old_team: int, new_team: int)
## Emitted when the player character spawns
signal player_spawned(player: Node)
## Emitted when the player character dies
signal player_died(player: Node)

## Team definitions (team_name -> bitmask value)
## Teams can be combined using bitwise OR for multi-team allegiances
var teams: Dictionary = {
	"none": 0,           # No team affiliation
	"player": 1 << 0,    # 1   - Player team
	"ally": 1 << 1,      # 2   - Allied NPCs/companions
	"enemy": 1 << 2,     # 4   - Hostile entities
	"neutral": 1 << 3,   # 8   - Neutral NPCs
	"wildlife": 1 << 4   # 16  - Ambient creatures
}

## Reference to the player character
var player: Node = null

## Registry of all active mobs (mob_id -> mob_node)
var _active_mobs: Dictionary = {}

## Registry of mob teams (mob_id -> team_bitmask)
var _mob_teams: Dictionary = {}

## Registry organized by team (team_bitmask -> Array[mob_id])
var _mobs_by_team: Dictionary = {}

## Counter for generating unique mob IDs
var _mob_id_counter: int = 0


func _ready() -> void:
	print("MobService initialized (Team-based)")


## Spawns a mob from a scene
## @param scene: PackedScene or path to scene file
## @param position: World position to spawn at
## @param parent: Parent node to add mob to (defaults to current scene)
## @param team: Team bitmask (default teams["neutral"])
## @param custom_id: Optional custom ID (auto-generated if not provided)
## @return: Spawned mob instance
func spawn_mob(scene, position: Vector2, parent: Node = null, team: int = 0, custom_id: String = "") -> Node:
	# Default to neutral team if 0 is passed
	if team == 0:
		team = teams["neutral"]
	# Load scene if path provided
	var mob_scene: PackedScene = null
	if scene is String:
		mob_scene = load(scene)
	elif scene is PackedScene:
		mob_scene = scene
	else:
		push_error("spawn_mob: scene must be PackedScene or String path")
		return null

	if mob_scene == null:
		push_error("Failed to load mob scene")
		return null

	# Instance the mob
	var mob = mob_scene.instantiate()
	if mob == null:
		push_error("Failed to instantiate mob scene")
		return null

	# Set position
	if mob is Node2D:
		mob.global_position = position
	elif mob is Node3D:
		mob.global_position = Vector3(position.x, 0, position.y)

	# Determine parent
	var spawn_parent = parent
	if spawn_parent == null:
		spawn_parent = get_tree().current_scene

	if spawn_parent == null:
		push_error("No valid parent found for mob spawn")
		mob.queue_free()
		return null

	# Add to scene tree
	spawn_parent.add_child(mob)

	# Generate or use custom ID
	var mob_id = custom_id
	if mob_id.is_empty():
		mob_id = _generate_mob_id()

	# Register the mob
	_register_mob(mob, mob_id, team)

	# Connect to mob signals if available
	_connect_mob_signals(mob, mob_id, team)

	# Emit spawn signal
	mob_spawned.emit(mob, mob_id, team)

	print("Spawned mob: ", mob_id, " (Team: ", team, ") at ", position)

	return mob


## Spawns the player character
## @param scene: Player scene (PackedScene or path)
## @param position: Spawn position
## @param parent: Parent node (defaults to current scene)
## @return: Player instance
func spawn_player(scene, position: Vector2, parent: Node = null) -> Node:
	# Despawn existing player if any
	if player != null:
		despawn_player()

	player = spawn_mob(scene, position, parent, teams["player"], "player")

	if player != null:
		player_spawned.emit(player)
		print("Player spawned at ", position)

	return player


## Despawns the player character
func despawn_player() -> void:
	if player == null:
		return

	despawn_mob("player")
	player = null


## Respawns the player at a position
## @param position: Respawn position
## @return: Player instance
func respawn_player(position: Vector2) -> Node:
	if player == null:
		push_warning("Cannot respawn player: no player scene registered")
		return null

	# Store player scene path before despawning
	var player_scene_path = player.scene_file_path

	despawn_player()

	return spawn_player(player_scene_path, position)


## Despawns a mob by ID
## @param mob_id: Unique ID of the mob
func despawn_mob(mob_id: String) -> void:
	if not _active_mobs.has(mob_id):
		push_warning("Cannot despawn mob: ID not found: ", mob_id)
		return

	var mob = _active_mobs[mob_id]
	var team = _mob_teams.get(mob_id, teams["none"])

	# Disconnect signals
	_disconnect_mob_signals(mob, mob_id, team)

	# Unregister
	_unregister_mob(mob_id)

	# Remove from scene
	if is_instance_valid(mob):
		mob.queue_free()

	# Emit signal
	mob_despawned.emit(mob_id, team)

	print("Despawned mob: ", mob_id)


## Gets a mob by ID
## @param mob_id: Unique mob ID
## @return: Mob node or null
func get_mob(mob_id: String) -> Node:
	return _active_mobs.get(mob_id, null)


## Gets the team of a mob
## @param mob_id: Unique mob ID
## @return: Team bitmask or teams["none"] if not found
func get_mob_team(mob_id: String) -> int:
	return _mob_teams.get(mob_id, teams["none"])


## Changes a mob's team allegiance
## @param mob_id: Unique mob ID
## @param new_team: New team bitmask
func set_mob_team(mob_id: String, new_team: int) -> void:
	if not _active_mobs.has(mob_id):
		push_warning("Cannot set team: mob ID not found: ", mob_id)
		return

	var old_team = _mob_teams.get(mob_id, teams["none"])
	if old_team == new_team:
		return

	var mob = _active_mobs[mob_id]

	# Remove from old team tracking
	_remove_from_team_tracking(mob_id, old_team)

	# Update team
	_mob_teams[mob_id] = new_team

	# Add to new team tracking
	_add_to_team_tracking(mob_id, new_team)

	# Update metadata
	if is_instance_valid(mob):
		mob.set_meta("mob_team", new_team)
		_update_mob_groups(mob, new_team)

	# Emit signal
	mob_team_changed.emit(mob, mob_id, old_team, new_team)

	print("Mob ", mob_id, " changed team from ", old_team, " to ", new_team)


## Gets all mobs on a specific team (exact match)
## @param team: Team bitmask
## @return: Array of mob nodes
func get_mobs_by_team(team: int) -> Array[Node]:
	var mobs: Array[Node] = []
	var mob_ids = _mobs_by_team.get(team, [])

	for mob_id in mob_ids:
		var mob = _active_mobs.get(mob_id, null)
		if mob != null:
			mobs.append(mob)

	return mobs


## Gets all mobs that have ANY of the specified team flags
## @param team_flags: Team bitmask to check against
## @return: Array of mob nodes
func get_mobs_with_any_team(team_flags: int) -> Array[Node]:
	var mobs: Array[Node] = []

	for mob_id in _active_mobs.keys():
		var mob_team = _mob_teams.get(mob_id, teams["none"])
		if mob_team & team_flags:  # Has any matching flags
			var mob = _active_mobs.get(mob_id, null)
			if mob != null:
				mobs.append(mob)

	return mobs


## Gets all mobs that have ALL of the specified team flags
## @param team_flags: Team bitmask to check against
## @return: Array of mob nodes
func get_mobs_with_all_teams(team_flags: int) -> Array[Node]:
	var mobs: Array[Node] = []

	for mob_id in _active_mobs.keys():
		var mob_team = _mob_teams.get(mob_id, teams["none"])
		if (mob_team & team_flags) == team_flags:  # Has all flags
			var mob = _active_mobs.get(mob_id, null)
			if mob != null:
				mobs.append(mob)

	return mobs


## Gets all active player team mobs
## @return: Array of player team nodes
func get_player_team() -> Array[Node]:
	return get_mobs_with_any_team(teams["player"])


## Gets all active allies
## @return: Array of ally nodes
func get_allies() -> Array[Node]:
	return get_mobs_with_any_team(teams["ally"])


## Gets all active enemies
## @return: Array of enemy nodes
func get_enemies() -> Array[Node]:
	return get_mobs_with_any_team(teams["enemy"])


## Gets all active neutral mobs
## @return: Array of neutral mob nodes
func get_neutrals() -> Array[Node]:
	return get_mobs_with_any_team(teams["neutral"])


## Gets count of mobs on a specific team (exact match)
## @param team: Team bitmask
## @return: Number of mobs on that team
func get_team_count(team: int) -> int:
	return _mobs_by_team.get(team, []).size()


## Gets total count of all active mobs
## @return: Total number of active mobs
func get_total_mob_count() -> int:
	return _active_mobs.size()


## Checks if two teams are hostile to each other
## @param team_a: First team bitmask
## @param team_b: Second team bitmask
## @return: true if teams are hostile
func are_teams_hostile(team_a: int, team_b: int) -> bool:
	# Player/Ally vs Enemy
	if (team_a & (teams["player"] | teams["ally"])) and (team_b & teams["enemy"]):
		return true
	if (team_b & (teams["player"] | teams["ally"])) and (team_a & teams["enemy"]):
		return true

	# Same team = not hostile
	if team_a == team_b:
		return false

	return false


## Checks if two teams are friendly to each other
## @param team_a: First team bitmask
## @param team_b: Second team bitmask
## @return: true if teams are friendly
func are_teams_friendly(team_a: int, team_b: int) -> bool:
	# Same team = friendly
	if team_a == team_b:
		return true

	# Player and Ally are friendly
	if (team_a & (teams["player"] | teams["ally"])) and (team_b & (teams["player"] | teams["ally"])):
		return true

	return false


## Despawns all mobs of a specific team (exact match)
## @param team: Team bitmask
func despawn_all_of_team(team: int) -> void:
	var mob_ids = _mobs_by_team.get(team, []).duplicate()

	for mob_id in mob_ids:
		despawn_mob(mob_id)

	print("Despawned all mobs of team: ", team)


## Despawns all mobs with any of the specified team flags
## @param team_flags: Team bitmask
func despawn_all_with_team(team_flags: int) -> void:
	var mob_ids_to_despawn: Array[String] = []

	for mob_id in _active_mobs.keys():
		var mob_team = _mob_teams.get(mob_id, teams["none"])
		if mob_team & team_flags:
			mob_ids_to_despawn.append(mob_id)

	for mob_id in mob_ids_to_despawn:
		despawn_mob(mob_id)

	print("Despawned all mobs with team flags: ", team_flags)


## Despawns all enemies
func despawn_all_enemies() -> void:
	despawn_all_with_team(teams["enemy"])


## Despawns all allies
func despawn_all_allies() -> void:
	despawn_all_with_team(teams["ally"])


## Despawns all mobs except player
func despawn_all_mobs() -> void:
	var mob_ids = _active_mobs.keys().duplicate()

	for mob_id in mob_ids:
		if mob_id != "player":  # Preserve player
			despawn_mob(mob_id)

	print("Despawned all non-player mobs")


## Clears all mobs including player (use for scene transitions)
func clear_all() -> void:
	var mob_ids = _active_mobs.keys().duplicate()

	for mob_id in mob_ids:
		despawn_mob(mob_id)

	player = null
	_mob_id_counter = 0

	print("Cleared all mobs")


## Checks if player is alive and active
## @return: true if player exists and is valid
func is_player_alive() -> bool:
	return player != null and is_instance_valid(player)


## Gets the player position
## @return: Player global position or Vector2.ZERO
func get_player_position() -> Vector2:
	if not is_player_alive():
		return Vector2.ZERO

	if player is Node2D:
		return player.global_position
	elif player is Node3D:
		return Vector2(player.global_position.x, player.global_position.z)

	return Vector2.ZERO


## Finds closest mob to a position
## @param position: Target position
## @param team_filter: Optional team filter (teams["none"] for all mobs)
## @param max_distance: Maximum search distance (-1 for infinite)
## @return: Closest mob node or null
func find_closest_mob(position: Vector2, team_filter: int = 0, max_distance: float = -1.0) -> Node:
	var closest_mob: Node = null
	var closest_distance: float = INF

	var search_mobs: Array[Node] = []

	if team_filter == 0 or team_filter == teams["none"]:
		# Search all mobs
		search_mobs.assign(_active_mobs.values())
	else:
		# Search mobs with any matching team flags
		search_mobs = get_mobs_with_any_team(team_filter)

	for mob in search_mobs:
		if not is_instance_valid(mob):
			continue

		var mob_pos = Vector2.ZERO
		if mob is Node2D:
			mob_pos = mob.global_position
		elif mob is Node3D:
			mob_pos = Vector2(mob.global_position.x, mob.global_position.z)

		var distance = position.distance_to(mob_pos)

		if distance < closest_distance:
			if max_distance < 0 or distance <= max_distance:
				closest_distance = distance
				closest_mob = mob

	return closest_mob


## Finds all mobs within a radius
## @param position: Center position
## @param radius: Search radius
## @param team_filter: Optional team filter (teams["none"] for all mobs)
## @return: Array of mobs within radius
func find_mobs_in_radius(position: Vector2, radius: float, team_filter: int = 0) -> Array[Node]:
	var found_mobs: Array[Node] = []

	var search_mobs: Array[Node] = []

	if team_filter == 0 or team_filter == teams["none"]:
		search_mobs.assign(_active_mobs.values())
	else:
		search_mobs = get_mobs_with_any_team(team_filter)

	for mob in search_mobs:
		if not is_instance_valid(mob):
			continue

		var mob_pos = Vector2.ZERO
		if mob is Node2D:
			mob_pos = mob.global_position
		elif mob is Node3D:
			mob_pos = Vector2(mob.global_position.x, mob.global_position.z)

		if position.distance_to(mob_pos) <= radius:
			found_mobs.append(mob)

	return found_mobs


## Private: Registers a mob
func _register_mob(mob: Node, mob_id: String, team: int) -> void:
	_active_mobs[mob_id] = mob
	_mob_teams[mob_id] = team

	# Add to team tracking
	_add_to_team_tracking(mob_id, team)

	# Add to groups
	mob.add_to_group("mobs")
	_update_mob_groups(mob, team)

	# Store metadata on mob
	mob.set_meta("mob_id", mob_id)
	mob.set_meta("mob_team", team)


## Private: Unregisters a mob
func _unregister_mob(mob_id: String) -> void:
	if not _active_mobs.has(mob_id):
		return

	var mob = _active_mobs[mob_id]
	var team = _mob_teams.get(mob_id, teams["none"])

	# Remove from team tracking
	_remove_from_team_tracking(mob_id, team)

	# Remove from main registries
	_active_mobs.erase(mob_id)
	_mob_teams.erase(mob_id)

	# Remove metadata
	if is_instance_valid(mob):
		mob.remove_meta("mob_id")
		mob.remove_meta("mob_team")


## Private: Adds mob to team tracking
func _add_to_team_tracking(mob_id: String, team: int) -> void:
	if not _mobs_by_team.has(team):
		_mobs_by_team[team] = []

	if mob_id not in _mobs_by_team[team]:
		_mobs_by_team[team].append(mob_id)


## Private: Removes mob from team tracking
func _remove_from_team_tracking(mob_id: String, team: int) -> void:
	if _mobs_by_team.has(team):
		_mobs_by_team[team].erase(mob_id)


## Private: Updates mob's groups based on team
func _update_mob_groups(mob: Node, team: int) -> void:
	# Remove old team groups
	mob.remove_from_group("team_player")
	mob.remove_from_group("team_ally")
	mob.remove_from_group("team_enemy")
	mob.remove_from_group("team_neutral")
	mob.remove_from_group("team_wildlife")

	# Add new team groups based on flags
	if team & teams["player"]:
		mob.add_to_group("team_player")
	if team & teams["ally"]:
		mob.add_to_group("team_ally")
	if team & teams["enemy"]:
		mob.add_to_group("team_enemy")
	if team & teams["neutral"]:
		mob.add_to_group("team_neutral")
	if team & teams["wildlife"]:
		mob.add_to_group("team_wildlife")


## Private: Generates a unique mob ID
func _generate_mob_id() -> String:
	_mob_id_counter += 1
	return "mob_%d" % _mob_id_counter


## Private: Connects to mob signals if available
func _connect_mob_signals(mob: Node, mob_id: String, team: int) -> void:
	# Connect to common mob signals (if they exist)
	if mob.has_signal("died"):
		mob.died.connect(_on_mob_died.bind(mob, mob_id, team))

	if mob.has_signal("health_changed"):
		mob.health_changed.connect(_on_mob_health_changed.bind(mob, mob_id, team))


## Private: Disconnects from mob signals
func _disconnect_mob_signals(mob: Node, mob_id: String, team: int) -> void:
	if not is_instance_valid(mob):
		return

	if mob.has_signal("died") and mob.died.is_connected(_on_mob_died):
		mob.died.disconnect(_on_mob_died)

	if mob.has_signal("health_changed") and mob.health_changed.is_connected(_on_mob_health_changed):
		mob.health_changed.disconnect(_on_mob_health_changed)


## Private: Handler for mob death
func _on_mob_died(mob: Node, mob_id: String, team: int) -> void:
	mob_died.emit(mob, mob_id, team)

	# Handle player death specifically
	if team & teams["player"]:
		player_died.emit(mob)
		print("Player died")

	print("Mob died: ", mob_id, " (Team: ", team, ")")


## Private: Handler for mob health changes
func _on_mob_health_changed(new_health: float, max_health: float, mob: Node, mob_id: String, team: int) -> void:
	# Extensible for future health tracking, UI updates, etc.
	pass
