# Procedural Generation Design — Flat Test Map

## Overview

Chunk-based procedural generation system that produces an endlessly extending flat terrain. This serves as the foundational test map for validating AI behaviors, settlement mechanics, and camera systems without hand-crafted level constraints. Uneven terrain (hills, cliffs, caves) is deferred to a future phase.

## Goals

- Infinite horizontal scrolling — world generates as entities explore
- Flat ground plane at a fixed Y level — uniform GRASS terrain, fully passable
- Seamless chunk loading/unloading with no visible seams or hitches
- Integrate with existing WorldGrid, territory, and BT systems without breaking them
- Minimal overhead — chunks are trivial to generate for a flat plane

## Architecture

### Chunk Model

The world is divided into vertical column chunks, each spanning a fixed width in the X axis and the full visible Y range.

```
Chunk Layout (side view):
  y = -2  [ AIR ] [ AIR ] [ AIR ] ...   (empty sky)
  y = -1  [ AIR ] [ AIR ] [ AIR ] ...
  y =  0  [GRASS] [GRASS] [GRASS] ...   (ground surface - walkable)
  y =  1  [ROCK ] [ROCK ] [ROCK ] ...   (subsurface)
  y =  2  [ROCK ] [ROCK ] [ROCK ] ...

  <--- chunk_width tiles in X --->
```

**Constants:**
- `CHUNK_WIDTH`: 16 tiles wide (X axis)
- `GROUND_DEPTH`: 3 tile rows of subsurface rock below ground level
- `SKY_HEIGHT`: 8 tile rows of air above ground level
- `GROUND_Y`: 0 (tile row where the ground surface sits)

A chunk key is a single integer: `chunk_x = floor(cell_x / CHUNK_WIDTH)`.

### Component Responsibilities

#### ChunkManager (`src/scripts/map/chunk_manager.gd`)

Owns chunk lifecycle. Runs in `_process()`, checks entity positions each frame, loads/unloads chunks as needed.

**State:**
- `_loaded_chunks: Dictionary` — chunk_x (int) -> `true`
- `_load_radius: int` — number of chunks to keep loaded around each tracked entity (default 3)
- `_unload_margin: int` — extra chunks beyond load_radius before unloading (default 2)
- `_tracked_entities: Array[Node2D]` — entities that trigger chunk loading (player, roos)

**Flow:**
1. Each frame, collect chunk_x positions of all tracked entities
2. Compute the set of chunks that should be loaded (union of `[entity_chunk - load_radius, entity_chunk + load_radius]` for all entities)
3. Load any missing chunks: generate cell data in WorldGrid, place tiles on TileMapLayer
4. Unload chunks outside `load_radius + unload_margin`: clear tiles from TileMapLayer, optionally evict cell data from WorldGrid

**API:**
```gdscript
func register_entity(entity: Node2D) -> void
func unregister_entity(entity: Node2D) -> void
func force_load_chunk(chunk_x: int) -> void
func is_chunk_loaded(chunk_x: int) -> bool
```

#### WorldGrid Changes

The existing WorldGrid needs small adaptations for unbounded operation:

1. **Remove bounds gating on `get_neighbors()`** — currently filters by `is_in_bounds()`. For infinite terrain, neighbors always exist conceptually. Change to return all four neighbors unconditionally; cells that don't exist yet in `_cells` are treated as UNKNOWN by the territory system (already the default behavior in `get_frontier_cells()`).

2. **Dynamic bounds** — `_bounds` becomes advisory (used for serialization snapshot). `is_in_bounds()` returns `true` for any cell that exists in `_cells`, or is left unchecked by callers that expect dynamic terrain.

3. **New method: `generate_chunk()`** — generates cells for a rectangular region and merges them into `_cells` without clearing existing data.

```gdscript
## Generate cells for a chunk region and merge into the grid.
## Does not overwrite existing cells (preserves scouted/claimed state).
func generate_chunk(region: Rect2i, generator: Callable) -> void:
    for x in range(region.position.x, region.end.x):
        for y in range(region.position.y, region.end.y):
            var pos = Vector2i(x, y)
            if not _cells.has(pos):
                _cells[pos] = generator.call(pos)
    # Expand bounds to include new region
    if _bounds.size == Vector2i.ZERO:
        _bounds = region
    else:
        _bounds = _bounds.merge(region)
```

4. **New method: `evict_chunk()`** — removes cells for a region (only cells with UNKNOWN territory state, to preserve player progress).

