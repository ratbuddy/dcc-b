# ToME Zone Construction Specification (DCCB)

> Canonical reference for building stable, themed, randomly generated zones in Tales of Maj’Eyal (T-Engine4).
>
> This document is intended to serve three roles:
> • Human reference when writing zones
> • Ground truth for addon documentation
> • Prompt material for Copilot / LLM-based generation

---

# 1. Mental Model: How ToME Builds a Zone

A zone is constructed in **four strict phases**:

## 1) Entity Registration
Loaded before any generation occurs.

Files automatically attempted by the engine:
```
/data/zones/<zone>/grids.lua
/data/zones/<zone>/npcs.lua
/data/zones/<zone>/objects.lua
/data/zones/<zone>/traps.lua
```

All `newEntity{ define_as = "..." }` entries are registered into the zone’s factory.

Nothing is placed yet. Only definitions exist.

---

## 2) Map Generation (Topology)
Handled by `engine.generator.map.*`

Examples:
• Forest → outdoor shapes
• Roomer → rooms + corridors
• Cavern → organic caves
• Static → premade maps
• Empty → nothing (manual painting)

This phase places **grid IDs**, not visuals.

---

## 3) Spawn Generation
NPCs, objects, traps are placed by their respective generators.

---

## 4) post_process (Authoritative Final Pass)
This is the **only fully reliable manual hook**.

Typical uses:
• Guaranteed terrain painting
• Stair placement
• Quest features
• Zone theming
• Corrections and overrides

Your experiments confirmed:
> post_process is the safest and most powerful place to do custom logic.

---

# 2. Directory Contract

Canonical zone directory structure:

```
data/zones/<zone-id>/
  zone.lua
  grids.lua
  npcs.lua
  objects.lua
  traps.lua
  rooms/
  maps/
  vaults/
```

Strong recommendation: always declare loads explicitly.

```lua
load = {
  "/data/zones/<zone>/grids.lua",
  "/data/zones/<zone>/npcs.lua",
  "/data/zones/<zone>/objects.lua",
  "/data/zones/<zone>/traps.lua",
}
```

This prevents silent resolution failures.

---

# 3. zone.lua – Canonical Structure

Minimal stable skeleton:

```lua
return {
  name = "Zone Name",
  short_name = "zone-id",

  level_range = {1, 10},
  max_level = 5,

  width = 50, height = 50,

  persistent = "zone",
  all_remembered = true,
  all_lited = false,

  load = {
    "/data/zones/zone-id/grids.lua",
    "/data/zones/zone-id/npcs.lua",
    "/data/zones/zone-id/objects.lua",
    "/data/zones/zone-id/traps.lua",
  },

  generator = { ... },

  levels = { ... },

  post_process = function(...) end,
}
```

Zone files are **primarily declarative**. Logic should be minimal and controlled.

---

# 4. Generators – What They Actually Do

Generators **place symbolic grid IDs only.**

They do not control visuals.

## Common map generators

### Forest (outdoor)
```lua
map = {
  class = "engine.generator.map.Forest",
  floor = "GRASS",
  wall  = "TREE",
  road  = "ROAD",
  up    = "GRASS_UP",
  down  = "GRASS_DOWN",
  add_road = true,
  do_ponds = true,
}
```

### Roomer (dungeons)
```lua
map = {
  class = "engine.generator.map.Roomer",
  nb_rooms = 8,
  rooms = {"simple", "pillar"},
  ['#'] = {"WALL"},
  ['.'] = {"FLOOR"},
  door = "DOOR",
  up = "UP",
  down = "DOWN",
}
```

### Empty (manual control)
```lua
map = { class = "engine.generator.map.Empty" }
```

---

# 5. grids.lua – The Real Theme Layer

`grids.lua` defines what your zone **looks like**.

Stock zones always load base sets:

```lua
load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")
load("/data/general/grids/water.lua")
```

Then extend them:

```lua
newEntity{
  base = "FLOOR",
  define_as = "GRASS",
  name = "grass",
  image = "terrain/forest_grass_01.png",
  nice_tiler = { method="replace", ... },
}
```

### Critical truth

If your zone looks wrong, it is **almost always grids.lua**, not the generator.

---

