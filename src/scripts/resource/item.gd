extends Resource
class_name Item
## Base resource class for all items in the game.
##
## Items can be:
##   - Collectibles (coins, gems, health pickups)
##   - Equipment (weapons, armor)
##   - Consumables (potions, food)
##   - Key items (quest items, keys)
##   - Materials (crafting components)

## Uses centralized enums from Enums autoload:
## - Enums.ItemType (MISC, COLLECTIBLE, CONSUMABLE, EQUIPMENT, KEY_ITEM, MATERIAL)
## - Enums.Rarity (COMMON, UNCOMMON, RARE, EPIC, LEGENDARY)

#region Properties

## Unique identifier for this item (use ItemsLibrary.Items enum)
@export var item_id: int = -1

## Display name
@export var display_name: String = "Item"

## Description shown in UI
@export_multiline var description: String = ""

## Item category
@export var item_type: Enums.ItemType = Enums.ItemType.MISC

## Item rarity
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON

## Icon for UI display
@export var icon: Texture2D = null

## Scene to spawn when dropped in world
@export var world_scene: PackedScene = null

## Can this item stack in inventory?
@export var stackable: bool = true

## Maximum stack size (0 = unlimited)
@export var max_stack: int = 99

## Base value for selling/buying
@export var base_value: int = 1

## Weight for inventory systems (0 = weightless)
@export var weight: float = 0.0

#endregion

#region Methods

## Get the color associated with this item's rarity
func get_rarity_color() -> Color:
	match rarity:
		Enums.Rarity.COMMON:
			return Color.WHITE
		Enums.Rarity.UNCOMMON:
			return Color.GREEN
		Enums.Rarity.RARE:
			return Color.DODGER_BLUE
		Enums.Rarity.EPIC:
			return Color.PURPLE
		Enums.Rarity.LEGENDARY:
			return Color.ORANGE
	return Color.WHITE


## Get the display string for rarity
func get_rarity_name() -> String:
	return Enums.Rarity.keys()[rarity]


## Check if this item can stack with another item
func can_stack_with(other: Item) -> bool:
	if not stackable or not other.stackable:
		return false
	return item_id == other.item_id


## Create a copy of this item
func duplicate_item() -> Item:
	return duplicate(true) as Item

#endregion
