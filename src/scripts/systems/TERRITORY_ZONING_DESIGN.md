# Territory & World Grid Design

Design proposition for a foundational tile grid system and the territory layer built on top of it.

## Problem

Currently there is no logical grid layer. The TileMapLayer is purely visual, settlement tracks tiles in a disconnected dictionary, and buildings are registered by node reference with no grid position. Every system that needs spatial tile awareness (territory, building placement, resource nodes, pathfinding) would end up inventing its own grid -- so we need a shared foundation.

## Architecture

```
WorldGrid (service)          ← foundational grid, owns cell data
    │
    ├── read by: TerritoryManager   ← territory state per cell
    ├── read by: BuildingManager    ← building placement locked to grid
    ├── read by: Scout AI           ← frontier queries
    └── syncs:   TileMapLayer       ← visual representation
```

**WorldGrid** is the authoritative logical grid. It exists independently of the visual TileMapLayer and can be procedurally generated. All game systems query and write to it through a shared API.

---

## WorldGrid Service

A new service accessible via GameManager. Not a settlement manager -- it is a game-wide system that the settlement (and anything else) consumes.

### Cell Data

Each grid cell stores a lightweight dictionary:

```gdscript
# WorldGrid._cells: Dictionary  # Vector2i -> CellData dict
{
    "terrain": TerrainType.GRASS,
    "passable": true,
    "building": null,          # Building node reference (or null)
    "territory_state": TileState.UNKNOWN,
    "threat_level": 0,
    "scouted_at": 0.0,
    "claimed_at": 0.0,
    "scouted_by": -1,
}
```

Terrain is the base layer populated on map load or generation. Territory state and building references are written by settlement managers at runtime.

### Terrain Types

```gdscript
enum TerrainType {
    VOID,       ## Out of bounds / impassable edge
    GRASS,      ## Standard buildable ground
    FOREST,     ## Tree cover, harvestable by Lumberjacks
    ROCK,       ## Stone deposits, mineable
    WATER,      ## Impassable, no building
    JADE_VEIN,  ## Rare jade deposit
}
```

### Specification

```
WorldGrid (GameManager service)
├── State:
│   ├── _cells: Dictionary          # Vector2i -> CellData
│   ├── _bounds: Rect2i             # World grid extents
│   └── _tile_size: int             # Pixels per tile (synced with TileMapLayer)
├── Coordinate API:
│   ├── world_to_cell(world_pos) -> Vector2i
│   ├── cell_to_world(cell_pos) -> Vector2
│   ├── is_in_bounds(cell_pos) -> bool
│   └── get_neighbors(cell_pos) -> Array[Vector2i]
├── Cell API:
│   ├── get_cell(cell_pos) -> CellData
│   ├── get_terrain(cell_pos) -> TerrainType
│   ├── is_passable(cell_pos) -> bool
│   ├── is_buildable(cell_pos) -> bool   # passable + no building + CLAIMED
│   ├── get_building(cell_pos) -> Node
│   ├── set_building(cell_pos, building)
│   └── clear_building(cell_pos)
├── Territory API:
│   ├── get_territory_state(cell_pos) -> TileState
│   ├── set_territory_state(cell_pos, state)
│   ├── get_cells_by_territory(state) -> Array[Vector2i]
│   └── get_frontier_cells() -> Array[Vector2i]
├── Generation:
│   ├── generate(bounds, seed)        # Procedural generation
│   └── load_from_tilemap(tilemap_layer)  # Import from existing scene
├── Signals:
│   ├── cell_changed(cell_pos)
│   ├── building_placed(cell_pos, building)
│   └── building_removed(cell_pos)
```

### Coordinate Conversion

WorldGrid bridges pixel space and grid space, staying in sync with the TileMapLayer:

```gdscript
var _tilemap_layer: TileMapLayer  # Reference to the visual layer

func world_to_cell(world_pos: Vector2) -> Vector2i:
    return _tilemap_layer.local_to_map(world_pos)

func cell_to_world(cell_pos: Vector2i) -> Vector2:
    return _tilemap_layer.map_to_local(cell_pos)
```