```gdscript
## Remove cells that have no player-significant state.
func evict_chunk(region: Rect2i) -> void:
    for x in range(region.position.x, region.end.x):
        for y in range(region.position.y, region.end.y):
            var pos = Vector2i(x, y)
            var cell = _cells.get(pos, {})
            if cell.get("territory_state", Enums.TileState.UNKNOWN) == Enums.TileState.UNKNOWN \
                and cell.get("building") == null:
                _cells.erase(pos)
```

#### TileMapLayer Sync

ChunkManager writes tiles directly to the TileMapLayer when loading a chunk:

```gdscript
func _place_chunk_tiles(chunk_x: int) -> void:
    var start_x = chunk_x * CHUNK_WIDTH
    for x in range(start_x, start_x + CHUNK_WIDTH):
        for y in range(GROUND_Y - SKY_HEIGHT, GROUND_Y + GROUND_DEPTH + 1):
            var pos = Vector2i(x, y)
            if y < GROUND_Y:
                # Sky — no tile (remove if exists)
                _tilemap_layer.erase_cell(pos)
            elif y == GROUND_Y:
                # Ground surface — grass tile
                _tilemap_layer.set_cell(pos, GRASS_SOURCE_ID, GRASS_ATLAS_COORDS)
            else:
                # Subsurface — rock tile
                _tilemap_layer.set_cell(pos, ROCK_SOURCE_ID, ROCK_ATLAS_COORDS)
```

Unloading erases tiles:
```gdscript
func _clear_chunk_tiles(chunk_x: int) -> void:
    var start_x = chunk_x * CHUNK_WIDTH
    for x in range(start_x, start_x + CHUNK_WIDTH):
        for y in range(GROUND_Y - SKY_HEIGHT, GROUND_Y + GROUND_DEPTH + 1):
            _tilemap_layer.erase_cell(Vector2i(x, y))
```

#### ProceduralMap (`src/scripts/map/procedural_map.gd`)

New map script extending BaseMap. Replaces the hand-crafted test stage for procedural testing.

**Responsibilities:**
- Creates an empty TileMapLayer at runtime (or uses a minimal scene with just the TileSet assigned)
- Instantiates and owns ChunkManager
- Overrides `_setup_world_grid()` to skip `load_from_tilemap()` (no pre-placed tiles)
- Registers player and spawned Roos as tracked entities with ChunkManager
- Removes camera bounds (or sets them to very large values) so the camera can follow entities freely

```gdscript
extends BaseMap

@export var player_scene: PackedScene
@export var roo_scene: PackedScene
@export var test_roo_count: int = 3

var chunk_manager: ChunkManager = null


func _setup_world_grid() -> void:
    # Set TileMapLayer reference on WorldGrid without loading tiles
    var terrain_layer = tilemaps.get_node_or_null("TileMapLayer")
    if terrain_layer and GameManager.WorldGridService:
        GameManager.WorldGridService._tilemap_layer = terrain_layer


func _spawn_entities() -> void:
    # Initialize ChunkManager
    chunk_manager = ChunkManager.new()
    chunk_manager.name = "ChunkManager"
    chunk_manager.tilemap_layer = tilemaps.get_node("TileMapLayer")
    add_child(chunk_manager)

    # Spawn player at origin ground level
    if player_scene:
        var player = player_scene.instantiate()
        entities.add_child(player)
        player.global_position = _ground_spawn_position(0)
        chunk_manager.register_entity(player)

    # Spawn test Roos
    for i in range(test_roo_count):
        var roo = roo_scene.instantiate() as Roo
        entities.add_child(roo)
        roo.global_position = _ground_spawn_position(randf_range(-80, 80))
        roo.roo_id = i
        roo.set_profession(Enums.Professions.SCOUT if i > 0 else Enums.Professions.NONE)
        chunk_manager.register_entity(roo)


func _ground_spawn_position(x_offset: float) -> Vector2:
    # Place entity just above ground surface
    var ground_world = GameManager.WorldGridService.cell_to_world(Vector2i(0, GROUND_Y))
    return Vector2(ground_world.x + x_offset, ground_world.y - 8)  # 8px above surface
```

### Flat Terrain Generator

For the flat test map, the generator callable passed to `WorldGrid.generate_chunk()` is trivial:

```gdscript
func _flat_generator(pos: Vector2i) -> Dictionary:
    var terrain: Enums.TerrainType
    if pos.y < ChunkManager.GROUND_Y:
        terrain = Enums.TerrainType.VOID  # Air
    elif pos.y == ChunkManager.GROUND_Y:
        terrain = Enums.TerrainType.GRASS
    else:
        terrain = Enums.TerrainType.ROCK

    var cell = WorldGrid.CELL_DEFAULTS.duplicate()
    cell["terrain"] = terrain
    cell["passable"] = (pos.y <= ChunkManager.GROUND_Y)
    return cell
```

