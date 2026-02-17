# Resource Node Design

## Overview

Resource nodes are world objects representing harvestable deposits — a grove of trees (wood), an ore outcrop (stone), or a jade vein. Roos claim these nodes and construct harvest facilities on top of them, producing resources indefinitely. Facilities are upgradeable alongside the settlement's progression.

Implementation is split into two phases:

- **Phase 1 — Hand-placed nodes on static maps.** Resource nodes are placed manually in the Godot editor as part of hand-crafted map scenes (e.g., test_stage_1). This allows immediate gameplay testing of the claim → build → harvest → upgrade loop without any procedural generation dependency.
- **Phase 2 — Procedural spawning on infinite terrain.** ChunkManager spawns resource nodes automatically during chunk generation using seeded RNG, as described in `PROCEDURAL_GENERATION_DESIGN.md`. Phase 1 code (ResourceNode scene, scripts, enums, WorldGrid integration) carries over unchanged.

## Node Types

| Node Type | Resource | Terrain Affinity | Visual (Placeholder) | Rarity |
|-----------|----------|------------------|----------------------|--------|
| **Grove** | Wood | FOREST | Cluster of trees | Common |
| **Ore Outcrop** | Stone | ROCK | Rocky mound | Common |
| **Jade Deposit** | Jade | JADE_VEIN | Glowing green crystal | Rare |

Each node type maps 1:1 to an existing `ItemsLibrary.Items` resource and an `Enums.BuildingType` facility:

| Node Type | `ItemsLibrary.Items` | Facility `BuildingType` | Profession |
|-----------|---------------------|------------------------|------------|
| Grove | `WOOD` | `LUMBER_MILL` | LUMBERJACK |
| Ore Outcrop | `STONE` | `STONE_QUARRY` | MINER |
| Jade Deposit | `JADE` | `JADE_QUARRY` | MINER |

## Scene Structure

### ResourceNode (`src/scenes/world/resource_node.tscn`)

```
ResourceNode (StaticBody2D)
├── Sprite2D              # Visual representation (placeholder → final texture)
├── CollisionShape2D      # Interaction area
└── InteractionArea (Area2D)
    └── CollisionShape2D  # Overlap detection for Roo proximity
```

Using `StaticBody2D` so the node has a physical presence on the ground that entities walk around. The `InteractionArea` is an `Area2D` for detecting when a Roo is close enough to interact.

### ResourceNode Script (`src/scenes/world/resource_node.gd`)

```gdscript
class_name ResourceNode
extends StaticBody2D

#region Signals

signal claimed(by_roo: Node)
signal facility_built(facility: Node)

#endregion

#region Exports

@export var node_type: Enums.ResourceNodeType = Enums.ResourceNodeType.GROVE
@export var facility_type: Enums.BuildingType = Enums.BuildingType.LUMBER_MILL

#endregion

#region State

## Which resource item this node produces
var resource_id: int = ItemsLibrary.Items.WOOD

## Whether a Roo has claimed this node for construction
var is_claimed: bool = false

## The Roo that claimed this node (null if unclaimed)
var claimed_by: Node = null

## The facility built on this node (null until constructed)
var facility: Node = null

## Grid cell position (set by ChunkManager on spawn)
var cell_pos: Vector2i = Vector2i.ZERO

#endregion

#region Lifecycle

func _ready() -> void:
    _apply_node_type()


## Configure resource_id and visuals based on node_type
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
    # Sprite/texture will be assigned here once art is available

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
```

## Enum Addition

Add to `enums.gd` under a new region:

```gdscript
#region Resource Nodes

## Types of harvestable resource nodes in the world
enum ResourceNodeType {
    GROVE,          ## Trees — produces Wood
    ORE_OUTCROP,    ## Rock formation — produces Stone
    JADE_DEPOSIT,   ## Rare jade crystal — produces Jade
}

#endregion
```

## Facility Upgrade System