All game systems use these methods rather than doing their own coordinate math. If tile size or layout changes, only WorldGrid needs updating.

### Procedural Generation

WorldGrid can be populated in two ways:

**1. From existing TileMapLayer (current maps)**

```gdscript
func load_from_tilemap(tilemap_layer: TileMapLayer) -> void:
    _tilemap_layer = tilemap_layer
    for cell_pos in tilemap_layer.get_used_cells():
        var source_id = tilemap_layer.get_cell_source_id(cell_pos)
        var atlas_coords = tilemap_layer.get_cell_atlas_coords(cell_pos)
        _cells[cell_pos] = _terrain_from_tile(source_id, atlas_coords)
```

**2. Procedural generation (future)**

```gdscript
func generate(bounds: Rect2i, world_seed: int) -> void:
    var rng = RandomNumberGenerator.new()
    rng.seed = world_seed
    _bounds = bounds

    for x in range(bounds.position.x, bounds.end.x):
        for y in range(bounds.position.y, bounds.end.y):
            var pos = Vector2i(x, y)
            _cells[pos] = _generate_cell(pos, rng)

    _sync_tilemap()  # Write generated data to TileMapLayer for rendering
```

Generation writes logical data first, then syncs to the visual TileMapLayer. The TileMapLayer becomes a rendering target, not the source of truth.

---

## BaseMap Integration

BaseMap gains a reference to WorldGrid and initializes it from the scene's TileMapLayer:

```gdscript
# base_map.gd additions
func _initialize_map() -> void:
    _setup_world_grid()  # New
    _setup_camera_bounds()
    _setup_physics()
    _play_bgm()

func _setup_world_grid() -> void:
    var terrain_layer = tilemaps.get_node("TileMapLayer")
    GameManager.WorldGrid.load_from_tilemap(terrain_layer)
```

For procedurally generated maps, a subclass overrides this to call `generate()` instead.

---

## Territory Layer

Territory is no longer a standalone data model. It reads and writes the `territory_state` field on WorldGrid cells.

### Tile States

```
UNKNOWN  →  SCOUTED  →  CLAIMED
  (fog)     (visible)   (owned / buildable)
```

| State | Description |
|-------|-------------|
| `UNKNOWN` | Not yet explored. Hidden by fog of war. |
| `SCOUTED` | Revealed by a Scout. Visible but not owned. May contain threats. |
| `CLAIMED` | Absorbed into settlement territory. Buildable if passable. |

### TerritoryManager

Operates on WorldGrid cells rather than a separate dictionary:

```
TerritoryManager
├── Operates on: WorldGrid cells (territory_state, threat_level, scouted_at, claimed_at)
├── Methods:
│   ├── scout_tile(cell_pos, scout_roo_id)
│   ├── try_claim_tile(cell_pos)
│   ├── get_tile_state(cell_pos) -> TileState
│   ├── get_claimed_tiles() -> Array[Vector2i]
│   ├── get_frontier_tiles() -> Array[Vector2i]
│   └── process_claiming(delta)
├── Signals:
│   ├── tile_scouted(cell_pos)
│   ├── tile_claimed(cell_pos)
│   └── tile_threat_changed(cell_pos, threat_level)
```

### Claiming Rules

A `SCOUTED` cell becomes `CLAIMED` when:

1. `threat_level == 0` (no hostile presence)
2. Cell is **adjacent** to an existing `CLAIMED` cell (contiguous expansion)
3. A configurable **claim delay** has elapsed since scouting

The claim delay is reduced by the `EXPLORATION_GEAR` research tech.

---

## Building Placement

Buildings snap to the grid and occupy cells. BuildingManager uses WorldGrid for placement validation:

```gdscript
# BuildingManager.construct() uses WorldGrid
func construct(building_type: Enums.BuildingType, cell_pos: Vector2i) -> Node:
    var world_grid = GameManager.WorldGrid

    if not world_grid.is_buildable(cell_pos):
        return null

    var cost = BuildingLibrary.get_construction_cost(building_type)
    if not _resource_manager.can_afford(cost):
        return null

    _resource_manager.spend(cost)

    var building = _instantiate_building(building_type)
    building.global_position = world_grid.cell_to_world(cell_pos)
    world_grid.set_building(cell_pos, building)

    return building
```

