# Terrain Gallery Map Generation Prompt

**Version**: 1.0  
**Date**: 2026-01-31  
**Purpose**: Comprehensive terrain gallery for testing and visualization

---

## Mission

Create a ToME zone that serves as a **terrain gallery** - a visual catalog displaying all available terrain types extracted from the TE4 grid catalog. This gallery will:

1. Display every grid ID from the extractor output in an organized, accessible layout
2. Group terrain by category (floor, wall, vegetation, water, lava, door, feature, special)
3. Provide clear visual separation and labeling for each category
4. Allow easy navigation and inspection of all terrain types
5. Serve as a reference for template work and terrain selection

---

## Prerequisites

Before starting, ensure you have:

1. ✅ **TE4 Grid Catalog**: `docs/te4_grid_catalog.json` (extractor output)
2. ✅ **Category Files**: `docs/te4_grid_ids_by_category/*.txt` (8 category files)
3. ✅ **Safe List**: `docs/te4_gallery_safe_ids.txt` (pre-filtered safe terrain)
4. ✅ **Safety Analysis**: Read `docs/TE4_GRID_SAFETY_ANALYSIS.md` for terrain safety guidelines

---

## Gallery Requirements

### 1. Zone Structure

**Zone Configuration:**
- **Name**: `terrain-gallery` or similar
- **Type**: Custom static zone (using `engine.generator.map.Static` or manual painting)
- **Size**: Large enough to display 100+ terrain tiles comfortably (recommend 80x80 or larger)
- **Theme**: Neutral, organized, easy to navigate

**Layout Strategy:**
Choose one of these approaches:

#### Option A: Category Rooms (Recommended)
- Separate room for each category
- Room labels (using feature grids or text overlays if possible)
- Connecting corridors between category rooms
- Each room displays all grids from that category in a grid pattern

#### Option B: Category Sections
- Single large open area
- Sections separated by walls or visual markers
- Each section displays a category with clear boundaries
- Linear or grid-based navigation

#### Option C: Museum Layout
- Central hub with 8 branching corridors
- Each corridor leads to a category exhibition area
- Gallery-style presentation with spacing between items

### 2. Terrain Display Pattern

For each terrain grid ID to display:

**Display Cell Pattern:**
```
W W W W W
W T T T W
W T G T W    G = Grid ID being displayed (center, 3x3 or 5x5 sample)
W T T T W    T = Neutral floor tile (FLOOR or similar)
W W W W W    W = Wall or boundary
```

**Spacing:**
- Leave 2-3 tiles between different grid displays
- Use neutral floor (FLOOR) for walkable areas
- Use clear walls (WALL) for boundaries

### 3. Category Organization

Display categories in this order (safest to most dangerous):

1. **Floor** (FLOOR, GRASS, ROAD, etc.)
2. **Wall** (WALL, ROCK, MOUNTAIN, etc.)
3. **Feature** (ALTAR, STATUE, PILLAR, etc.)
4. **Vegetation** (TREE, BUSH, THICKET, etc.)
5. **Water** (WATER, RIVER, etc.)
6. **Lava** (LAVA variants) ⚠️
7. **Door** (DOOR_CLOSED, DOOR_OPEN, etc.) ⚠️
8. **Special** (STAIRS, PORTAL, etc.) ❌ Use with extreme caution

### 4. Safety Considerations

**CRITICAL:**
- **Isolate special.txt terrain**: Place special terrain (stairs, portals) in a separate, clearly marked area
- **Prevent accidental transitions**: Add warning signs or impassable barriers around dangerous terrain
- **Test area**: Place the starting location in the safest category (floor)
- **Escape route**: Ensure there's always a safe path to exit the gallery

**Special Terrain Handling:**
- For `STAIRS_UP/DOWN`: Place in isolated alcoves or disable their function if possible
- For `PORTAL`: Same isolation as stairs
- For `on_stand` effects (lava): Place behind glass (impassable transparent terrain) if available
- For `change_level/zone`: Consider NOT including these in the gallery or placing at the very end

### 5. Zone File Structure

**File Location:** `/data/zones/terrain-gallery/`

**Required Files:**
- `zone.lua` - Zone definition and configuration
- `grids.lua` - Grid definitions (can reference base game grids)
- `npcs.lua` - Optional (keep empty or minimal)
- `objects.lua` - Optional (keep empty or minimal)

**Optional Files:**
- `traps.lua` - Optional (keep empty)

---

## Implementation Approach

### Phase 1: Data Preparation

1. **Load catalog data**:
   ```python
   import json
   
   with open('docs/te4_grid_catalog.json', 'r') as f:
       catalog = json.load(f)
   
   # Get IDs by category
   ids_by_category = {}
   for cat in ['floor', 'wall', 'feature', 'vegetation', 'water', 'lava', 'door', 'special']:
       with open(f'docs/te4_grid_ids_by_category/{cat}.txt', 'r') as f:
           ids_by_category[cat] = [line.strip() for line in f if line.strip()]
   ```

2. **Calculate layout dimensions**:
   - Count total grids to display
   - Determine grid-per-row based on zone size
   - Calculate required category room sizes

3. **Generate layout plan**:
   - Map out category room positions
   - Design corridor connections
   - Plan entrance and exit points

### Phase 2: Zone Definition

Create `zone.lua`:

```lua
-- /data/zones/terrain-gallery/zone.lua
return {
  name = "Terrain Gallery",
  level_range = {1, 1},
  level_scheme = "player",
  max_level = 1,
  actor_adjust_level = function(zone, level, e) return zone.base_level + e:getRankLevelAdjust() + level.level-1 + rng.range(-1,2) end,
  width = 80, height = 80,
  persistent = "zone",
  
  generator = {
    map = {
      class = "engine.generator.map.Static",
      map = "zones/terrain-gallery"
    },
    actor = {
      nb_npc = {0, 0}, -- No NPCs
    },
    object = {
      nb_object = {0, 0}, -- No objects
    },
  },
  
  post_process = function(level)
    -- Custom terrain painting logic here
    -- This is where we'll programmatically place all terrain samples
  end,
}
```

