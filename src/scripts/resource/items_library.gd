extends Node
class_name ItemsLibrary
## Central registry for all item definitions.
##
## Following the StatusEffectsLibrary pattern, this provides a static
## registry of all item definitions in the game.
##
## Usage:
##   var jade = ItemsLibrary.get_item(ItemsLibrary.Items.JADE)
##   var consumables = ItemsLibrary.get_items_by_type(Item.ItemType.CONSUMABLE)
##
## To add new items:
##   1. Add the item to the Items enum
##   2. Create a _create_item_name() factory method
##   3. Call register_item() in _register_all_items()

const Item = preload("res://src/scripts/resource/item.gd")

## All item IDs in the game
enum Items {
	WOOD,
	STONE,
	JADE,
}

## Dictionary of all registered items [Items -> Item]
static var _items: Dictionary = {}

## Flag to prevent double initialization
static var _initialized: bool = false

## Initialize all item definitions
static func _static_init() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all_items()

static func _register_all_items() -> void:
	# Materials
	register_item(_create_wood())
	register_item(_create_stone())
	register_item(_create_jade())

	print("ItemsLibrary: Registered %d items" % _items.size())


#region Registration & Lookup

## Register an item in the library
static func register_item(item: Item) -> void:
	if item and item.item_id >= 0:
		_items[item.item_id] = item


## Get an item by its ID
static func get_item(item_id: Items) -> Item:
	_ensure_initialized()
	return _items.get(item_id, null)


## Check if an item exists
static func has_item(item_id: Items) -> bool:
	_ensure_initialized()
	return _items.has(item_id)


## Get all registered item IDs
static func get_all_item_ids() -> Array[int]:
	_ensure_initialized()
	var ids: Array[int] = []
	for id in _items.keys():
		ids.append(id)
	return ids


## Get all items
static func get_all_items() -> Array[Item]:
	_ensure_initialized()
	var items_array: Array[Item] = []
	for item in _items.values():
		items_array.append(item)
	return items_array


## Get items by type
static func get_items_by_type(item_type: Item.ItemType) -> Array[Item]:
	_ensure_initialized()
	var result: Array[Item] = []
	for item in _items.values():
		if item.item_type == item_type:
			result.append(item)
	return result


## Get items by rarity
static func get_items_by_rarity(rarity: Item.Rarity) -> Array[Item]:
	_ensure_initialized()
	var result: Array[Item] = []
	for item in _items.values():
		if item.rarity == rarity:
			result.append(item)
	return result


## Ensure the library is initialized before access
static func _ensure_initialized() -> void:
	if not _initialized:
		_static_init()

#endregion


# ============================================================================
# Item Definitions - Materials
# ============================================================================

static func _create_wood() -> Item:
	var item = Item.new()
	item.item_id = Items.WOOD
	item.display_name = "Wood"
	item.description = "Basic crafting material from trees."
	item.item_type = Item.ItemType.MATERIAL
	item.rarity = Item.Rarity.COMMON
	item.stackable = true
	item.max_stack = 999
	item.base_value = 2
	return item


static func _create_stone() -> Item:
	var item = Item.new()
	item.item_id = Items.STONE
	item.display_name = "Stone"
	item.description = "Basic crafting material from rocks."
	item.item_type = Item.ItemType.MATERIAL
	item.rarity = Item.Rarity.COMMON
	item.stackable = true
	item.max_stack = 999
	item.base_value = 2
	return item


static func _create_jade() -> Item:
	var item = Item.new()
	item.item_id = Items.JADE
	item.display_name = "Jade"
	item.description = "A piece of meteorite rock that is used as a central currency ."
	item.item_type = Item.ItemType.MATERIAL
	item.rarity = Item.Rarity.COMMON
	item.stackable = true
	item.max_stack = 999
	item.base_value = 25
	return item