`is_buildable()` checks all layers: terrain passable, no existing building, and territory CLAIMED.

---

## Visualization

### Layer Structure

```
TileMaps (Node2D)
├── TileMapLayer       # Base terrain (source of truth for existing maps,
│                      #   render target for procedural maps)
├── TerritoryOverlay   # Renders claimed borders
└── FogOfWar           # Hides UNKNOWN cells
```

### Visual Sync

WorldGrid emits `cell_changed` whenever a cell updates. A visualization script listens and updates the overlay layers:

```gdscript
func _on_cell_changed(cell_pos: Vector2i) -> void:
    var cell = GameManager.WorldGrid.get_cell(cell_pos)
    _update_fog(cell_pos, cell.territory_state)
    _update_territory_overlay(cell_pos, cell.territory_state)
```

---

## Scout Integration

Scouts autonomously explore the frontier:

1. Scout queries `territory_manager.get_frontier_tiles()` for UNKNOWN cells adjacent to known territory
2. Scout picks the nearest frontier cell and moves toward `WorldGrid.cell_to_world(target)`
3. On arrival, scout calls `territory_manager.scout_tile(cell_pos, roo_id)`
4. If threats are present, scout calls `settlement.report_threat(position, type)`
5. Scout returns to frontier and repeats

`EXPLORATION_GEAR` research: reduces claim delay, increases scout reveal radius.

---

## Serialization

WorldGrid serializes the logical grid. The visual TileMapLayer is rebuilt from it on load:

```gdscript
func serialize() -> Dictionary:
    var cells: Array = []
    for pos in _cells.keys():
        var cell = _cells[pos]
        cells.append({
            "x": pos.x, "y": pos.y,
            "terrain": cell.terrain,
            "territory_state": cell.territory_state,
            "threat_level": cell.threat_level,
            "scouted_at": cell.scouted_at,
            "claimed_at": cell.claimed_at,
        })
    return {
        "bounds": {"x": _bounds.position.x, "y": _bounds.position.y,
                   "w": _bounds.size.x, "h": _bounds.size.y},
        "seed": _world_seed,
        "cells": cells,
    }
```

Building references are not serialized here -- BuildingManager handles that separately since buildings are scene nodes.

---

## New Enums

```gdscript
#region World Grid

enum TerrainType {
    VOID,
    GRASS,
    FOREST,
    ROCK,
    WATER,
    JADE_VEIN,
}

enum TileState {
    UNKNOWN,
    SCOUTED,
    CLAIMED,
}

#endregion
```

---

## Implementation Phases

### Phase 1: WorldGrid Service
- Add `TerrainType` and `TileState` enums to Enums.gd
- Create WorldGrid service with cell data model, coordinate API, cell API
- Register in GameManager
- Implement `load_from_tilemap()` to bootstrap from existing scenes

### Phase 2: BaseMap Integration
- Wire `base_map.gd` to initialize WorldGrid from its TileMapLayer on `_ready()`
- Test coordinate conversion roundtrips

### Phase 3: TerritoryManager
- Create TerritoryManager operating on WorldGrid cells
- Implement scouting, claiming, frontier queries
- Implement `process_claiming(delta)` tick with adjacency + delay logic
- Wire into Settlement facade

### Phase 4: Building Placement on Grid
- Update BuildingManager to use WorldGrid for placement validation
- Snap buildings to grid via `cell_to_world()`
- Track occupied cells via `set_building()` / `clear_building()`

### Phase 5: Visualization
- Create TerritoryOverlay TileMapLayer
- Create FogOfWar TileMapLayer
- Listen to `cell_changed` signal for visual sync

### Phase 6: Procedural Generation (future)
- Implement `generate(bounds, seed)` with noise-based terrain distribution
- Sync generated data to TileMapLayer for rendering
- Settlement origin placement logic
