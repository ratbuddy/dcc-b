# dccb-surface-master Zone - Validation Guide

## Overview
This zone demonstrates the DCCB surface painter/template system with **seed-based auto-selection**. It follows the proven patterns from dccb-start and is reached via a one-time handoff from dccb-start.

**New in this version:** Auto-selects templates based on run seed instead of using a fixed template.

## Flow Sequence

1. **Game starts** → Game.lua superload redirects from wilderness to `dccb-start`
2. **Player enters dccb-start** → `on_enter` fires one-time handoff
3. **Handoff executes** → `game:changeLevel(1, "dccb+dccb-surface-master")`
4. **Player enters dccb-surface-master** → `post_process` runs with template picker
5. **Template selection** → Seed-based auto-selection from {plains, road, courtyard}
6. **Surface painting** → Painter applies selected template

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
The zone now uses **seed-based auto-selection** like dccb-start:
```lua
local DCCB_SURFACE_TEMPLATE = nil  -- Auto-selection enabled
```

**Auto-selection logic:**
- Extracts seed from game.run_seed, game._DCCB_RUN_SEED (cached), game.start_time, or fallbacks
- Selects template using `(seed % 3) + 1` from {plains, road, courtyard}
- Logs seed source and selected template

**Debug override:** Set to a template name to force specific template:
```lua
local DCCB_SURFACE_TEMPLATE = "plains"  -- Force plains template
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
   - Automatic transition to **dccb-surface-master** (once per run)
4. Verify you are now in dccb-surface-master zone
2. Use debug commands or zone redirect to enter "dccb-surface-master"
3. Check for Lua errors in te4_log.txt

### 2. Log Verification (te4_log.txt)
Expected log sequence showing the complete flow:
```
[DCCB] early redirect: changeLevelReal from wilderness to dccb+dccb-start
[DCCB-Zone] Entered zone 'dccb-start' level 1
[DCCB-Zone] ========================================
[DCCB-Zone] Handoff: dccb-start -> dccb-surface-master
[DCCB-Zone] ========================================
[DCCB-Zone] Transitioning to: dccb+dccb-surface-master
[DCCB-Zone] Handoff complete (once per run)
[DCCB-Zone] ========================================
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
- Handoff messages appear exactly once
- Template selection shows auto-selected (not override/fixed)
- Seed source is logged (game.run_seed, cached, etc.)
- Painter completes successfully

### 3. No Loop Verification
- Move around the map
- Verify NO repeated zone transitions
- Verify NO repeated handoff messages in log
- The handoff should happen exactly once per run (guarded by `game._DCCB_HANDOFF_DONE`)

### 4. Visual Verification
- Map should render with visible terrain (not black/empty)
- Grass (,) covers most of the map in light green
- Trees (T) form a sparse border in green
- Two entrance markers (>) visible in yellow
- No "next level here" or staircase messages

### 4. Movement Test
- GRASS and ROAD: passable, player can walk through
- TREE: blocks movement and sight (impassable)
- ENTRANCE markers: passable, shows "[DCCB] Dungeon entrance not implemented yet" message

### 6. Level Check
- Press '<' or '>' (if available) - should NOT trigger level change
- Check status: should show level 1 only
- No level 2 or deeper levels generated

## Expected Outputs

### Terrain Distribution (varies by template)
**Plains template:**
- Base: 900 cells (30x30) filled with GRASS
- Decorations: ~60-100 TREE cells forming edge ring (step=3, thickness=2)
- Entrances: 2 DCCB_ENTRANCE markers (center-left and center-right)

**Road template:**
- Base: 900 cells filled with GRASS
- Vertical road: 3-cell wide ROAD in center
- Tree border: ~60-100 TREE cells at edges
- Entrances: 2 DCCB_ENTRANCE markers

**Courtyard template:**
- Similar to plains (grass + tree border)
- Entrances: 2 DCCB_ENTRANCE markers

### Grid Resolution
All grids should resolve via zone:makeEntityByName without "grid not found" errors:
- GRASS ✓
- ROAD ✓ (used in road template)
- TREE ✓
- SNOW ✓ (defined but not currently used in any template)
- RUINS ✓ (defined but not currently used in any template)
- DCCB_ENTRANCE ✓

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
local DCCB_SURFACE_TEMPLATE = "plains"    -- Force plains
local DCCB_SURFACE_TEMPLATE = "road"      -- Force road (adds vertical road)
local DCCB_SURFACE_TEMPLATE = "courtyard" -- Force courtyard
```

Available templates: plains, road, courtyard

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
