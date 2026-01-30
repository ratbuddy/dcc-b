# dccb-tileset-gallery Zone - Usage Guide

## Overview
The dccb-tileset-gallery zone is a **debug/reference tool** that displays a **dense visual palette** of 90+ terrain samples. It validates tileset image paths and serves as a comprehensive catalog for theme development.

## Purpose

### Why This Zone Exists
After PR #45 fixed ASCII fallback, we needed a comprehensive terrain catalog. This zone now provides:
1. **Dense palette:** 40-60+ visible terrain samples tightly packed
2. **Comprehensive catalog:** 90+ terrain candidates from all ToME families
3. **Safe operation:** Handles missing IDs and dangerous terrains gracefully
4. **Visual validation:** See which tilesets render correctly vs ASCII
5. **Theme reference:** All DCCB themes plus official ToME terrain families

### What Problem It Solves
- **Eliminates guessing:** See immediately which tilesets render correctly
- **Comprehensive coverage:** Probes 90+ terrain IDs across all categories
- **Safe exploration:** No crashes, no unwanted zone transitions
- **Dense layout:** Many samples visible at once (not widely spaced)
- **Clear categorization:** DCCB custom + official ToME terrains organized
- **Quality assurance:** Detect tileset issues before they reach players

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

### Dense Palette Layout
The zone displays a **dense grid** of terrain samples:

**Background:** Filled with grass (or floor if grass unavailable)  
**Starting position:** (2, 2)  
**Spacing:** 2 cells between samples (tight packing)  
**Arrangement:** 16-20 terrains per row (auto-calculated)  
**Spawn pad:** 8×8 walkable area at bottom-right corner

### Generation Process
1. **Background Fill:** Entire map filled with GRASS or FLOOR (no black areas)
2. **Spawn Pad:** 8×8 safe walkable area created at bottom-right
3. **Dense Layout:** Auto-calculates columns from map width (~16-20)
4. **Safe Placement:** Each terrain checked for safety before placing
5. **Terrain Loading:** Safely loads terrain packs and probes 90+ candidates

### Terrain Categories (90+ Candidates)

#### DCCB Custom Terrains (12 terrains)
- **Base:** FLOOR, WALL
- **Green Theme:** GRASS, ROAD, TREE
- **Winter Theme:** GRASS_WINTER, ROAD_WINTER, TREE_WINTER
- **Ruins Theme:** GRASS_RUINS, ROAD_RUINS, TREE_RUINS
- **Special:** DCCB_ENTRANCE

#### Official ToME Terrains (80+ candidates)
*Note: Many may be skipped if terrain packs not loaded - this is normal*

**Base/Generic (10):**
- HARDFLOOR, HARDWALL, DIRT, SAND, ROCK, STONE_FLOOR, STONE_WALL
- GRANITE_FLOOR, GRANITE_WALL, MARBLE_FLOOR, MARBLE_WALL

**Forest (10):**
- FOREST_TREE, TREE_OLDER, TREE_BURNT, DENSE_FOREST, TREE_WALL
- BUSH, THICKET, FOREST_FLOOR, FOREST_GRASS, TALL_GRASS

**Water (8):**
- WATER, DEEP_WATER, SHALLOW_WATER, WATER_BUBBLE, WATER_FLOOR
- UNDERWATER_FLOOR, UNDERWATER_WALL, POOL

**Lava (6):**
- LAVA, DEEP_LAVA, LAVA_DEEP, VOLCANIC_FLOOR, LAVA_FLOOR, MOLTEN_ROCK

**Mountain/Cave (8):**
- MOUNTAIN, MOUNTAIN_WALL, MOUNTAIN_FLOOR, CAVE_WALL, CAVE_FLOOR
- ROCKY_GROUND, ROUGH_ROCK, CAVE_MOSS

**Snow/Ice (7):**
- SNOW, SNOW_FLOOR, SNOW_GROUND, ICE, ICE_FLOOR, ICE_WALL, FROZEN_GROUND

**Dungeon (6):**
- DOOR, DOOR_OPEN, DOOR_CLOSED, CHASM, PIT, VOID

**Misc (13):**
- SWAMP, MUD, BOG, SAND_FLOOR, DESERT_SAND, COBBLESTONE, FLAGSTONE
- CRYSTAL, CRYSTAL_WALL, FUNGUS, SLIME

