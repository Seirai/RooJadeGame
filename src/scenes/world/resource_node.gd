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
## Tile footprint this node occupies (odd dimensions, centered on cell_pos).
## Most resource nodes are 5x5. Adjust per node in the inspector if needed.
@export var footprint_size: Vector2i = Vector2i(5, 5)

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

## Anchor grid cell (center of footprint, set during WorldGrid registration)
var cell_pos: Vector2i = Vector2i.ZERO

## All cells this node occupies (populated during registration)
var _footprint_cells: Array[Vector2i] = []

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


## Register the full footprint with WorldGrid (centered on cell_pos).
## Uses call_deferred so WorldGrid is guaranteed to be loaded first.
func _register_with_world_grid() -> void:
	var world_grid = GameManager.WorldGridService if GameManager else null
	if not world_grid:
		return

	cell_pos = world_grid.world_to_cell(global_position)

	var half_x: int = footprint_size.x / 2
	var half_y: int = footprint_size.y / 2

	_footprint_cells.clear()
	for dx in range(-half_x, half_x + 1):
		for dy in range(-half_y, half_y + 1):
			var fp_cell := cell_pos + Vector2i(dx, dy)
			if world_grid.has_cell(fp_cell):
				world_grid.set_resource_node(fp_cell, node_type)
				_footprint_cells.append(fp_cell)

	print("ResourceNode: Registered %s — %d cells, footprint %s, anchor %s" % [
		Enums.ResourceNodeType.keys()[node_type], _footprint_cells.size(), footprint_size, cell_pos
	])

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


## Convert this resource node into a built facility.
##
## Called by the builder system once construction is complete.
## Clears the resource node footprint from WorldGrid, registers the building
## on all footprint cells, emits facility_built, then removes this node.
## The building node must already be added to the scene tree before calling this.
func convert_to_facility(building: Node) -> void:
	var world_grid = GameManager.WorldGridService if GameManager else null
	if world_grid:
		for fp_cell in _footprint_cells:
			world_grid.clear_resource_node(fp_cell)
			world_grid.set_building(fp_cell, building)

	facility = building
	facility_built.emit(building)
	queue_free()


## Whether this node has a completed facility
func has_facility() -> bool:
	return facility != null

#endregion
