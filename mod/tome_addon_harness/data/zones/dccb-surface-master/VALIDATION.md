# dccb-surface-master Zone - Validation Guide

## Overview
This zone demonstrates the DCCB surface painter/template system in a deterministic, production-ready way. It follows the proven patterns from dccb-start but uses a fixed template for predictable testing.

## Files Created

### Zone Descriptor (data/)
- `/mod/tome_addon_harness/data/zones/dccb-surface-master/zone.lua`
  - Zone metadata and generation config
  - Fixed template selection: "plains"
  - Empty generator (no Roomer, no auto-stairs)
  - Signature-agnostic post_process with painter integration

### Resource Files (overload/)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/grids.lua`
  - Core grids: GRASS, ROAD, TREE
  - Optional grids: SNOW, RUINS
  - DCCB_ENTRANCE (inert marker, no transitions)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/npcs.lua` (empty)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/objects.lua` (empty)
- `/mod/tome_addon_harness/overload/data/zones/dccb-surface-master/traps.lua` (empty)

## Key Features

### Deterministic Template Selection
Unlike dccb-start which auto-selects templates based on run seed, dccb-surface-master uses:
```lua
local DCCB_SURFACE_TEMPLATE = "plains"
```
This ensures consistent, predictable map generation for testing and validation.

### Zone Configuration
- **Name**: "DCCB Surface Master"
- **Short name**: "dccb-surface-master"
- **Dimensions**: 30x30
- **Max level**: 1 (single level only)
- **No level connectivity**: Prevents automatic level 2+ generation
- **Persistent**: "zone" (zone persists in save)
- **All remembered/lited**: Full visibility for testing

### Generator Settings
- **Map generator**: engine.generator.map.Empty (blank canvas)
- **No spawns**: nb_npc={0,0}, nb_object={0,0}, nb_trap={0,0}
- **No stair mappings**: No up/down/door to prevent auto-stairs

## Validation Steps

### 1. Basic Load Test
1. Launch ToME with the addon enabled
2. Use debug commands or zone redirect to enter "dccb-surface-master"
3. Check for Lua errors in te4_log.txt

### 2. Log Verification (te4_log.txt)
Expected log messages:
```
[DCCB-SurfaceMaster] Entered zone 'dccb-surface-master' level 1
[DCCB-SurfaceMaster] Template fixed: plains (available templates=plains,road,courtyard)
[DCCB-SurfaceMaster] Loaded template 'plains'
[DCCB-Painter] Starting surface paint with template 'plains'
[DCCB-Painter] Base fill: 900 cells with 'GRASS'
[DCCB-Painter] Edge ring: XX 'TREE' cells (thickness=2, step=3)
[DCCB-Painter] Total decorations: XX cells
[DCCB-Painter] Entrances: 2 'DCCB_ENTRANCE' markers placed
[DCCB-Painter] Completed template 'plains': base=900, decorations=XX, entrances=2
[DCCB-SurfaceMaster] Surface template 'plains' applied
```

### 3. Visual Verification
- Map should render with visible terrain (not black/empty)
- Grass (,) covers most of the map in light green
- Trees (T) form a sparse border in green
- Two entrance markers (>) visible in yellow
- No "next level here" or staircase messages

### 4. Movement Test
- GRASS and ROAD: passable, player can walk through
- TREE: blocks movement and sight (impassable)
- ENTRANCE markers: passable, shows "[DCCB] Dungeon entrance not implemented yet" message

### 5. Level Check
- Press '<' or '>' (if available) - should NOT trigger level change
- Check status: should show level 1 only
- No level 2 or deeper levels generated

## Expected Outputs

### Terrain Distribution
- Base: 900 cells (30x30) filled with GRASS
- Decorations: ~60-100 TREE cells forming edge ring (step=3, thickness=2)
- Entrances: 2 DCCB_ENTRANCE markers (center-left and center-right)

### Grid Resolution
All grids should resolve via zone:makeEntityByName without "grid not found" errors:
- GRASS ✓
- ROAD ✓ (not used in plains template, but defined)
- TREE ✓
- SNOW ✓ (defined but not used in plains template)
- RUINS ✓ (defined but not used in plains template)
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
- Fixed template (not randomized)

## Testing Other Templates

To test other templates, edit zone.lua line 7:
```lua
-- Change from:
local DCCB_SURFACE_TEMPLATE = "plains"

-- To:
local DCCB_SURFACE_TEMPLATE = "road"      -- Adds vertical road
local DCCB_SURFACE_TEMPLATE = "courtyard" -- Same as plains
```

Available templates: plains, road, courtyard

## Integration Pattern

This zone follows the ToME-Integration-Notes.md §2.5 Stable Custom Zone Generation Pattern:

1. **File Path Split**: zone.lua in data/, resources in overload/
2. **Explicit Load Directives**: All resource files listed in load array
3. **Empty Generator**: No hidden behaviors, blank canvas
4. **Signature-Agnostic post_process**: Capability-based argument detection
5. **Virtual Path Loading**: Uses loadfile("/data-dccb/...") for painter/templates

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