# 6. nice_tiler & Visual Variation

Official zones avoid repetition using `nice_tiler` and tile families.

Example pattern:

```lua
newEntity{
  define_as="TREE",
  image="terrain/tree_base.png",
  nice_tiler = { method="replace", base={"TREE",1,20} }
}

for i=1,20 do
  newEntity{
    base="TREE",
    define_as="TREE_"..i,
    image="terrain/tree_"..i..".png",
  }
end
```

This allows automatic neighbor-aware tiling.

---

# 7. post_process – The Safe Manual Layer

Your validated safe pattern:

```lua
local Map = require "engine.Map"
local g = zone:makeEntityByName(level, "grid", "GRASS")
if g and g.resolve then g:resolve() end
level.map(x, y, Map.TERRAIN, g)
```

Rules:
• Never invent map helpers
• Always use zone factories
• Always treat post_process as final authority

Typical uses:
• guaranteed terrain
• stairs
• quest props
• final theming

---

# 8. Zone Visual Controls

Zones can define:

```lua
day_night = true
color_shown = {0.9, 1.0, 0.9}
color_obscure = {0.3, 0.4, 0.3}
nicer_tiler_overlay = "DungeonWallsGrass"
```

These affect lighting, tinting, and blending.

---

# 9. Full Template Zone (All Options)

```lua
return {
  name = "Template Zone",
  short_name = "template-zone",

  level_range = {1, 20},
  max_level = 5,
  width = 50, height = 50,

  persistent = "zone",
  all_remembered = true,
  all_lited = false,
  day_night = true,

  color_shown = {0.9, 1.0, 0.9},
  color_obscure = {0.3, 0.4, 0.3},

  nicer_tiler_overlay = "DungeonWallsGrass",

  load = {
    "/data/zones/template-zone/grids.lua",
    "/data/zones/template-zone/npcs.lua",
    "/data/zones/template-zone/objects.lua",
    "/data/zones/template-zone/traps.lua",
  },

  generator = {
    map = {
      class = "engine.generator.map.Forest",
      floor = "GRASS",
      wall  = "TREE",
      road  = "ROAD",
      up    = "GRASS_UP",
      down  = "GRASS_DOWN",
      add_road = true,
      do_ponds = true,
    },

    actor = { class = "engine.generator.actor.Random", nb_npc = {8, 12} },
    object = { class = "engine.generator.object.Random", nb_object = {4, 8} },
    trap   = { class = "engine.generator.trap.Random",   nb_trap   = {0, 2} },
  },

  post_process = function(...) end,
}
```

---

# 10. Recommended Zone Development Workflow

1. Copy a stock zone near your theme
2. Make it render correctly unmodified
3. Strip it down to floor + wall
4. Replace grids
5. Validate visuals
6. Introduce procedural variation
7. Add gameplay logic last

---

# 11. DCCB-Specific Notes

For DCCB:

• Generators define topology
• grids.lua defines art direction
• post_process defines gameplay intent

Your surface template system is correctly layered.

Once grids inherit proper forest/snow/cave sets, templates will visually diverge without logic changes.

---

# 12. Terrain Resources and Grid Selection

**Available Resources:** TE4 Grid Catalog (comprehensive terrain metadata)  
**Location:** `/docs/te4_grid_catalog.json` and `/docs/te4_grid_ids_by_category/*.txt`  
**Documentation:** See `TE4_GRID_SAFETY_ANALYSIS.md` for detailed safety analysis

## 12.1 Using Categorized Terrain Lists

The TE4 Grid Extractor has generated pre-categorized terrain lists that are safe for zone generation:

**Safe Categories for Templates:**
- **`floor.txt`**: Passable floor terrain (FLOOR, GRASS, ROAD, SAND, SNOW, etc.)
- **`wall.txt`**: Blocking walls and obstacles (WALL, ROCK, MOUNTAIN, etc.)
- **`feature.txt`**: Non-blocking decorative features (ALTAR, STATUE, PILLAR, etc.)
- **`vegetation.txt`**: Trees, bushes, thickets (TREE, BUSH, etc.)
- **`water.txt`**: Water terrain (WATER, RIVER, SHALLOW_WATER, etc.)