**Base Variants (4 terrains):**
- `HARDFLOOR` - Hard floor
- `HARDWALL` - Hard wall

## Expected Log Output

When the zone generates, you'll see detailed logging with safety checks:

```
[DCCB-Gallery] Entered zone 'dccb-tileset-gallery' level 1

[DCCB-Gallery] Loaded terrain pack: /data/general/grids/water.lua
[DCCB-Gallery] Loaded terrain pack: /data/general/grids/forest.lua
[DCCB-Gallery] Loaded terrain pack: /data/general/grids/lava.lua
[DCCB-Gallery] Loaded terrain pack: /data/general/grids/mountain.lua
[DCCB-Gallery] Failed to load terrain pack: /data/general/grids/jungle_hut.lua : [error details]

[DCCB-Gallery] ========================================
[DCCB-Gallery] Generating Dense Tileset Palette
[DCCB-Gallery] ========================================

[DCCB-Gallery] Step 1: Filling background...
[DCCB-Gallery] Background filled with: grass

[DCCB-Gallery] Step 2: Creating spawn pad...
[DCCB-Gallery] Spawn pad: 8x8 at (40,40)

[DCCB-Gallery] Step 3: Dense layout: 16 columns, 2x2 cell spacing

[DCCB-Gallery] Step 4: Placing terrain samples from manifest (90 candidates)...

[DCCB-Gallery] ✓ [ 2, 2] FLOOR                | DCCB/Base
[DCCB-Gallery] ✓ [ 4, 2] WALL                 | DCCB/Base
[DCCB-Gallery] ✓ [ 6, 2] GRASS                | DCCB/Green
... (first 10 placed terrains logged)
[DCCB-Gallery] ⊘ [14, 4] SHALLOW_WATER        | MISSING
[DCCB-Gallery] ⊘ [16, 4] UNDERWATER_FLOOR     | MISSING
... (first 5 missing terrains logged)
[DCCB-Gallery] ⚠ [20, 6] DOOR_CLOSED          | DANGEROUS (has change_level/on_stand)
[DCCB-Gallery] ⚠ [22, 6] CHASM                | DANGEROUS (has change_level/on_stand)
... (all dangerous terrains logged)

[DCCB-Gallery] ========================================
[DCCB-Gallery] Palette generation complete
[DCCB-Gallery] ========================================
[DCCB-Gallery] Total candidates: 90
[DCCB-Gallery] ✓ Placed: 45 terrains
[DCCB-Gallery] ⊘ Skipped (missing): 40
[DCCB-Gallery] ⚠ Skipped (dangerous): 5
[DCCB-Gallery] Layout: 16 columns × 3 rows visible
[DCCB-Gallery] ========================================
```

### Log Symbols
- **✓** - Terrain successfully placed (safe to use)
- **⊘** - Terrain skipped (ID not found - normal for missing packs)
- **⚠** - Terrain dangerous (has change_level/on_stand hooks - filtered out)

### What the Counts Mean

**Placed (40-60):** Terrains that exist and are safe to use  
**Skipped Missing (30-50):** Terrains not found - depends on ToME installation  
**Skipped Dangerous (5-10):** Terrains with transition hooks - intentionally filtered

Missing terrains are **expected and normal** - not all ToME installations have all terrain packs. The gallery probes comprehensively to find what's available.

### Safety Features

**Dangerous Terrain Detection:**
The gallery automatically filters terrains with:
- `change_level` - Would cause zone transitions
- `change_zone` - Would change zones
- `on_stand` - Could trigger when walking
- `on_move` - Could trigger on movement

These are logged with ⚠ and **never placed** to prevent unwanted transitions.

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

### Step 1: Add to Manifest
Edit `/mod/tome_addon_harness/data/dccb/tileset/gallery_manifest.lua`:

```lua
M.TERRAIN_CANDIDATES = {
  -- ... existing terrains ...
  
  -- Add your new terrain:
  {id = "MY_TERRAIN", category = "Custom/MyTheme", description = "My custom terrain"},
}
```

### Step 2: Define Custom Terrain (optional)
If it's a DCCB custom terrain, add to `dccb-tileset-gallery/grids.lua`:

