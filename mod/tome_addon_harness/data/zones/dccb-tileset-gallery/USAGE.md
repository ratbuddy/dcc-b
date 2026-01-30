# dccb-tileset-gallery Zone - Usage Guide

## Overview
The dccb-tileset-gallery zone is a **debug/reference tool** that displays a visual palette of all DCCB terrain grids **plus official ToME terrain families**. It's designed to validate tileset image paths and serve as a comprehensive catalog for theme development.

## Purpose

### Why This Zone Exists
After PR #45 fixed ASCII fallback by removing invalid image paths, we needed:
1. A way to **validate which tileset paths work** without trial-and-error
2. A **visual catalog** of all available DCCB grids
3. A **reference for official ToME terrains** (water, lava, forest, mountain)
4. A **regression testing tool** to detect tileset issues
5. A **comprehensive reference** for future theme development

### What Problem It Solves
- **Eliminates guessing:** See immediately which tilesets render correctly
- **Side-by-side comparison:** View all themed variants at once
- **Official terrain showcase:** Discover what terrains ToME provides
- **Safe loading:** Handles missing terrain packs gracefully (no crashes)
- **Documentation:** Canonical reference for all available terrains
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

### Terrain Palette Layout
The zone displays **up to 30 terrain samples** in an organized layout:

**Background:** Filled with grass (or floor if grass unavailable)  
**Starting position:** (5, 5)  
**Spacing:** 4 cells between samples  
**Arrangement:** 6 terrains per row

### Generation Process
1. **Background Fill:** Entire map filled with GRASS or FLOOR (no black areas)
2. **Terrain Loading:** Safely loads 5 additional ToME terrain packs
3. **Sample Placement:** Places terrain samples from catalog at spaced coordinates

### Terrain Categories

#### DCCB Custom Terrains (13 terrains)

**Base (2 terrains):**
- `FLOOR` - Standard floor tile (from ToME basic.lua)
- `WALL` - Standard wall tile (from ToME basic.lua)

**Green/Plains Theme (3 terrains):**
- `GRASS` - Green grass with explicit tileset (terrain/grass.png)
- `ROAD` - Dirt road with explicit tileset (terrain/road_dirt_6_1.png)
- `TREE` - Tree with explicit tileset (terrain/tree.png)

**Winter/Snow Theme (3 terrains):**
- `GRASS_WINTER` - Snowy ground (inherits from FLOOR, white color)
- `ROAD_WINTER` - Icy path (inherits from FLOOR, light blue color)
- `TREE_WINTER` - Snowy tree (inherits from WALL, white color)

**Ruins/Ancient Theme (3 terrains):**
- `GRASS_RUINS` - Overgrown ground (inherits from FLOOR, dark green color)
- `ROAD_RUINS` - Ancient path (inherits from FLOOR, grey color)
- `TREE_RUINS` - Ruined pillar (inherits from WALL, grey color)

**Special (1 terrain):**
- `DCCB_ENTRANCE` - Dungeon entrance marker (yellow, grass tileset)

#### Official ToME Terrains (17 terrains)
*Note: Availability depends on which terrain packs successfully loaded*

**Forest Terrains (4 terrains):**
- `FOREST_TREE` - Forest tree
- `TREE_OLDER` - Old tree
- `TREE_BURNT` - Burnt tree
- `DENSE_FOREST` - Dense forest

**Water Terrains (3 terrains):**
- `WATER` - Shallow water
- `DEEP_WATER` - Deep water
- `WATER_BUBBLE` - Bubbling water

**Lava Terrains (3 terrains):**
- `LAVA` - Lava
- `LAVA_DEEP` - Deep lava
- `VOLCANIC_FLOOR` - Volcanic floor

**Mountain Terrains (3 terrains):**
- `MOUNTAIN` - Mountain
- `MOUNTAIN_WALL` - Mountain wall
- `ROCK` - Rocky ground

