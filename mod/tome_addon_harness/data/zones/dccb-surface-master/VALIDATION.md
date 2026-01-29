# dccb-surface-master Zone - Validation Guide

## Overview
This zone demonstrates the DCCB surface painter/template system with **seed-based auto-selection**. It follows the proven patterns from dccb-start and is reached via a one-time handoff from dccb-start.

**New in this version:** Auto-selects templates based on run seed instead of using a fixed template.

**Handoff mechanism:** The transition from dccb-start to dccb-surface-master happens via the Actor:move hook in `hooks/load.lua` when the player first moves in dccb-start. The zone `on_enter` callback doesn't fire reliably during initial zone generation.

## Flow Sequence

1. **Game starts** → Game.lua superload redirects from wilderness to `dccb-start`
2. **dccb-start zone generates** → Template picker and painter create the map
3. **Player makes first move** → Actor:move hook fires in hooks/load.lua
4. **Handoff executes** → `game:changeLevel(1, "dccb+dccb-surface-master")`
5. **Player enters dccb-surface-master** → `post_process` runs with template picker
6. **Template selection** → Seed-based auto-selection from {plains, road, courtyard}
7. **Surface painting** → Painter applies selected template

## Files Created

### Zone Descriptor (data/)
- `/mod/tome_addon_harness/data/zones/dccb-surface-master/zone.lua`
  - Zone metadata and generation config
  - **Template selection**: Seed-based auto-selection (nil = auto, or set to template name for override)
  - Empty generator (no Roomer, no auto-stairs)
  - Signature-agnostic post_process with painter integration
  - Reuses cached seed from `game._DCCB_RUN_SEED` for consistency

