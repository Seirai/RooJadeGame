extends StaticBody2D
class_name ResourceNode
## A harvestable resource deposit in the world.
##
## Placed on the map (hand-placed or procedurally spawned), resource nodes
## can be claimed by Roos and converted into harvest facilities that produce
## resources indefinitely.

#region Signals

signal claimed(by_roo: Node)
signal facility_built(facility: Node)

#endregion

#region Exports

@export_group("Resource Node")
@export var node_type: Enums.ResourceNodeType = Enums.ResourceNodeType.GROVE

#endregion

#region State

## Building type this node converts into when a facility is constructed
var facility_type: Enums.BuildingType = Enums.BuildingType.LUMBER_MILL

## Which resource item this node produces
var resource_id: int = ItemsLibrary.Items.WOOD

## Whether a Roo has claimed this node for construction
var is_claimed: bool = false

## The Roo that claimed this node (null if unclaimed)
var claimed_by: Node = null

## The facility built on this node (null until constructed)
var facility: Node = null

## Grid cell position (set during WorldGrid registration)
var cell_pos: Vector2i = Vector2i.ZERO

#endregion

#region Placeholder Colors

const COLOR_GROVE: Color = Color(0.2, 0.7, 0.2)
const COLOR_ORE: Color = Color(0.5, 0.5, 0.5)
const COLOR_JADE: Color = Color(0.0, 0.8, 0.5)

#endregion

#region Lifecycle

func _ready() -> void:
	add_to_group("resource_nodes")
	_apply_node_type()
	_apply_placeholder_visual()
	_apply_debug_overlay()
	call_deferred("_register_with_world_grid")


## Configure resource_id and facility_type based on node_type
func _apply_node_type() -> void:
	match node_type:
		Enums.ResourceNodeType.GROVE:
			resource_id = ItemsLibrary.Items.WOOD
			facility_type = Enums.BuildingType.LUMBER_MILL
		Enums.ResourceNodeType.ORE_OUTCROP:
			resource_id = ItemsLibrary.Items.STONE
			facility_type = Enums.BuildingType.STONE_QUARRY
		Enums.ResourceNodeType.JADE_DEPOSIT:
			resource_id = ItemsLibrary.Items.JADE
			facility_type = Enums.BuildingType.JADE_QUARRY


## Set placeholder sprite color based on node type
func _apply_placeholder_visual() -> void:
	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return
	match node_type:
		Enums.ResourceNodeType.GROVE:
			sprite.modulate = COLOR_GROVE
		Enums.ResourceNodeType.ORE_OUTCROP:
			sprite.modulate = COLOR_ORE
		Enums.ResourceNodeType.JADE_DEPOSIT:
			sprite.modulate = COLOR_JADE


## Configure the debug overlay with node type name
func _apply_debug_overlay() -> void:
	var overlay = get_node_or_null("DebugOverlay") as DebugOverlay
	if not overlay:
		return
	var type_name = Enums.ResourceNodeType.keys()[node_type]
	overlay.set_display_name(type_name.capitalize())


## Register this node's cell position with WorldGrid
func _register_with_world_grid() -> void:
	var world_grid = GameManager.WorldGridService if GameManager else null
	if not world_grid:
		return
	cell_pos = world_grid.world_to_cell(global_position)
	if world_grid.has_cell(cell_pos):
		world_grid.set_resource_node(cell_pos, node_type)
		print("ResourceNode: Registered %s at cell %s" % [Enums.ResourceNodeType.keys()[node_type], cell_pos])

#endregion

#region Interaction API

## Claim this node for facility construction. Returns true if successful.
func claim(roo: Node) -> bool:
	if is_claimed:
		return false
	is_claimed = true
	claimed_by = roo
	claimed.emit(roo)
	return true


## Release a claim (e.g., if the Roo is reassigned before building)
func release_claim() -> void:
	is_claimed = false
	claimed_by = null


## Mark the facility as built on this node.
## The node remains as the anchor; the facility is the active building.
func set_facility(built_facility: Node) -> void:
	facility = built_facility
	facility_built.emit(built_facility)


## Whether this node has a completed facility
func has_facility() -> bool:
	return facility != null

#endregion
