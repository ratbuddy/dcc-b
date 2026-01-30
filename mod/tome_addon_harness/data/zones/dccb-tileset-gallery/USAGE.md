# dccb-tileset-gallery Zone - Usage Guide

## Overview
The dccb-tileset-gallery zone is a **debug/reference tool** that displays a visual palette of all DCCB terrain grids. It's designed to validate tileset image paths and serve as a catalog for theme development.

## Purpose

### Why This Zone Exists
After PR #45 fixed ASCII fallback by removing invalid image paths, we needed:
1. A way to **validate which tileset paths work** without trial-and-error
2. A **visual catalog** of all available DCCB grids
3. A **regression testing tool** to detect tileset issues
4. A **reference** for future theme development

### What Problem It Solves
- **Eliminates guessing:** See immediately which tilesets render correctly
- **Side-by-side comparison:** View all themed variants at once
- **Documentation:** Canonical reference for available grids
- **Quality assurance:** Detect ASCII fallback issues before they reach players

## How to Access

### Using Debug Console
```lua
game:changeLevel(1, "dccb+dccb-tileset-gallery")
```

### Using ToME Debug Menu
1. Open debug menu (usually Ctrl+D or via game settings)
2. Select "Change Zone"
3. Enter: `dccb+dccb-tileset-gallery`
4. Level: 1

## What You'll See

### Grid Palette Layout
The zone displays **13 terrain grids** in an organized layout:

**Starting position:** (5, 5)  
**Spacing:** 4 cells between grids  
**Arrangement:** 5 grids per row

```
Row 1: FLOOR      WALL       GRASS      ROAD       TREE
Row 2: GRASS_W    ROAD_W     TREE_W     GRASS_R    ROAD_R
Row 3: TREE_R     ENTRANCE   (empty)    (empty)    (empty)

Legend:
_W = Winter theme
_R = Ruins theme
```

### Grid Categories

**Base Game (2 grids):**
- `FLOOR` - Standard floor tile (from ToME basic.lua)
- `WALL` - Standard wall tile (from ToME basic.lua)

**Green/Plains Theme (3 grids):**
- `GRASS` - Green grass with explicit tileset (terrain/grass.png)
- `ROAD` - Dirt road with explicit tileset (terrain/road_dirt_6_1.png)
- `TREE` - Tree with explicit tileset (terrain/tree.png)

**Winter/Snow Theme (3 grids):**
- `GRASS_WINTER` - Snowy ground (inherits from FLOOR, white color)
- `ROAD_WINTER` - Icy path (inherits from FLOOR, light blue color)
- `TREE_WINTER` - Snowy tree (inherits from WALL, white color)

**Ruins/Ancient Theme (3 grids):**
- `GRASS_RUINS` - Overgrown ground (inherits from FLOOR, dark green color)
- `ROAD_RUINS` - Ancient path (inherits from FLOOR, grey color)
- `TREE_RUINS` - Ruined pillar (inherits from WALL, grey color)

**Special (1 grid):**
- `DCCB_ENTRANCE` - Dungeon entrance marker (yellow, grass tileset)

## Expected Log Output

When the zone generates, you'll see detailed logging:

```
[DCCB-Gallery] Entered zone 'dccb-tileset-gallery' level 1
[DCCB-Gallery] ========================================
[DCCB-Gallery] Generating Tileset Palette
[DCCB-Gallery] ========================================
[DCCB-Gallery] Placing 13 grids in palette
[DCCB-Gallery] Layout: 5 grids per row, spacing=4
[DCCB-Gallery] ✓ [ 5, 5] FLOOR           | Base Game | Standard floor tile
[DCCB-Gallery] ✓ [ 9, 5] WALL            | Base Game | Standard wall tile
[DCCB-Gallery] ✓ [13, 5] GRASS           | Green Theme | Grass (explicit tileset)
[DCCB-Gallery] ✓ [17, 5] ROAD            | Green Theme | Dirt road (explicit tileset)
[DCCB-Gallery] ✓ [21, 5] TREE            | Green Theme | Tree (explicit tileset)
[DCCB-Gallery] ✓ [ 5, 9] GRASS_WINTER    | Winter Theme | Snowy ground (inherited)
[DCCB-Gallery] ✓ [ 9, 9] ROAD_WINTER     | Winter Theme | Icy path (inherited)
[DCCB-Gallery] ✓ [13, 9] TREE_WINTER     | Winter Theme | Snowy tree (inherited)
[DCCB-Gallery] ✓ [ 5,13] GRASS_RUINS     | Ruins Theme | Overgrown ground (inherited)
[DCCB-Gallery] ✓ [ 9,13] ROAD_RUINS      | Ruins Theme | Ancient path (inherited)
[DCCB-Gallery] ✓ [13,13] TREE_RUINS      | Ruins Theme | Ruined pillar (inherited)
[DCCB-Gallery] ✓ [17,13] DCCB_ENTRANCE   | Special | Dungeon entrance marker
[DCCB-Gallery] ========================================
[DCCB-Gallery] Palette generation complete
[DCCB-Gallery] Total grids attempted: 13
[DCCB-Gallery] ========================================
```