### Resource Files (overload/)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/grids.lua`
  - Core grids: GRASS, ROAD, TREE
  - Optional grids: SNOW, RUINS
  - DCCB_ENTRANCE (inert marker, no transitions)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/npcs.lua` (empty)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/objects.lua` (empty)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/traps.lua` (empty)

## Key Features

### Template Selection System
The zone uses **seed-based auto-selection** with **themed visual variations**:
```lua
local DCCB_SURFACE_TEMPLATE = nil  -- Auto-selection enabled
```

**Auto-selection logic:**
- Extracts seed from game.run_seed, game._DCCB_RUN_SEED (cached), game.start_time, or fallbacks
- Selects template using `(seed % 6) + 1` from 6 available templates
- Each template has distinct visual theme with appropriate tilesets
- Logs seed source and selected template

**Available Templates (6 total):**

**Green/Plains Theme** (3 templates):
- `plains` - Green grass with tree border
- `road` - Green grass with dirt road and trees
- `courtyard` - Green grass courtyard with trees
- Tilesets: grass.png (green), road_dirt_6_1.png (brown dirt), tree.png (green trees)

**Winter/Snow Theme** (2 templates):
- `winter` - Snowy ground with snowy trees
- `winter_road` - Snowy ground with icy path and trees
- Tilesets: snow_ground.png (white), tree.png (for snowy trees)

**Ruins/Ancient Theme** (1 template):
- `ruins` - Weathered stone with ruined pillars
- Tilesets: marble_floor.png (grey stone), grey_stone_wall1.png (ruins)

**Debug override:** Set to force a specific template:
```lua
local DCCB_SURFACE_TEMPLATE = "plains"      -- Force green plains
local DCCB_SURFACE_TEMPLATE = "winter"      -- Force snowy winter
local DCCB_SURFACE_TEMPLATE = "ruins"       -- Force ancient ruins
local DCCB_SURFACE_TEMPLATE = "winter_road" -- Force winter with icy path
```

### Zone Configuration
- **Name**: "DCCB Surface Master"
- **Short name**: "dccb-surface-master"
- **Dimensions**: 30x30
- **Max level**: 1 (single level only)
- **No level connectivity**: Prevents automatic generation of levels 2 and beyond
- **Persistent**: "zone" (zone persists in save)
- **All remembered/lited**: Full visibility for testing

### Generator Settings
- **Map generator**: engine.generator.map.Empty (blank canvas)
- **No spawns**: nb_npc={0,0}, nb_object={0,0}, nb_trap={0,0}
- **No stair mappings**: No up/down/door to prevent auto-stairs

## Validation Steps

### 1. Basic Flow Test (With Handoff)
1. Launch ToME with the addon enabled
2. Start a new character/run
3. Observe the following sequence:
   - Brief landing in **dccb-start** (bootstrap zone)
   - Make first move (arrow key or any movement)
   - Automatic transition to **dccb-surface-master** (once per run)
4. Verify you are now in dccb-surface-master zone

### 2. Log Verification (te4_log.txt)
Expected log sequence showing the complete flow:
```
[DCCB] early redirect: changeLevelReal from wilderness to dccb+dccb-start
[DCCB-Zone] Template auto-selected: [template] (seed=[X] from [source], idx=[1-3]/3)
[DCCB-Painter] Starting surface paint with template '[template_name]'
[DCCB-Painter] Base fill: 900 cells with 'GRASS'
...
[DCCB] first zone observed after bootstrap
[DCCB] current zone short_name: dccb-start
[DCCB] entered DCCB stub zone: dccb-start
[DCCB] ========================================
[DCCB] Handoff: dccb-start -> dccb-surface-master
[DCCB] ========================================
[DCCB] Transitioning to: dccb+dccb-surface-master
[DCCB] Handoff complete (once per run)
[DCCB] ========================================
[DCCB-SurfaceMaster] Entered zone 'dccb-surface-master' level 1
[DCCB-SurfaceMaster] Template auto-selected: [plains|road|courtyard] (seed=[X] from [source], idx=[1-3]/3, templates=plains,road,courtyard)
[DCCB-Painter] Starting surface paint with template '[template_name]'
[DCCB-Painter] Base fill: 900 cells with 'GRASS'
[DCCB-Painter] Edge ring: 60-100 'TREE' cells placed (thickness=2, step=3)
[DCCB-Painter] Total decorations: 60-100 cells
[DCCB-Painter] Entrances: 2 'DCCB_ENTRANCE' markers placed
[DCCB-Painter] Completed template '[template_name]': base=900, decorations=60-100, entrances=2
[DCCB-SurfaceMaster] Surface template '[template_name]' applied
```

**Key points to verify:**
- dccb-start zone generates first (you'll see its template selection)
- Handoff messages appear after first zone observed
- Template selection in surface-master shows auto-selected (not override/fixed)
- Seed source is logged (game.run_seed, cached, etc.)
- Both painters complete successfully

### 3. No Loop Verification
- Move around the map
- Verify NO repeated zone transitions
- Verify NO repeated handoff messages in log
- The handoff should happen exactly once per run (guarded by `game._DCCB_HANDOFF_DONE`)

### 4. Visual Verification
- Map should render with visible terrain (not black/empty)
- Terrain appearance depends on selected theme:
  - **Green themes**: Green grass (,), brown roads (=), green trees (T)
  - **Winter themes**: White snow (.), light blue ice (=), white trees (T)
  - **Ruins theme**: Grey stone (,), dark paths (=), grey pillars (#)
- Trees/obstacles form a sparse border
- Two entrance markers (>) visible in yellow
- No "next level here" or staircase messages

### 5. Movement Test
- Base terrain (GRASS/GRASS_WINTER/GRASS_RUINS): passable, player can walk through
- Roads (ROAD/ROAD_WINTER/ROAD_RUINS): passable, player can walk through
- Obstacles (TREE/TREE_WINTER/TREE_RUINS): blocks movement and sight (impassable)
- ENTRANCE markers: passable, shows "[DCCB] Dungeon entrance not implemented yet" message

### 6. Level Check
- Press '<' or '>' (if available) - should NOT trigger level change
- Check status: should show level 1 only
- No level 2 or deeper levels generated

## Expected Outputs

### Terrain Distribution (varies by template and theme)

**Green Theme Templates (plains/road/courtyard):**
- Base: 900 cells filled with GRASS (green grass)
- Decorations: ~60-100 TREE cells (green trees) forming edge ring
- Road (road template only): 90 ROAD cells (brown dirt path)
- Entrances: 2 DCCB_ENTRANCE markers

**Winter Theme Templates (winter/winter_road):**
- Base: 900 cells filled with GRASS_WINTER (white snow)
- Decorations: ~60-100 TREE_WINTER cells (snowy trees) forming edge ring  
- Road (winter_road only): 90 ROAD_WINTER cells (icy path)
- Entrances: 2 DCCB_ENTRANCE markers

**Ruins Theme Template (ruins):**
- Base: 900 cells filled with GRASS_RUINS (grey weathered stone)
- Decorations: ~60-100 TREE_RUINS cells (ruined pillars) forming edge ring
- Entrances: 2 DCCB_ENTRANCE markers

### Grid Resolution
All grids should resolve via zone:makeEntityByName without "grid not found" errors:

**Green Theme:**
- GRASS ✓ (green grass tile)
- ROAD ✓ (brown dirt path tile)
- TREE ✓ (green tree tile)

**Winter Theme:**
- GRASS_WINTER ✓ (white snow tile)
- ROAD_WINTER ✓ (icy path tile)
- TREE_WINTER ✓ (snowy tree tile)

**Ruins Theme:**
- GRASS_RUINS ✓ (grey stone tile)
- ROAD_RUINS ✓ (ancient path tile)
- TREE_RUINS ✓ (ruined pillar tile)

**Universal:**
- DCCB_ENTRANCE ✓ (entrance marker on grass)

## Known Limitations

### Not Implemented
- No gameplay systems (NPCs, items, traps)
- No level transitions (entrances are inert markers)
- No dungeon connections
- No POIs or special features
- No roaming encounters
- No settlements

### By Design
- Single level only (no -2, -3, etc.)
- No automatic spawns
- No inter-level stairs
- Seed-based template selection (varies per run)
- Accessed via one-time handoff from dccb-start

## Testing Other Templates

To test a specific template, edit zone.lua line 8:
```lua
-- Change from:
local DCCB_SURFACE_TEMPLATE = nil  -- Auto-selection

