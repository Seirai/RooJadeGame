extends Node
## Manages all item definitions and handles item spawning.
##
## Provides centralized management for:
##   - Item registration and lookup
##   - Item spawning in the world
##   - Drop calculations and loot generation
##   - Item rarity weighting

#region Signals

signal item_registered(item_id: int)
signal item_unregistered(item_id: int)
signal item_spawned(item: Node, item_id: int, position: Vector2)
signal item_collected(item_id: int, collector: Node, amount: int)

#endregion

#region Properties

## Registry of all item definitions (item_id -> Item resource)
var _items: Dictionary = {}

## Registry of item world scenes (item_id -> PackedScene)
var _item_scenes: Dictionary = {}

## Base drop weights by rarity
var rarity_weights: Dictionary = {
	Enums.Rarity.COMMON: 60.0,
	Enums.Rarity.UNCOMMON: 25.0,
	Enums.Rarity.RARE: 10.0,
	Enums.Rarity.EPIC: 4.0,
	Enums.Rarity.LEGENDARY: 1.0
}

## Global drop rate modifier (1.0 = normal, 2.0 = double drops)
var global_drop_rate_modifier: float = 1.0

## Global luck modifier (affects rarity rolls)
var global_luck_modifier: float = 1.0

#endregion

#region Lifecycle

func _ready() -> void:
	# Load all items from the static library
	_load_from_library()
	print("ItemService initialized with %d items" % _items.size())


## Load all item definitions from ItemsLibrary
func _load_from_library() -> void:
	# Trigger static initialization if not already done
	ItemsLibrary._static_init()

	# Register all items from ItemsLibrary
	for item in ItemsLibrary.get_all_items():
		register_item(item)

#endregion

#region Item Registration

## Register an item definition
## @param item: Item resource to register
func register_item(item: Item) -> void:
	if item == null or item.item_id < 0:
		push_error("ItemService: Cannot register item with null or invalid ID")
		return

	if _items.has(item.item_id):
		push_warning("ItemService: Item '%d' already registered, replacing." % item.item_id)

	_items[item.item_id] = item

	# Also register world scene if available
	if item.world_scene:
		_item_scenes[item.item_id] = item.world_scene

	item_registered.emit(item.item_id)
	print("ItemService: Registered item '%d'" % item.item_id)


## Register multiple items at once
## @param items: Array of Item resources
func register_items(items: Array) -> void:
	for item in items:
		if item is Item:
			register_item(item)


## Register an item from a resource path
## @param path: Path to Item resource file
func register_item_from_path(path: String) -> void:
	var item = load(path) as Item
	if item:
		register_item(item)
	else:
		push_error("ItemService: Failed to load item from path: %s" % path)