**Base Variants (4 terrains):**
- `HARDFLOOR` - Hard floor
- `HARDWALL` - Hard wall

## Expected Log Output

When the zone generates, you'll see detailed logging in three steps:

```
[DCCB-Gallery] Entered zone 'dccb-tileset-gallery' level 1

[DCCB-Gallery] Loaded terrain pack: /data/general/grids/water.lua
[DCCB-Gallery] Loaded terrain pack: /data/general/grids/forest.lua
[DCCB-Gallery] Loaded terrain pack: /data/general/grids/lava.lua
[DCCB-Gallery] Loaded terrain pack: /data/general/grids/mountain.lua
[DCCB-Gallery] Failed to load terrain pack: /data/general/grids/jungle_hut.lua : [error details]

[DCCB-Gallery] ========================================
[DCCB-Gallery] Generating Tileset Palette
[DCCB-Gallery] ========================================

[DCCB-Gallery] Step 1: Filling background...
[DCCB-Gallery] Background filled with: grass

[DCCB-Gallery] Step 2: Preparing terrain catalog...

[DCCB-Gallery] Step 3: Placing 30 terrain samples...
[DCCB-Gallery] Layout: 6 grids per row, spacing=4

[DCCB-Gallery] ✓ [ 5, 5] FLOOR                | DCCB/Base      | Standard floor tile
[DCCB-Gallery] ✓ [ 9, 5] WALL                 | DCCB/Base      | Standard wall tile
[DCCB-Gallery] ✓ [13, 5] GRASS                | DCCB/Green     | Grass (explicit tileset)
... (all DCCB terrains)
[DCCB-Gallery] ✓ [13,13] WATER                | ToME/Water     | Shallow water
[DCCB-Gallery] ⊘ [17,13] LAVA_DEEP            | ToME/Lava      | SKIPPED (not found)
[DCCB-Gallery] ✓ [21,13] MOUNTAIN             | ToME/Mountain  | Mountain
... (remaining terrains)

[DCCB-Gallery] ========================================
[DCCB-Gallery] Palette generation complete
[DCCB-Gallery] Total attempted: 30
[DCCB-Gallery] Placed: 24 | Skipped: 6
[DCCB-Gallery] ========================================
```

### Log Symbols
- **✓** - Terrain successfully placed
- **⊘** - Terrain skipped (ID not found in loaded packs)

The skipped terrains are **expected** - not all ToME installations have all terrain packs. The gallery handles this gracefully.

### What to Look For

**✓ (checkmark)** = Terrain placed successfully  
**⊘ (crossed circle)** = Terrain skipped (not found - normal for missing packs)

If a terrain is skipped, it simply means that terrain pack isn't loaded. This is **expected behavior** and not an error.

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

## How to Add New Terrains to Catalog

### Step 1: Add Terrain Pack (if needed)
If adding official ToME terrains, add the pack load to `grids.lua`:

```lua
safe_load("/data/general/grids/your_pack.lua")
```

### Step 2: Define Custom Terrain (optional)
For DCCB custom terrains, add to `grids.lua`:

```lua
newEntity{
  base = "FLOOR",
  define_as = "MY_NEW_TERRAIN",
  type = "floor", subtype = "custom",
  name = "my custom terrain",
  display = '*', color=colors.PURPLE,
  image = "terrain/custom.png",  -- Optional
  always_remember = true,
}
```

### Step 3: Add to Catalog
Edit `zone.lua` and add to the `grid_catalog` table:

```lua
local grid_catalog = {
  -- ... existing entries ...
  
  {id = "MY_NEW_TERRAIN", category = "Custom/Theme", description = "My custom terrain"},
}
```

### Step 4: Test
1. Load the zone: `game:changeLevel(1, "dccb+dccb-tileset-gallery")`
2. Check the log:
   - Pack loaded successfully?
   - Terrain placed (✓) or skipped (⊘)?
3. Visually inspect: PNG tile or ASCII fallback?