-- To force a specific template:
local DCCB_SURFACE_TEMPLATE = "plains"      -- Green grass with trees
local DCCB_SURFACE_TEMPLATE = "road"        -- Green grass with dirt road
local DCCB_SURFACE_TEMPLATE = "courtyard"   -- Green grass courtyard
local DCCB_SURFACE_TEMPLATE = "winter"      -- Snowy landscape
local DCCB_SURFACE_TEMPLATE = "winter_road" -- Snowy with icy path
local DCCB_SURFACE_TEMPLATE = "ruins"       -- Ancient weathered ruins
```

Available templates: plains, road, courtyard, winter, winter_road, ruins

## Customizing Tilesets

The visual appearance of tiles is controlled in `grids.lua` via the `image` property. To change how grass, roads, or trees look:

**Edit:** `mod/tome_addon_harness/overload/data/zones/dccb-surface-master/grids.lua`

**Example - Change grass to a different tileset:**
```lua
newEntity{
  base = "FLOOR",
  define_as = "GRASS",
  name = "grass",
  image = "terrain/grass.png",  -- Change this to any ToME terrain image
  -- Try: "terrain/forest_grass_01.png", "terrain/grass2.png", etc.
}
```

**Current tilesets used:**
- GRASS: `terrain/grass.png` (green grass)
- ROAD: `terrain/road_dirt_6_1.png` (dirt path)
- TREE: `terrain/tree.png` (tree)
- SNOW: `terrain/snow_ground.png` (snow)
- RUINS: `terrain/grey_stone_wall1.png` (stone ruins)

**To explore available tilesets:**
- Look in ToME's data directory: `/data/gfx/shockbolt/terrain/`
- Common outdoor tiles: grass, dirt, stone, snow, water, forest, etc.
- Common dungeon tiles: marble_floor, stone_wall, brick, etc.

**Note:** Without an `image` property, terrains inherit the base entity's tileset (usually dungeon bricks/stone).

## Integration Pattern

This zone follows the ToME-Integration-Notes.md §2.5 Stable Custom Zone Generation Pattern plus handoff:

1. **Entry Flow**: wilderness → dccb-start (via Game.lua superload) → dccb-surface-master (via on_enter handoff)
2. **File Path Split**: zone.lua in data/, resources in overload/
3. **Explicit Load Directives**: All resource files listed in load array
4. **Empty Generator**: No hidden behaviors, blank canvas
5. **Signature-Agnostic post_process**: Capability-based argument detection
6. **Virtual Path Loading**: Uses loadfile("/data-dccb/...") for painter/templates
7. **Seed-based Template Selection**: Reuses game._DCCB_RUN_SEED for determinism

## Troubleshooting

### "Grid not found" errors
- Check that grids.lua is in overload/data/zones/dccb-surface-master/
- Verify load directive includes "/data/zones/dccb-surface-master/grids.lua"
- Ensure newEntity{define_as="GRID_NAME"} exists for each grid

### Black/empty map
- Check post_process executed (look for painter messages in log)
- Verify painter module loaded successfully
- Check fallback filled with GRASS if painter failed

### "Next level here" messages
- Verify generator.map has NO up/down/door mappings
- Check no_level_connectivity = true
- Ensure max_level = 1

### Lua errors on load
- Check syntax in all .lua files
- Verify file paths in load array match actual file locations
- Check that all referenced grids are defined in grids.lua
