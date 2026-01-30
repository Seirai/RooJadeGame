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

#region Enums

enum ItemType {
	MISC,           ## Generic item
	COLLECTIBLE,    ## Picked up and counted (coins, gems)
	CONSUMABLE,     ## Single-use items (potions, food)
	EQUIPMENT,      ## Wearable/usable items
	KEY_ITEM,       ## Quest/progression items
	MATERIAL        ## Crafting materials
}

enum Rarity {
	COMMON,         ## White/Gray - 60% base
	UNCOMMON,       ## Green - 25% base
	RARE,           ## Blue - 10% base
	EPIC,           ## Purple - 4% base
	LEGENDARY       ## Orange/Gold - 1% base
}

#endregion

#region Properties

## Unique identifier for this item (use ItemsLibrary.Items enum)
@export var item_id: int = -1

## Display name
@export var display_name: String = "Item"

## Description shown in UI
@export_multiline var description: String = ""

## Item category
@export var item_type: ItemType = ItemType.MISC

## Item rarity
@export var rarity: Rarity = Rarity.COMMON

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
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.DODGER_BLUE
		Rarity.EPIC:
			return Color.PURPLE
		Rarity.LEGENDARY:
			return Color.ORANGE
	return Color.WHITE


## Get the display string for rarity
func get_rarity_name() -> String:
	return Rarity.keys()[rarity]


## Check if this item can stack with another item
func can_stack_with(other: Item) -> bool:
	if not stackable or not other.stackable:
		return false
	return item_id == other.item_id


## Create a copy of this item
func duplicate_item() -> Item:
	return duplicate(true) as Item

#endregion
