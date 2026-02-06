# Forest Kingdom Tileset Reference

Tileset resource: `res://src/assets/tilesets/forest-kingdom/forest-kingdom.tres`
Tile size: 16x16 pixels
Physics layer 0: collision_layer = 1

---

## Sources

| Source ID | Texture | Dimensions | Grid | Description |
|-----------|---------|------------|------|-------------|
| 0 | `grass-stone-terrain.png` | 144x208 px | 9 cols x 13 rows | Natural terrain: grass surfaces, stone cliffs, cave entrance |
| 1 | `town1.png` | 256x320 px | 16 cols x 20 rows | Structures: rooftops, walls, doors, props, water/dock |
| -- | `trees1.png` (unused) | 560x480 px | -- | Tree sprites (green + autumn), not in tileset |

---

## Source 0: grass-stone-terrain.png

Natural terrain atlas. Grass surfaces are walkable (no collision). Stone/cliff tiles are solid (have collision).

### Visual Layout

```
Col:  0    1    2    3    4    5    6    7    8
Row 0:  [grass-top-left corners and flat grass surfaces]  [edge]
Row 1:  [--------- stone cliff face ---------]  [grass edge] [grass edge] [stone]
Row 2:  [-------------- stone cliff face (full row, all collision) ----------]
Row 3:  [--- stone cliff face ---]  [grass]  [grass]  [stone]  [stone]
Row 4:  [--- stone cliff face ---]  [grass]  [grass]  [stone]  [stone]
Row 5:  [--- grass ground fill ---]  [stone]  [stone]  [stone]  [stone]
Row 6:  [--- stone wall ---]  [grass]  [grass]
Row 7:  [--- stone archway top (all collision) ---]
Row 8:  [--- stone archway mid (all collision) ---]
Row 9:  [--- stone archway lower (all collision) ---]
Row 10: [--- stone archway base (all collision) ---]
Row 11: [stone] [--] [stone] [stone] [grass] [stone]
Row 12: [stone] [--] [stone] [stone] [stone] [stone]
```

### Collision Map (C = collision, . = walkable)

```
	 0  1  2  3  4  5  6  7  8
 0:  .  .  .  .  C  .  -  -  .
 1:  C  C  C  C  C  C  .  .  C
 2:  C  C  C  C  C  C  C  C  C
 3:  C  C  C  C  C  .  .  C  C
 4:  C  C  C  C  C  .  .  C  C
 5:  .  .  .  .  .  C  C  C  C
 6:  C  C  C  C  C  .  .  -  -
 7:  C  C  C  C  C  C  C  -  -
 8:  C  C  C  C  C  C  C  -  -
 9:  C  C  C  C  C  C  C  -  -
10:  C  C  C  C  C  C  -  -  -
11:  C  -  C  C  .  C  -  -  -
12:  C  -  C  C  C  C  -  -  -
```

`-` = tile not defined in this source

### Walkable Tiles (No Collision)

These are flat grass ground surfaces:

| Atlas Coords | Description |
|-------------|-------------|
| (0,0) (1,0) (2,0) (3,0) | Grass surface top edges |
| (5,0) (8,0) | Grass corner/edge variants |
| (6,1) (7,1) | Grass-to-stone transition edges |
| (5,3) (6,3) | Grass inner corners (cliff recess) |
| (5,4) (6,4) | Grass inner corners (cliff recess) |
| (0,5) (1,5) (2,5) (3,5) (4,5) | Flat grass ground fill |
| (5,6) (6,6) | Grass ground variant |
| (4,11) | Archway interior floor |

### Collision Tiles (Solid)

Stone cliffs, walls, and structural tiles. Key regions:

- **Rows 1-4, cols 0-4**: Main cliff face (vertical stone wall)
- **Row 2**: Full stone wall row
- **Rows 7-12**: Cave/archway structure
- **Row 5, cols 5-8**: Stone ledge/shelf

### WorldGrid Terrain Mapping

| Collision | TerrainType | Passable |
|-----------|------------|----------|
| No | `GRASS` | Yes |
| Yes | `ROCK` | No |

---

## Source 1: town1.png

Building and structure atlas. Used for settlement buildings and decorative elements.

### Visual Layout

```
Col:  0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
Row 0-2:   [Rooftop tiles]              [Building facades, peaked roofs, walls]
Row 3:     [Walls, lower roof]          [Stone walls, wooden walls, window frames]
Row 4-5:   [Doors, arched entries]      [Wall details, foundations]
Row 6-8:   [Stone foundations, bricks]  [Decorative walls, structural elements]
Row 9:     [Signs, banners]             [Props: bush, fence, barrel, misc items]
Row 10-11: [Props, ground decor]        [Furniture, small items, wall hangings]
Row 12-13: [Floor planks, paths]        [Wooden walkway sections]
Row 14-15: [Floor variants]             [Dock/pier boards, wooden surfaces]
Row 16-17: [Water edge transitions]     [Dock supports, water tiles]
Row 18-19:                              [Deep water, pier end pieces]
```