Facilities built on resource nodes are upgradeable. Each tier increases the resource income rate. Upgrades are gated by settlement progression and research.

### Upgrade Tiers

| Tier | Name | Income Multiplier | Upgrade Cost | Required Stage |
|------|------|-------------------|-------------|----------------|
| 1 | Basic | 1.0x | (construction cost) | FOUNDING |
| 2 | Improved | 1.5x | 1.5x base cost | ESTABLISHED |
| 3 | Advanced | 2.0x | 2.0x base cost | GROWING |
| 4 | Master | 3.0x | 3.0x base cost + Jade | THRIVING |

### FacilityData

Upgrade state lives on the facility node or as metadata on the WorldGrid cell. A lightweight approach using the existing `BuildingDefinition` pattern:

```gdscript
## Stored per-facility, not as a global definition
var facility_tier: int = 1
var income_multiplier: float = 1.0
var base_income_rate: float = 1.0  # resources per cycle

func get_income_rate() -> float:
    return base_income_rate * income_multiplier
```

Upgrade tiers can be defined in `BuildingLibrary` as an extension of `BuildingDefinition`, or as a standalone `FacilityUpgradeLibrary`. This is a settlement-system concern and will be detailed when implementing the LUMBERJACK/MINER professions.

## Placeholder Visuals

Until final art is ready, each node type uses a distinct colored rectangle or the Godot icon with a tint:

| Node Type | Placeholder | Color |
|-----------|-------------|-------|
| Grove | 32x32 rect | Green `Color(0.2, 0.7, 0.2)` |
| Ore Outcrop | 32x32 rect | Gray `Color(0.5, 0.5, 0.5)` |
| Jade Deposit | 32x32 rect | Jade `Color(0.0, 0.8, 0.5)` |

These can be set programmatically in `_apply_node_type()` using `$Sprite2D.modulate` on a white placeholder texture, or by swapping `$Sprite2D.texture` once real assets exist.

## Phase 1 — Hand-Placed Nodes on Static Maps

Resource nodes are placed manually in the Godot editor inside existing map scenes. This is the immediate implementation target.

### Editor Workflow

1. Open a map scene (e.g., `test_stage_1.tscn`)
2. Add `ResourceNode` instances as children of the `Entities` node (or a dedicated `ResourceNodes` group node under `MapObjects`)
3. Set `node_type` via the inspector `@export` dropdown (GROVE, ORE_OUTCROP, JADE_DEPOSIT)
4. Position visually on the ground surface
5. The node self-configures `resource_id`, `facility_type`, and placeholder color in `_ready()`

### Map Registration

When the map loads, hand-placed resource nodes register themselves with WorldGrid:

```gdscript
# In ResourceNode._ready(), after _apply_node_type():
func _register_with_world_grid() -> void:
    var world_grid = GameManager.WorldGridService if GameManager else null
    if not world_grid:
        return
    cell_pos = world_grid.world_to_cell(global_position)
    if world_grid.has_cell(cell_pos):
        world_grid.set_resource_node(cell_pos, node_type)
```

This keeps WorldGrid as the authoritative spatial data source — BT actions query the grid, not the scene tree, to find available resource nodes.

### Test Stage Integration

`test_stage_1.tscn` gets a few hand-placed nodes near the player spawn for immediate gameplay testing:

- 2 Groves (wood) — close to settlement, within initial territory
- 1 Ore Outcrop (stone) — slightly further, within scout range
- 1 Jade Deposit — far enough to require scouting first

These are placed in the editor and require no code changes to `test_stage_1.gd`.

### What Phase 1 Delivers

- `ResourceNode` scene and script (claim, release, build facility API)
- `ResourceNodeType` enum in `enums.gd`
- WorldGrid `"resource_node"` cell key and `set_resource_node()` / `get_resource_node()` API
- Placeholder visuals (colored rects)
- Hand-placed nodes in test map for validating the full gameplay loop

### What Phase 1 Does NOT Include