### What to Look For

**✓ (checkmark)** = Grid placed successfully  
**✗ (cross)** = Grid not found (error condition)

If you see `✗` for any grid, it means that grid definition is missing or broken.

## Validating Tilesets

### Visual Inspection
Walk around the zone and visually inspect each grid:

**Expected:** PNG tile graphics  
**Problem:** ASCII characters (, . = # T >) indicate fallback

### Common Issues

**ASCII Fallback:**
- **Cause:** Invalid `image` path in grid definition
- **Solution:** Remove `image` property or fix the path
- **Example:** `image = "terrain/nonexistent.png"` → Remove or use valid path

**Grid Not Found:**
- **Cause:** Grid not defined in grids.lua
- **Solution:** Add grid definition or check for typos
- **Example:** `GRASS_WINTER` typo as `GRASS_WITER`

**Wrong Colors:**
- **Cause:** `color` property incorrect
- **Solution:** Update color in grid definition
- **Example:** Winter theme should use `colors.WHITE`

## How to Add New Grids to Catalog

### Step 1: Define the Grid
Add the grid definition to `grids.lua`:

```lua
newEntity{
  base = "FLOOR",
  define_as = "MY_NEW_GRID",
  type = "floor", subtype = "custom",
  name = "my custom terrain",
  display = '*', color=colors.PURPLE,
  image = "terrain/custom.png",  -- Optional
  always_remember = true,
}
```

### Step 2: Add to Catalog
Edit `zone.lua` and add to the `grid_catalog` table:

```lua
local grid_catalog = {
  -- ... existing entries ...
  
  {id = "MY_NEW_GRID", category = "Custom Theme", description = "My custom terrain"},
}
```

### Step 3: Test
1. Load the zone: `game:changeLevel(1, "dccb+dccb-tileset-gallery")`
2. Check the log for your grid
3. Visually inspect: PNG tile or ASCII fallback?

### Step 4: Fix Issues
If you see ASCII instead of tile:
1. Check if `image` path exists in ToME
2. Try removing `image` to inherit from base
3. Verify `base` entity has valid tileset

## Technical Details

### Zone Configuration
- **Size:** 50x50 (large enough for palette)
- **Generator:** Empty (blank canvas)
- **Levels:** Single level only
- **Visibility:** All remembered, all lited (full visibility)
- **Persistence:** Zone level

### Grid Placement Algorithm
```lua
grids_per_row = 5
grid_spacing = 4
start_x = 5
start_y = 5

For grid #N (1-indexed):
  row = floor((N-1) / grids_per_row)
  col = (N-1) % grids_per_row
  x = start_x + (col * grid_spacing)
  y = start_y + (row * grid_spacing)
```

### Why This Layout
- **Spacing (4 cells):** Enough to see individual grids clearly
- **5 per row:** Fits comfortably in standard viewport
- **Starting (5,5):** Leaves border space, centers content

## Integration with Development Workflow

### When to Use This Zone

**During Theme Development:**
- Testing new tileset image paths
- Comparing themed variants
- Validating color schemes

**After Code Changes:**
- Regression testing tileset changes
- Verifying grid definitions load correctly
- Checking for ASCII fallback issues

**For Documentation:**
- Taking screenshots of available grids
- Creating theme guides
- Training new developers

### Not Used For
- Normal gameplay (debug zone only)
- Performance testing (small, static map)
- NPC/combat testing (no spawns)

## Troubleshooting

### Zone Won't Load
**Problem:** Error when changing to zone  
**Check:**
1. Are all resource files present? (grids.lua, npcs.lua, etc.)
2. Is grids.lua syntax correct? (Lua errors)
3. Are zone directories created correctly?

### All Grids Show ASCII
**Problem:** Everything renders as ASCII characters  
**Check:**
1. Is base game loaded? (`load("/data/general/grids/basic.lua")`)
2. Are base entities (FLOOR, WALL) available?
3. ToME tileset installation correct?

### Some Grids Missing
**Problem:** `✗` in log for specific grids  
**Check:**
1. Is grid defined in grids.lua?
2. Is `define_as` name correct? (case-sensitive)
3. Is newEntity syntax correct?

### Colors Look Wrong
**Problem:** Grids have wrong colors  
**Fix:** Update `color` property in grid definition

## Future Enhancements

### Possible Additions
- Text labels next to each grid (if feasible in ToME)
- More ToME base grids (water, lava, etc.)
- Additional DCCB themes (desert, forest, etc.)
- Interactive features (click grid to see properties)

### Not Planned
- Gameplay features (remains debug tool)
- Complex layouts (keep simple for clarity)
- Dynamic content (static catalog is the goal)

---

**Status:** Production-ready debug tool  
**Maintenance:** Update when adding new DCCB grids  
**Dependencies:** None (self-contained zone)
