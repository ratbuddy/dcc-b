# Surface Template System

## Overview
The surface template system provides a clean, modular way to define and render deterministic surface layouts for the dccb-start zone using the known-good Empty generator.

## Components

### 1. Painter Module
**Location:** `mod/tome_addon_harness/data/dccb/surface/painter.lua`

The painter module provides the `paint_surface(level, zone, template)` function that:
- Validates inputs (level.map, zone.makeEntityByName)
- Uses correct ToME APIs:
  - `zone:makeEntityByName(level, "grid", "DEFINE_AS")` for grid resolution
  - `level.map(x, y, Map.TERRAIN, grid)` for terrain placement
- Applies template features in deterministic order:
  1. Base fill (entire map)
  2. Decorations (e.g., edge rings, roads)
  3. Entrances (1-2 markers)
- Logs all operations for debugging
- Fails gracefully without crashing on invalid inputs

### 2. Templates
**Location:** `mod/tome_addon_harness/data/dccb/surface/templates/`

Templates are pure data Lua files that return a table with:
- `name`: Template identifier
- `base`: Base terrain grid (e.g., "GRASS")
- `decorations`: Array of decoration specs
  - Each has `kind`, `grid`, and kind-specific parameters
- `entrances`: Entrance marker configuration
  - `count`: Number of entrances (1-2)
  - `grid`: Grid type for entrances (e.g., "DCCB_ENTRANCE")

**Available Templates:**
- `plains.lua`: Simple grassy area with tree border
- `road.lua`: Grassy area with vertical road and tree border

**Supported Decoration Kinds:**
- `edge_ring`: Places grids in a ring around map edges
  - Parameters: `grid`, `thickness`, `step`
- `vertical_road`: Places a vertical road down the center
  - Parameters: `grid`, `width`

### 3. Zone Integration
**Location:** `mod/tome_addon_harness/data/zones/dccb-start/zone.lua`

The zone descriptor:
- Defines a constant `DCCB_SURFACE_TEMPLATE` for template selection (currently "plains")
- Loads the painter module via `loadfile("/data-dccb/dccb/surface/painter.lua")()`
- Loads the selected template via `loadfile("/data-dccb/dccb/surface/templates/{name}.lua")()`
- Calls `painter.paint_surface(level, zone, template)` in post_process
- Has robust fallback behavior if painter or template loading fails

## How to Use

### Selecting a Template
Edit the `DCCB_SURFACE_TEMPLATE` constant at the top of `zone.lua`:
```lua
local DCCB_SURFACE_TEMPLATE = "plains"  -- Options: "plains", "road"
```

### Adding New Templates
1. Create a new file in `mod/tome_addon_harness/data/dccb/surface/templates/{name}.lua`
2. Return a table with the template structure (see existing templates as examples)
3. Use only existing grid definitions: GRASS, TREE, ROAD, DCCB_ENTRANCE
4. Update the template selection constant in zone.lua to use your new template

### Extending Decoration Types
To add new decoration kinds:
1. Add a handler function in `painter.lua` (e.g., `apply_horizontal_road`)
2. Add a case for the new kind in `apply_decorations`
3. Document the new kind and its parameters

## Future Extensions
The system is designed to support:
- Random template selection (replace constant with random choice)
- Dynamic template parameters based on game state
- Template variants with different layouts
- More complex decoration patterns
- Template composition (combining multiple templates)

## Technical Notes
- Templates are loaded via `loadfile()` to work with ToME's virtual path system
- All grid placements use the correct API: `zone:makeEntityByName` + `level.map`
- The system is fail-soft: errors are logged but don't crash the game
- All operations are deterministic (no randomness introduced)
- Entrance positions are currently hardcoded to predictable locations

## Logging
The system logs to console:
- Template selection: `[DCCB-Zone] Loaded template 'plains'`
- Painter operations: `[DCCB-Painter] Starting surface paint with template 'plains'`
- Base fill: `[DCCB-Painter] Base fill: 900 cells with 'GRASS'`
- Decorations: `[DCCB-Painter] Edge ring: 84 'TREE' cells (thickness=2, step=3)`
- Entrances: `[DCCB-Painter] Entrances: 2 'DCCB_ENTRANCE' markers placed`
- Completion: `[DCCB-Painter] Completed template 'plains': base=900, decorations=84, entrances=2`

All log messages are prefixed with `[DCCB-Zone]` or `[DCCB-Painter]` for easy filtering.