Ground surface (y=0) is GRASS and passable. Below is ROCK and impassable. Above is VOID (air) and passable. This creates a flat walkable surface extending infinitely in both horizontal directions.

## Camera

Current `camera_bounds` in BaseMap constrains the camera to a fixed rectangle. For infinite terrain:

- ProceduralMap sets no camera bounds (or extremely large bounds like `Rect2(-1000000, -1000000, 2000000, 2000000)`)
- Camera follows the player as normal via CameraService
- No Y-axis scrolling needed for the flat plane — the ground is always at the same level

## Integration with Existing Systems

### Territory / Scouting
- Works unchanged. Frontier cells are UNKNOWN neighbors of SCOUTED/CLAIMED cells — as ChunkManager generates new chunks ahead of scouts, fresh UNKNOWN cells appear for them to discover
- `get_frontier_cells()` already checks `_cells.has(neighbor)` so newly generated cells are automatically frontier candidates

### Settlement
- Settlement position is fixed at spawn origin
- Territory expands outward as scouts explore

### Behavior Trees
- `BTFindFrontierTile` finds the nearest frontier cell — new chunks provide fresh frontiers infinitely
- `BTTooFarFromHome` still applies — scouts will return home when too far, preventing them from outrunning chunk generation
- `BTPickRandomNearbyPoint` works as-is since it picks offsets from home_position

### WorldGrid Serialization
- `serialize()` captures all loaded cells — on save, this is only the explored/significant region
- Evicted (UNKNOWN, no-building) cells are not saved, reducing save size
- On load, `deserialize()` restores player-modified cells; ChunkManager regenerates the surrounding terrain

## File Summary

### New Files
| File | Class | Purpose |
|------|-------|---------|
| `src/scripts/map/chunk_manager.gd` | `ChunkManager` | Chunk lifecycle, tile placement |
| `src/scripts/map/procedural_map.gd` | `ProceduralMap` | Test map using procedural generation |
| `src/scenes/maps/procedural_test.tscn` | — | Minimal scene: Node2D + TileMaps/TileMapLayer + MapObjects/SpawnPoints + Entities |

### Modified Files
| File | Changes |
|------|---------|
| `src/scripts/service/world_grid.gd` | Add `generate_chunk()`, `evict_chunk()`; relax bounds in `get_neighbors()` |

## Resource Node Spawning

Chunks occasionally spawn **resource nodes** on the ground surface — special world objects (e.g., a forest grove, ore outcrop, jade deposit) that Roos can convert into **harvest facilities**.

### Spawning Rules
- During chunk generation, each ground-surface cell has a small chance of being designated as a resource node spawn point
- Spawn probability is seeded deterministically from `(world_seed, cell_x)` so regenerating a chunk always produces the same nodes
- Minimum spacing enforced between nodes (e.g., no two nodes within 8 tiles) to avoid clustering
- Resource type is weighted by distance from settlement origin — common resources (wood, stone) spawn everywhere, rarer resources (jade) spawn further out

### Resource Node → Harvest Facility
- A resource node starts as a raw marker on the map (visual indicator, interactable)
- A Roo with the appropriate profession (LUMBERJACK, MINER, etc.) can claim the node and begin constructing a harvest facility
- Once built, the facility produces its resource **indefinitely** — there is no depletion mechanic
- Facilities are upgradeable, with each tier increasing resource income rate
- Upgrades progress alongside the settlement's research/tech tree

### Integration
- Resource nodes are tracked on WorldGrid cells via a new cell key (e.g., `"resource_node"`) or as lightweight scene instances placed by ChunkManager
- The building/facility placed on the cell uses the existing `WorldGrid.set_building()` API
- Eviction skips cells that have resource nodes or buildings (already handled by the `evict_chunk()` guard on building presence)

### Scope
- The spawning infrastructure (probability, placement, persistence) is part of the procedural generation system
- The harvest facility gameplay (construction, upgrading, income rates) is part of the settlement/profession systems and designed separately

## Future Extensions (Not In Scope)

- **Uneven terrain**: Noise-based heightmap varying the ground Y per column — plugs into the generator callable
- **Biomes**: Generator selects terrain types based on x-position or noise regions
- **Vertical chunks**: For caves/multi-level terrain, extend chunk model to Y-axis slices
- **Background parallax**: Procedural sky/mountain layers that scroll with the camera
- **Threaded generation**: Move cell generation off main thread for complex terrain generators