### Step 5: Fix Issues
If you see ASCII instead of tile:
1. Check if `image` path exists in ToME
2. Try removing `image` to inherit from base
3. Verify `base` entity has valid tileset

If terrain is skipped:
1. Check terrain ID spelling
2. Verify terrain pack loaded successfully
3. Confirm terrain exists in that pack

## Technical Details

### Zone Configuration
- **Size:** 50x50 (large enough for expanded palette)
- **Generator:** Empty (blank canvas)
- **Levels:** Single level only
- **Visibility:** All remembered, all lited (full visibility)
- **Persistence:** Zone level
- **Background:** Filled with GRASS or FLOOR (no black areas)

### Terrain Placement Algorithm
```lua
grids_per_row = 6  -- Increased from 5
grid_spacing = 4
start_x = 5
start_y = 5

For terrain #N (1-indexed):
  row = floor((N-1) / grids_per_row)
  col = (N-1) % grids_per_row
  x = start_x + (col * grid_spacing)
  y = start_y + (row * grid_spacing)
```

### Why This Layout
- **Background fill:** Prevents black map, provides context
- **Spacing (4 cells):** Enough to see individual terrains clearly
- **6 per row:** Accommodates expanded catalog (30 terrains)
- **Starting (5,5):** Leaves border space, centers content

### Safe Loading
Terrain packs are loaded with `pcall` to prevent crashes:
- If pack loads: Terrains available for placement
- If pack fails: Logged but doesn't crash zone
- Missing terrains: Skipped gracefully during placement

## Integration with Development Workflow

### When to Use This Zone

**During Theme Development:**
- Testing new tileset image paths
- Comparing themed variants
- Validating color schemes
- Discovering available ToME terrains

**After Code Changes:**
- Regression testing tileset changes
- Verifying grid definitions load correctly
- Checking for ASCII fallback issues
- Validating new terrain pack loads

**For Documentation:**
- Taking screenshots of available terrains
- Creating theme guides
- Training new developers
- Reference for terrain selection

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

### All Terrains Show ASCII
**Problem:** Everything renders as ASCII characters  
**Check:**
1. Is base game loaded? (`load("/data/general/grids/basic.lua")`)
2. Are base entities (FLOOR, WALL) available?
3. ToME tileset installation correct?

### Some Terrains Skipped
**Problem:** `⊘` in log for specific terrains (especially ToME terrains)  
**This is normal!** Not all terrain packs exist in all ToME installations. The gallery handles this gracefully. Only investigate if:
1. All ToME terrains are skipped (check pack loading)
2. DCCB terrains are skipped (check grids.lua definitions)

### Terrain Pack Load Failures
**Problem:** "Failed to load terrain pack" messages  
**Check:**
1. Is this a standard ToME installation? (some packs may not exist)
2. Are pack paths correct? (`/data/general/grids/water.lua` etc.)
3. This is **expected** for non-existent packs - zone continues safely

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

## Summary of Changes

### Latest Update: Official ToME Terrain Families
- **Added 17 official ToME terrain samples** (water, forest, lava, mountain)
- **Total catalog: 30 terrains** (13 DCCB + 17 ToME)
- **Safe terrain pack loading** with pcall (no crashes on missing packs)
- **Background fill** prevents black map
- **Fixed entity kind** to "terrain" (canonical approach)
- **6 per row layout** (expanded from 5)

### Benefits
- **Comprehensive reference:** See both custom and official terrains
- **Safe operation:** Handles missing packs/terrains gracefully
- **Better visualization:** Background fill provides context
- **Correct API usage:** Uses "terrain" entity kind
- **Expanded catalog:** Water, lava, forest, mountain terrains available

---

**Status:** Production-ready comprehensive terrain catalog  
**Catalog Size:** 30 terrains (13 DCCB custom + 17 official ToME)  
**Maintenance:** Update when adding new terrains or themes  
**Dependencies:** None (self-contained, handles missing packs safely)