**Use with Caution:**
- **`lava.txt`**: Lava terrain (deals damage via `on_stand` effects)
- **`door.txt`**: Doors (blocking when closed, requires context)

**Avoid in Generic Templates:**
- **`special.txt`**: Contains stairs, portals, level/zone transitions (dangerous)

## 12.2 Example: Theme-Based Terrain Selection

```lua
-- In grids.lua, load base terrain
load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")

-- In zone.lua generator configuration
generator = {
  map = {
    class = "engine.generator.map.Forest",
    -- For forest theme, use vegetation category
    floor = "GRASS",           -- from floor.txt
    wall  = "TREE",            -- from vegetation.txt (blocks)
    road  = "ROAD",            -- from floor.txt
    up    = "GRASS_UP",        -- Note: stairs are in special.txt
    down  = "GRASS_DOWN",
  },
}

-- For volcanic theme
generator = {
  map = {
    class = "engine.generator.map.Cavern",
    floor = "VOLCANIC_FLOOR",  -- from floor.txt
    wall  = "VOLCANIC_WALL",   -- from wall.txt
    -- Add lava pools in post_process using lava.txt
  },
}
```

## 12.3 Safe Terrain Selection in post_process

```lua
post_process = function(level)
  local Map = require "engine.Map"
  
  -- Safe floor terrain pool (from floor.txt)
  local safe_floors = {"FLOOR", "GRASS", "DIRT", "ROAD"}
  
  -- Safe wall terrain pool (from wall.txt)
  local safe_walls = {"WALL", "TREE_WALL", "ROCK"}
  
  -- Paint random floors in a room
  for x = 10, 20 do
    for y = 10, 20 do
      local floor_id = safe_floors[rng.range(1, #safe_floors)]
      local g = zone:makeEntityByName(level, "grid", floor_id)
      if g and g.resolve then g:resolve() end
      level.map(x, y, Map.TERRAIN, g)
    end
  end
end
```

## 12.4 Checking Terrain Safety

Before using a grid ID, check its metadata in `te4_grid_catalog.json`:

```lua
-- Python example for validation
import json

with open('docs/te4_grid_catalog.json', 'r') as f:
    catalog = json.load(f)

grid_id = "LAVA"
meta = catalog['meta'][grid_id]

# Check safety flags
if meta['is_dangerous']:
    print(f"WARNING: {grid_id} is dangerous!")
    print(f"  - change_level: {meta['change_level']}")
    print(f"  - change_zone: {meta['change_zone']}")
    print(f"  - on_stand: {meta['on_stand']}")

if meta['is_blocking']:
    print(f"{grid_id} blocks movement")
```

## 12.5 Gallery Safe List

For showcases and galleries, use the pre-filtered safe list:

**`te4_gallery_safe_ids.txt`** contains:
- All terrain from: floor + wall + vegetation + water + lava + feature
- Excludes: special (stairs, portals) and door categories
- Safe for visual showcases and testing

## 12.6 Related Documentation

- **`TE4_GRID_SAFETY_ANALYSIS.md`**: Detailed safety analysis for each category
- **`TERRAIN_GALLERY_PROMPT.md`**: How to create a comprehensive terrain gallery
- **`TE4_EXTRACTOR_USAGE.md`**: How to update the grid catalog
- **`ToME-Integration-Notes.md`**: Section 10 on terrain resources

---

# Appendix A – LLM Reference Pack

When asking Copilot / LLMs to generate zones, prepend:

> You are writing ToME4 zones. Follow this strictly:
> • grids.lua defines visuals
> • generators place grid IDs only
> • post_process is final authority
> • use zone:makeEntityByName + Map.TERRAIN
> • never invent map helpers
> • always declare loads
> • copy stock zones when unsure

---

# Appendix B – Copilot Template Prompt

```
You are writing a Tales of Maj’Eyal zone.

Constraints:
- Follow official ToME zone structure
- grids.lua controls visuals
- generators only place grid IDs
- post_process is authoritative
- use zone:makeEntityByName(level, "grid", "ID")
- place with level.map(x,y,Map.TERRAIN,g)
- never invent map helpers
- always declare load paths

Goal:
[describe theme]

Output:
- zone.lua
- grids.lua
- explanation of generator choice
```

---

# End of Specification