- ChunkManager or procedural spawning
- Spawn probability tables or distance-based weighting
- Chunk load/unload lifecycle for resource nodes

---

## Phase 2 — Procedural Spawning on Infinite Terrain

Depends on the chunk-based procedural generation system from `PROCEDURAL_GENERATION_DESIGN.md`. All Phase 1 code carries over unchanged — Phase 2 adds automated placement on top.

### ChunkManager Spawning

During chunk loading, ChunkManager spawns resource nodes on ground-surface cells:

1. For each ground-surface cell in the chunk, a seeded RNG roll determines whether a resource node spawns
2. If spawned, ChunkManager instantiates the `ResourceNode` scene, positions it at `cell_to_world(pos)`, and adds it to the map's `entities` node
3. The node's `_register_with_world_grid()` sets the cell key (same as Phase 1)
4. On chunk unload, resource nodes on unclaimed/unbuilt cells are freed; nodes with claims or facilities persist

### Spawn Weights by Distance

```
distance_from_origin = abs(cell_x)

Grove:        base 5% chance, constant
Ore Outcrop:  base 3% chance, constant
Jade Deposit: 0% within 50 tiles, then 1% scaling to 2% at 200+ tiles
```

- Spawn probability is seeded deterministically from `(world_seed, cell_x)` so regenerating a chunk always produces the same nodes
- Minimum spacing enforced between nodes (e.g., no two nodes within 8 tiles) to avoid clustering
- These values are tuning knobs exposed as constants in ChunkManager or a dedicated spawn table

### What Phase 2 Adds

- Seeded RNG spawning logic in ChunkManager
- Distance-based spawn weight tables
- Minimum spacing enforcement
- Chunk unload guards for resource nodes (parallel to building guards in `evict_chunk()`)

---

## Integration with WorldGrid

A new cell data key tracks resource node presence:

```gdscript
# In WorldGrid CELL_DEFAULTS, add:
"resource_node": -1  # -1 = no node, or Enums.ResourceNodeType value
```

New WorldGrid methods:

```gdscript
## Set a resource node type on a cell
func set_resource_node(cell_pos: Vector2i, node_type: Enums.ResourceNodeType) -> void:
    if not _cells.has(cell_pos):
        return
    _cells[cell_pos]["resource_node"] = node_type
    cell_changed.emit(cell_pos)


## Get the resource node type on a cell (-1 if none)
func get_resource_node(cell_pos: Vector2i) -> int:
    var cell = _cells.get(cell_pos, {})
    return cell.get("resource_node", -1)


## Find all cells with resource nodes (optionally filtered by type)
func get_resource_node_cells(filter_type: int = -1) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for pos in _cells.keys():
        var rn = _cells[pos].get("resource_node", -1)
        if rn >= 0 and (filter_type < 0 or rn == filter_type):
            result.append(pos)
    return result
```

This allows:
- `evict_chunk()` (Phase 2) to skip cells with resource nodes
- BT actions to query for unclaimed resource nodes within range
- Serialization to save/restore node locations across sessions

## File Summary

### New Files (Phase 1)
| File | Class | Purpose |
|------|-------|---------|
| `src/scenes/world/resource_node.gd` | `ResourceNode` | Resource node script with claim/facility API |
| `src/scenes/world/resource_node.tscn` | — | Scene: StaticBody2D + Sprite2D + InteractionArea |

### Modified Files (Phase 1)
| File | Changes |
|------|---------|
| `src/scripts/resource/enums.gd` | Add `ResourceNodeType` enum |
| `src/scripts/service/world_grid.gd` | Add `"resource_node"` to `CELL_DEFAULTS`; add `set_resource_node()`, `get_resource_node()`, `get_resource_node_cells()` |

### Modified Files (Phase 2)
| File | Changes |
|------|---------|
| `src/scripts/map/chunk_manager.gd` | Add resource node spawning during chunk load, cleanup on unload |
| `src/scripts/service/world_grid.gd` | Guard in `evict_chunk()` for resource node presence |