### Collision Map

```
	  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
 0:   .  .  .  .  .  C  C  C  C  C  C  -  -  C  C  -
 1:   .  .  .  .  .  -  C  C  C  C  -  -  C  C  C  C
 2:   .  .  .  .  -  C  C  C  C  C  C  -  C  .  .  C
 3:   .  .  .  C  C  C  C  C  C  C  C  C  C  .  .  C
 4:   C  C  C  C  C  C  C  C  C  C  C  C  C  C  C  C
 5:   C  C  C  C  C  C  C  C  C  C  C  C  C  C  C  -
 6:   C  C  C  C  C  C  C  C  C  C  C  C  C  C  C  -
 7:   C  C  C  C  C  C  C  C  C  C  C  C  C  C  C  -
 8:   C  C  C  C  C  C  C  -  -  C  C  C  C  C  C  -
 9:   C  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
10:   C  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
11:   C  .  .  .  .  .  .  .  .  .  .  .  .  .  -  .
12:   -  .  .  .  .  .  .  .  .  .  .  .  .  .  -  -
13:   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
14:   .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  -
15:   .  .  .  .  .  -  .  .  .  .  .  .  .  .  .  -
16:   -  -  -  -  .  .  .  .  .  .  .  .  .  .  -  -
17:   -  -  -  -  -  .  .  .  .  .  .  .  .  .  .  .
18:   -  -  -  -  -  -  -  -  .  .  .  .  .  .  .  .
19:   -  -  -  -  -  -  -  .  .  .  .  .  .  .  .  .
```

### Tile Regions by Function

**Rooftops (rows 0-3, cols 0-4)** -- No collision, decorative overhangs
- (0,0)-(4,0), (0,1)-(4,1), (0,2)-(3,2), (0,3)-(2,3)
- Visually: peaked gray/brown roof tiles

**Building Walls (rows 0-8, cols 5-15)** -- Collision, solid structures
- Stone brick walls, wooden plank walls, window frames
- Includes doorway tiles (arched dark openings)

**Props & Decor (rows 9-12)** -- Mostly no collision, ground-level
- Signs, banners (pink/red), bushes, iron fence posts
- Barrels, crates, small decorative items
- Exception: col 0 has collision (wall edge continuations)

**Floor & Paths (rows 13-15)** -- No collision, walkable surfaces
- Wooden plank flooring, dirt paths
- Dock/pier board surfaces

**Water & Dock (rows 16-19)** -- No collision in .tres, but logically water
- Water surface tiles, dock pier supports
- Bottom-right corner of atlas
- Note: these tiles lack physics collision in the tileset but represent water visually

### WorldGrid Terrain Mapping

All Source 1 tiles map to `GRASS` for terrain type (buildings are tracked separately via `WorldGrid.set_building()`). Collision still determines passability.

---

## trees1.png (Not In Tileset)

560x480 pixel sprite sheet containing deciduous trees. Not currently referenced as a tileset source.

### Contents

- **Top row**: Green-leafed trees -- tall birch (3 variants), medium tree, small bush, hedge
- **Bottom row**: Autumn/gold-leafed trees -- same silhouettes as top row in orange/yellow

### Future Integration

When added as Source 2, tree tiles would map to `Enums.TerrainType.FOREST` in WorldGrid. These are larger multi-tile sprites (not 16x16 grid tiles), so they may be better placed as individual scene nodes or on a separate decorative TileMapLayer rather than the terrain grid.

---

## WorldGrid Integration

`WorldGrid.load_from_tilemap()` reads each cell from the TileMapLayer and classifies it:

1. **Checks physics collision** via `TileSetAtlasSource.get_tile_data().get_collision_polygons_count(0)`
2. **Maps terrain type** based on source_id + collision:

| Source | Collision | TerrainType | Passable |
|--------|-----------|-------------|----------|
| 0 | No | `GRASS` | Yes |
| 0 | Yes | `ROCK` | No |
| 1 | No | `GRASS` | Yes |
| 1 | Yes | `GRASS` | No (collision override) |

Code: `world_grid.gd` -- `_terrain_from_tile()` and `_tile_has_collision()`

---

## Notes

- All collision polygons are uniform 16x16 squares: `(-8,-8)` to `(8,8)`
- No custom data layers are defined on the tileset
- No terrain painting sets are configured (autotiling is manual)
- The tileset uses a single physics layer (layer 0, collision_layer = 1)