```lua
newEntity{
  base = "FLOOR",
  define_as = "MY_TERRAIN",
  type = "floor", subtype = "custom",
  name = "my custom terrain",
  display = '*', color=colors.PURPLE,
  image = "terrain/custom.png",  -- Optional
  always_remember = true,
}
```

### Step 3: Test
1. Load the zone: `game:changeLevel(1, "dccb+dccb-tileset-gallery")`
2. Check the log:
   - Terrain placed (✓), missing (⊘), or dangerous (⚠)?
3. Visually inspect: PNG tile or ASCII fallback?

### Step 4: Fix Issues
If you see ASCII instead of tile:
1. Check if `image` path exists in ToME
2. Try removing `image` to inherit from base
3. Verify `base` entity has valid tileset

If terrain is skipped (missing):
1. Check terrain ID spelling in manifest
2. Verify terrain pack loaded successfully
3. Confirm terrain exists in that pack

If terrain is dangerous (⚠):
1. This is intentional - terrain has transition hooks
2. Gallery filters these to prevent unwanted zone changes
3. Don't use these terrains in gameplay zones

## Technical Details

### Zone Configuration
- **Size:** 50x50 (large enough for dense palette)
- **Generator:** Empty (blank canvas)
- **Levels:** Single level only
- **Visibility:** All remembered, all lited (full visibility)
- **Persistence:** Zone level
- **Background:** Filled with GRASS or FLOOR (no black areas)
- **Spawn Pad:** 8×8 walkable area at bottom-right

### Dense Layout Algorithm
```lua
CELL_W = 2              -- Tight horizontal spacing
CELL_H = 2              -- Tight vertical spacing
START_X = 2             -- Palette origin
START_Y = 2
cols = ~16-20           -- Auto-calculated from map width

For terrain #N (1-indexed):
  row = floor((N-1) / cols)
  col = (N-1) % cols
  x = START_X + (col * CELL_W)
  y = START_Y + (row * CELL_H)
```

### Why Dense Layout
- **Tight spacing (2 cells):** Maximizes visible terrains
- **Auto columns (~16-20):** Adapts to map width
- **Sequential placement:** Easy to scan visually
- **Spawn pad:** Safe walkable area preserved

### Safety Checks
**Three-tier filtering:**
1. **Entity creation:** `zone:makeEntityByName()` - nil if not found
2. **Dangerous check:** Looks for change_level/on_stand/etc hooks
3. **Safe placement:** Only places terrains that pass both checks

**Prevents:**
- Crashes from missing terrains
- Unwanted zone transitions
- Movement-triggered events

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
1. Is manifest file present? (`data/dccb/tileset/gallery_manifest.lua`)
2. Are all resource files present? (grids.lua, npcs.lua, etc.)
3. Is zone.lua syntax correct? (Lua errors)
4. Are zone directories created correctly?

### All Terrains Show ASCII
**Problem:** Everything renders as ASCII characters  
**Check:**
1. Is base game loaded? (`load("/data/general/grids/basic.lua")`)
2. Are base entities (FLOOR, WALL) available?
3. ToME tileset installation correct?

### Most Terrains Skipped (⊘)
**Problem:** Many terrains show `⊘ MISSING` in log  
**This is normal!** The gallery probes 90+ terrain IDs. Not all exist in every ToME installation.

**Expected:** 40-50 skipped terrains is typical  
**Only investigate if:**
1. ALL terrains are skipped (check manifest loading)
2. All DCCB terrains are skipped (check grids.lua)
3. Placed count is very low (<10)

### Dangerous Terrains (⚠)
**Problem:** Some terrains show `⚠ DANGEROUS` in log  
**This is intentional!** These terrains have change_level/on_stand hooks that would cause zone transitions.

**Expected:** 5-10 dangerous terrains is normal  
**Action:** None needed - these are automatically filtered for safety

### Terrain Pack Load Failures
**Problem:** "Failed to load terrain pack" messages  
**This is expected** for non-existent packs. Common scenarios:
1. jungle_hut.lua may not exist in all ToME versions
2. Some packs are expansion/mod-specific
3. Gallery continues safely without them

**Only investigate if:** All terrain packs fail to load (ToME installation issue)

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