## Register all items from a directory
## @param directory_path: Path to directory containing Item resources
func register_items_from_directory(directory_path: String) -> void:
	var dir = DirAccess.open(directory_path)
	if dir == null:
		push_error("ItemService: Cannot open directory: %s" % directory_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = directory_path.path_join(file_name)
			register_item_from_path(full_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("ItemService: Loaded items from directory: %s" % directory_path)


## Unregister an item
## @param item_id: ID of item to unregister
func unregister_item(item_id: int) -> void:
	if not _items.has(item_id):
		return

	_items.erase(item_id)
	_item_scenes.erase(item_id)
	item_unregistered.emit(item_id)
	print("ItemService: Unregistered item '%d'" % item_id)


## Clear all registered items
func clear_all_items() -> void:
	_items.clear()
	_item_scenes.clear()
	print("ItemService: Cleared all items")

#endregion

#region Item Lookup

## Get an item by ID
## @param item_id: Unique item ID (use ItemsLibrary.Items enum)
## @return: Item resource or null
func get_item(item_id: int) -> Item:
	return _items.get(item_id, null)


## Check if an item is registered
## @param item_id: Unique item ID (use ItemsLibrary.Items enum)
## @return: true if item exists
func has_item(item_id: int) -> bool:
	return _items.has(item_id)


## Get all registered item IDs
## @return: Array of item IDs
func get_all_item_ids() -> Array[int]:
	var ids: Array[int] = []
	for key in _items.keys():
		ids.append(key)
	return ids


## Get all items of a specific type
## @param item_type: ItemType to filter by
## @return: Array of matching Item resources
func get_items_by_type(item_type: Enums.ItemType) -> Array[Item]:
	var result: Array[Item] = []
	for item in _items.values():
		if item.item_type == item_type:
			result.append(item)
	return result


## Get all items of a specific rarity
## @param rarity: Rarity to filter by
## @return: Array of matching Item resources
func get_items_by_rarity(rarity: Enums.Rarity) -> Array[Item]:
	var result: Array[Item] = []
	for item in _items.values():
		if item.rarity == rarity:
			result.append(item)
	return result

#endregion

#region Item Spawning

## Spawn an item in the world
## @param item_id: ID of item to spawn (use ItemsLibrary.Items enum)
## @param position: World position
## @param parent: Parent node (defaults to current scene)
## @return: Spawned item node or null
func spawn_item(item_id: int, position: Vector2, parent: Node = null) -> Node:
	var item = get_item(item_id)
	if item == null:
		push_error("ItemService: Cannot spawn unknown item '%d'" % item_id)
		return null

	var scene = _item_scenes.get(item_id, item.world_scene)
	if scene == null:
		push_error("ItemService: No world scene for item '%d'" % item_id)
		return null

	var spawn_parent = parent if parent else get_tree().current_scene
	if spawn_parent == null:
		push_error("ItemService: No valid parent for item spawn")
		return null

	var instance = scene.instantiate()
	spawn_parent.add_child(instance)

	if instance is Node2D:
		instance.global_position = position

	# Set item data on instance if it has the method
	if instance.has_method("set_item_data"):
		instance.set_item_data(item)
	else:
		instance.set_meta("item_id", item_id)
		instance.set_meta("item_data", item)

	item_spawned.emit(instance, item_id, position)
	return instance


## Spawn an item with random offset
## @param item_id: ID of item to spawn (use ItemsLibrary.Items enum)
## @param position: Center position
## @param spread: Random spread radius
## @param parent: Parent node
## @return: Spawned item node or null
func spawn_item_with_spread(item_id: int, position: Vector2, spread: float = 16.0, parent: Node = null) -> Node:
	var offset = Vector2(
		randf_range(-spread, spread),
		randf_range(-spread, spread)
	)
	return spawn_item(item_id, position + offset, parent)


## Spawn multiple items
## @param item_id: ID of item to spawn (use ItemsLibrary.Items enum)
## @param position: Center position
## @param count: Number to spawn
## @param spread: Random spread radius
## @param parent: Parent node
## @return: Array of spawned item nodes
func spawn_items(item_id: int, position: Vector2, count: int, spread: float = 16.0, parent: Node = null) -> Array[Node]:
	var spawned: Array[Node] = []
	for i in range(count):
		var instance = spawn_item_with_spread(item_id, position, spread, parent)
		if instance:
			spawned.append(instance)
	return spawned

#endregion

#region Drop Calculations

## Roll for a random rarity based on weights
## @param luck_bonus: Additional luck modifier (additive with global)
## @return: Rolled rarity
func roll_rarity(luck_bonus: float = 0.0) -> Enums.Rarity:
	var total_luck = global_luck_modifier + luck_bonus

	# Adjust weights based on luck (luck increases rare drops)
	var adjusted_weights: Dictionary = {}
	var total_weight: float = 0.0

	for rarity in rarity_weights.keys():
		var weight = rarity_weights[rarity]

		# Luck boosts higher rarities, reduces common
		if rarity == Enums.Rarity.COMMON:
			weight = max(1.0, weight / total_luck)
		else:
			weight *= total_luck

		adjusted_weights[rarity] = weight
		total_weight += weight

	# Roll
	var roll = randf() * total_weight
	var cumulative: float = 0.0

	for rarity in adjusted_weights.keys():
		cumulative += adjusted_weights[rarity]
		if roll <= cumulative:
			return rarity

	return Enums.Rarity.COMMON


## Process a drop table and return items to spawn
## @param drop_table: Array of drop entries
## @param luck_bonus: Additional luck modifier
## @return: Array of { "item_id": int, "count": int }
func process_drop_table(drop_table: Array, luck_bonus: float = 0.0) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []

	if drop_table.is_empty():
		return drops

	var total_luck = global_luck_modifier + luck_bonus
	var drop_rate = global_drop_rate_modifier

	for entry in drop_table:
		if not _is_valid_drop_entry(entry):
			continue

		var item_id: int = entry.get("item_id", -1)
		var chance = entry.get("chance", 1.0) * drop_rate
		var count_min = entry.get("count_min", 1)
		var count_max = entry.get("count_max", 1)
		var rarity_required = entry.get("rarity_required", -1)

		# Check rarity requirement if specified
		if rarity_required >= 0:
			var item = get_item(item_id)
			if item and item.rarity < rarity_required:
				continue

		# Roll for drop
		if randf() <= chance:
			var count = randi_range(count_min, count_max)
			if count > 0:
				drops.append({
					"item_id": item_id,
					"count": count
				})

	return drops


## Spawn drops from a drop table at a position
## @param drop_table: Array of drop entries
## @param position: Spawn position
## @param parent: Parent node
## @param luck_bonus: Additional luck modifier
## @return: Array of spawned item nodes
func spawn_drops(drop_table: Array, position: Vector2, parent: Node = null, luck_bonus: float = 0.0) -> Array[Node]:
	var drops = process_drop_table(drop_table, luck_bonus)
	var spawned: Array[Node] = []

	for drop in drops:
		var item_id = drop["item_id"]
		var count = drop["count"]

		var items = spawn_items(item_id, position, count, 24.0, parent)
		spawned.append_array(items)

	return spawned


## Check if a drop entry is valid
func _is_valid_drop_entry(entry) -> bool:
	if not entry is Dictionary:
		return false
	if not entry.has("item_id") or entry["item_id"] < 0:
		return false
	return true

#endregion

#region Item Collection

## Called when an item is collected (for tracking/events)
## @param item_id: ID of collected item (use ItemsLibrary.Items enum)
## @param collector: Node that collected the item
## @param amount: Amount collected
func on_item_collected(item_id: int, collector: Node, amount: int = 1) -> void:
	item_collected.emit(item_id, collector, amount)


## Get the total value of items
## @param items: Array of { "item_id": int, "count": int }
## @return: Total value
func calculate_total_value(items: Array) -> int:
	var total: int = 0
	for entry in items:
		var item = get_item(entry.get("item_id", -1))
		if item:
			total += item.base_value * entry.get("count", 1)
	return total

#endregion