### Phase 3: Terrain Painting

In `post_process`, implement the gallery layout:

```lua
post_process = function(level)
  local grids = {
    -- Load grid IDs from category files
    floor = {"FLOOR", "GRASS", "ROAD", ...},
    wall = {"WALL", "ROCK", ...},
    -- etc.
  }
  
  local x, y = 5, 5  -- Starting position
  local display_size = 5  -- 5x5 display per grid
  local spacing = 2
  
  for category, grid_list in pairs(grids) do
    -- Paint category label/header
    -- Paint category section
    for _, grid_id in ipairs(grid_list) do
      -- Paint individual grid sample
      for dy = 0, display_size-1 do
        for dx = 0, display_size-1 do
          level.map(x + dx, y + dy, engine.Map.TERRAIN, level.map:checkEntity(grid_id, "terrain"))
        end
      end
      x = x + display_size + spacing
      if x > level.map.w - display_size then
        x = 5
        y = y + display_size + spacing
      end
    end
  end
end
```

### Phase 4: Grids Definition

Create `grids.lua`:

```lua
-- /data/zones/terrain-gallery/grids.lua

-- Load base terrain definitions
load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")
load("/data/general/grids/water.lua")
-- Load other grid definition files as needed

-- Define any custom grids for the gallery itself (optional)
```

### Phase 5: Testing & Validation

1. **Load the zone** in ToME
2. **Verify display**:
   - All categories visible
   - Terrain samples display correctly
   - No crashes or errors
3. **Test navigation**:
   - Can walk through safe areas
   - Cannot accidentally trigger dangerous terrain
4. **Verify isolation**:
   - Special terrain properly isolated
   - No unexpected transitions

---

## Alternative: Programmatic Gallery Generator

Instead of manual zone creation, create a Python script to generate the zone files:

**Script: `generate_terrain_gallery.py`**

```python
#!/usr/bin/env python3
"""
Generate a ToME terrain gallery zone from the TE4 grid catalog.
"""

import json
from pathlib import Path

def generate_gallery_zone(catalog_path, output_dir):
    # Load catalog
    with open(catalog_path, 'r') as f:
        catalog = json.load(f)
    
    # Load category files
    ids_by_category = {}
    for cat in ['floor', 'wall', 'feature', 'vegetation', 'water', 'lava', 'door', 'special']:
        cat_file = Path(catalog_path).parent / f'te4_grid_ids_by_category/{cat}.txt'
        if cat_file.exists():
            with open(cat_file, 'r') as f:
                ids_by_category[cat] = [line.strip() for line in f if line.strip()]
    
    # Generate zone.lua
    zone_lua = generate_zone_lua(ids_by_category)
    
    # Write files
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    (output_path / 'zone.lua').write_text(zone_lua)
    
    # Generate grids.lua (mostly imports)
    grids_lua = generate_grids_lua()
    (output_path / 'grids.lua').write_text(grids_lua)
    
    print(f"Gallery zone generated in {output_path}")

def generate_zone_lua(ids_by_category):
    # Generate the zone.lua content with post_process logic
    # that paints all terrain samples
    pass

def generate_grids_lua():
    # Generate grids.lua that imports necessary base grids
    return """
-- Load base terrain definitions
load("/data/general/grids/basic.lua")
load("/data/general/grids/forest.lua")
load("/data/general/grids/water.lua")
load("/data/general/grids/lava.lua")
-- Add more loads as needed based on catalog
"""

if __name__ == '__main__':
    generate_gallery_zone('docs/te4_grid_catalog.json', 'mod/terrain-gallery/data/zones/terrain-gallery')
```

---

## Expected Deliverables

1. **Working ToME zone** that displays terrain gallery
2. **Zone files**:
   - `zone.lua` (zone definition with layout logic)
   - `grids.lua` (terrain imports)
   - `npcs.lua` (empty or minimal)
3. **Documentation**:
   - Gallery layout map (ASCII art or image)
   - Usage instructions
   - Known limitations

---

## Success Criteria

✅ Gallery loads without errors  
✅ All 8 categories displayed  
✅ Terrain samples render correctly  
✅ Navigation works (can walk around safely)  
✅ Special terrain properly isolated  
✅ No accidental level/zone transitions  
✅ Gallery serves as useful reference tool  

---

## Advanced Features (Optional)

If time permits and engine supports:

1. **Interactive labels**: Display grid ID names on hover or inspect
2. **Metadata display**: Show category, blocking status, dangerous flag
3. **Search/filter**: Find specific terrain types
4. **Copy/export**: Copy grid ID to clipboard for use in templates
5. **Comparison view**: Display similar terrain side-by-side
6. **Animation test**: For terrain with animations

---

## Known Limitations

- **Static layout**: Gallery must be pre-generated, not dynamic
- **Grid count**: Large number of grids may require very large zone
- **No hover text**: ToME may not support custom tooltip text for terrain
- **Special terrain risks**: Some terrain may still have effects even when isolated

---

## Related Documentation

- **TE4_GRID_SAFETY_ANALYSIS.md**: Safety guidelines for terrain usage
- **TE4_EXTRACTOR_USAGE.md**: How to run the extractor
- **ToME_zone_spec.md**: ToME zone construction patterns

---

## Revision History

- **v1.0** (2026-01-31): Initial gallery prompt
