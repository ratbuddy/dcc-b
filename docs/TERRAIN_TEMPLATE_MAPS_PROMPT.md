# Terrain Master/Template Maps - Session Prompt

**Version**: 1.0  
**Date**: 2026-01-31  
**Purpose**: Create reusable master/template maps using categorized terrain data for procedural generation

---

## Executive Summary

We have **complete terrain data** (10/10 files, 779 terrain IDs):
- ✅ **te4_grid_catalog.json** - Complete metadata (695 KB, all 779 IDs with semantic context)
- ✅ **8 categorized terrain lists** - Organized by safety and usage (floor, wall, vegetation, water, lava, door, feature, special)
- ✅ **Safety analysis** - Detailed risk assessment for each category
- ✅ **Pre-filtered safe list** - 372 safe IDs for template work

**Goal**: Create master terrain templates that can be safely reused across zones with validated, categorized terrain selections.

---

## Mission

Create reusable terrain templates/patterns that:

1. **Use validated terrain** from categorized lists (safe by design)
2. **Provide theme variations** (forest, dungeon, volcanic, water, etc.)
3. **Include safety guarantees** (no accidental level transitions or dangerous effects)
4. **Support procedural generation** (templates can be instantiated with variation)
5. **Document terrain choices** (why each terrain ID was selected for each template)

---

## Available Resources

### Complete Data Set (All 10 Files Present)

**Main Catalog** (`docs/te4_grid_catalog.json`):
```json
{
  "ids": [...779 IDs...],
  "count": 779,
  "images": [...image paths...],
  "meta": {
    "FLOOR": {
      "name": "floor",
      "type": "floor",
      "block_move": false,
      "is_blocking": false,
      "is_dangerous": false,
      "is_doorish": false,
      "category": "floor",
      ...
    }
  },
  "counts": {
    "floor": 136,
    "wall": 168,
    "feature": 4,
    "vegetation": 19,
    "water": 35,
    "lava": 10,
    "door": 157,
    "special": 250
  }
}
```

**Category Lists** (`docs/te4_grid_ids_by_category/*.txt`):
- `floor.txt` - 136 safe passable terrain IDs
- `wall.txt` - 168 safe blocking terrain IDs
- `feature.txt` - 4 decorative feature IDs
- `vegetation.txt` - 19 natural elements
- `water.txt` - 35 water terrain IDs
- `lava.txt` - 10 lava terrain IDs (dangerous)
- `door.txt` - 157 door variants (context-dependent)
- `special.txt` - 250 special/dangerous IDs (use with extreme caution)

**Pre-Filtered Safe List** (`docs/te4_gallery_safe_ids.txt`):
- 372 IDs that are safe for general template use
- Excludes: special.txt (level transitions) and door.txt (state-dependent)
- Includes: floor + wall + feature + vegetation + water + lava

### Documentation References

- **TE4_GRID_SAFETY_ANALYSIS.md** - Detailed safety guidelines per category
- **TE4_GRID_CATALOG_QUICKREF.md** - Quick lookup table
- **ToME_zone_spec.md** (Section 12) - Terrain usage in zones
- **ToME-Integration-Notes.md** (Section 10) - Integration patterns

---

## Template Categories to Create

### 1. Room Templates

**Purpose**: Reusable room layouts with validated terrain

**Types to Create**:
- **Basic Room** (10x10, simple floor + walls)
- **Decorated Room** (with features: altars, statues, pillars)
- **Storage Room** (minimal, functional)
- **Treasure Room** (decorative, safe)
- **Boss Room** (large, decorative)

**Terrain Selection**:
- Floor: From `floor.txt` (safe, non-blocking)
- Walls: From `wall.txt` (blocking, no special effects)
- Features: From `feature.txt` (decorative, non-blocking)

### 2. Corridor Templates

**Purpose**: Connecting passages between rooms

**Types to Create**:
- **Straight Corridor** (1-3 tiles wide)
- **L-Shaped Corridor**
- **T-Junction**
- **Cross Junction**
- **Decorated Corridor** (with features along sides)

**Terrain Selection**:
- Floor: FLOOR, STONE_FLOOR, DIRT (from floor.txt)
- Walls: WALL, STONE_WALL (from wall.txt)

### 3. Themed Templates

**Forest Theme**:
- Floor: GRASS, DIRT, FOREST_FLOOR (from floor.txt)
- Walls: TREE, TREE_WALL (from vegetation.txt/wall.txt)
- Features: BUSH, TREE (from vegetation.txt)
- Water: Optional SHALLOW_WATER (from water.txt)

**Dungeon Theme**:
- Floor: FLOOR, STONE_FLOOR, COBBLESTONES (from floor.txt)
- Walls: WALL, STONE_WALL, HARDWALL (from wall.txt)
- Features: ALTAR, STATUE, PILLAR (from feature.txt)

**Volcanic Theme**:
- Floor: VOLCANIC_FLOOR, STONE_FLOOR (from floor.txt)
- Walls: VOLCANIC_WALL, HARDWALL (from wall.txt)
- Features: Use sparingly
- Hazards: LAVA (from lava.txt) - use with barriers

**Water Theme**:
- Floor: SAND, SHALLOW_WATER (from floor.txt/water.txt)
- Walls: ROCK, MOUNTAIN (from wall.txt)
- Features: Coastal/aquatic elements
- Water: WATER, DEEP_WATER (from water.txt)

### 4. Special Purpose Templates

**Safe Testing Ground**:
- Use only floor.txt + wall.txt + feature.txt
- Guaranteed no dangerous effects
- Ideal for player starting areas

**Challenge Area**:
- Can include lava.txt (with proper barriers)
- Clear warnings/visual indicators
- No accidental instant-death

**Transition Area** (Advanced):
- May use special.txt for stairs/portals
- Must be clearly marked
- Isolated from main exploration areas

---

## Template Format

Each template should include:

### Template Metadata

```lua
-- template_name.lua
return {
  name = "Basic Room",
  theme = "dungeon",
  size = {width = 10, height = 10},
  safety_level = "safe", -- safe, caution, dangerous
  
  -- Terrain sources (IDs from category files)
  terrain = {
    floor = {"FLOOR", "STONE_FLOOR"},      -- from floor.txt
    wall = {"WALL", "STONE_WALL"},         -- from wall.txt
    feature = {"ALTAR", "STATUE"},         -- from feature.txt (optional)
  },
  
  -- Safety guarantees
  guarantees = {
    no_level_transitions = true,
    no_dangerous_effects = true,
    all_blocking_predictable = true,
  },
  
  -- Usage notes
  notes = [[
    Safe for any zone. All terrain validated from safe categories.
    No special.txt IDs used. No on_stand/on_move effects.
  ]],
}
```

### Template Layout

Option A: ASCII Grid (for visualization):
```
##########
#........#
#.A....S.#
#........#
#........#
#........#
#........#
#.P....F.#
#........#
##########

Legend:
# = WALL (blocking)
. = FLOOR (passable)
A = ALTAR (feature, non-blocking)
S = STATUE (feature, non-blocking)
P = PILLAR (feature, non-blocking)
F = FOUNTAIN (feature, non-blocking)
```

Option B: Programmatic (for generation):
```lua
function generate_basic_room(width, height, theme)
  local template = {}
  local catalog = load_catalog("docs/te4_grid_catalog.json")
  local floors = load_category("docs/te4_grid_ids_by_category/floor.txt")
  local walls = load_category("docs/te4_grid_ids_by_category/wall.txt")
  
  -- Validate all terrain is safe
  for _, id in ipairs(floors) do
    assert(not catalog.meta[id].is_dangerous, "Floor terrain must be safe")
    assert(not catalog.meta[id].is_blocking, "Floor must be passable")
  end
  
  -- Generate grid
  for y = 1, height do
    for x = 1, width do
      if x == 1 or x == width or y == 1 or y == height then
        template[y][x] = choose_random(walls)
      else
        template[y][x] = choose_random(floors)
      end
    end
  end
  
  return template
end
```

---

## Safety-First Approach

### Terrain Selection Workflow

For each template, follow this validation process:

**Step 1: Choose Category**
```python
import json

# Load catalog
with open('docs/te4_grid_catalog.json', 'r') as f:
    catalog = json.load(f)

# Choose category based on need
need_floor = True  # passable terrain
need_wall = True   # blocking terrain
need_features = False  # decorative
```

**Step 2: Filter by Safety**
```python
# Get safe floors (non-blocking, non-dangerous)
safe_floors = [
    id for id, meta in catalog['meta'].items()
    if meta['category'] == 'floor'
    and not meta['is_blocking']
    and not meta['is_dangerous']
]

# Get reliable walls (blocking, non-dangerous)
safe_walls = [
    id for id, meta in catalog['meta'].items()
    if meta['category'] == 'wall'
    and meta['is_blocking']
    and not meta['is_dangerous']
]
```

**Step 3: Theme Filtering**
```python
# Filter by theme keywords
dungeon_floors = [
    id for id in safe_floors
    if any(kw in id for kw in ['FLOOR', 'STONE', 'COBBLE'])
]

forest_floors = [
    id for id in safe_floors
    if any(kw in id for kw in ['GRASS', 'DIRT', 'FOREST'])
]
```

**Step 4: Validate Selection**
```python
# Final validation before use
def validate_terrain_selection(terrain_ids, catalog):
    for tid in terrain_ids:
        meta = catalog['meta'][tid]
        
        # Check for dangerous behaviors
        assert not meta.get('change_level'), f"{tid} changes level!"
        assert not meta.get('change_zone'), f"{tid} changes zone!"
        assert not meta.get('is_dangerous'), f"{tid} is dangerous!"
        
        # Verify expected category
        assert meta['category'] in ['floor', 'wall', 'feature', 'vegetation', 'water'], \
            f"{tid} is in unexpected category: {meta['category']}"
    
    return True
```

---

## Template Generation Script

Create `generate_terrain_templates.py`:

```python
#!/usr/bin/env python3
"""
Generate master terrain templates from TE4 grid catalog.
"""

import json
from pathlib import Path
from collections import defaultdict

def load_catalog():
    """Load the complete terrain catalog."""
    with open('docs/te4_grid_catalog.json', 'r') as f:
        return json.load(f)

def load_category(category_name):
    """Load terrain IDs from a category file."""
    path = Path(f'docs/te4_grid_ids_by_category/{category_name}.txt')
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]

def filter_by_theme(ids, catalog, theme_keywords):
    """Filter terrain IDs by theme keywords."""
    return [
        tid for tid in ids
        if any(kw.upper() in tid.upper() for kw in theme_keywords)
    ]

def generate_room_template(name, theme, floor_ids, wall_ids, feature_ids=None):
    """Generate a room template with validated terrain."""
    template = {
        'name': name,
        'theme': theme,
        'terrain': {
            'floor': floor_ids[:3],  # Use top 3 for variation
            'wall': wall_ids[:2],
            'feature': feature_ids[:2] if feature_ids else [],
        },
        'layout': {
            'type': 'rectangular',
            'min_size': (8, 8),
            'max_size': (15, 15),
        }
    }
    return template

def main():
    catalog = load_catalog()
    
    # Load categories
    floors = load_category('floor')
    walls = load_category('wall')
    features = load_category('feature')
    
    templates = []
    
    # Dungeon theme
    dungeon_floors = filter_by_theme(floors, catalog, ['FLOOR', 'STONE', 'COBBLE'])
    dungeon_walls = filter_by_theme(walls, catalog, ['WALL', 'STONE', 'HARD'])
    templates.append(generate_room_template(
        'Basic Dungeon Room', 'dungeon',
        dungeon_floors, dungeon_walls, features
    ))
    
    # Forest theme
    forest_floors = filter_by_theme(floors, catalog, ['GRASS', 'DIRT', 'FOREST'])
    forest_walls = filter_by_theme(walls, catalog, ['TREE', 'ROCK'])
    templates.append(generate_room_template(
        'Forest Clearing', 'forest',
        forest_floors, forest_walls
    ))
    
    # Output templates
    output = {
        'templates': templates,
        'catalog_version': '1.0',
        'total_templates': len(templates),
    }
    
    Path('terrain_templates.json').write_text(json.dumps(output, indent=2))
    print(f"Generated {len(templates)} templates")

if __name__ == '__main__':
    main()
```

---

## Usage in Zone Generation

### Integrating Templates with ToME

```lua
-- In zone.lua post_process
post_process = function(level)
  local Map = require "engine.Map"
  local templates = load_terrain_templates("terrain_templates.json")
  
  -- Select template by theme
  local template = templates['Basic Dungeon Room']
  
  -- Instantiate at position
  local start_x, start_y = 10, 10
  for dy = 0, template.height - 1 do
    for dx = 0, template.width - 1 do
      local terrain_id = template.grid[dy + 1][dx + 1]
      local g = zone:makeEntityByName(level, "grid", terrain_id)
      if g and g.resolve then g:resolve() end
      level.map(start_x + dx, start_y + dy, Map.TERRAIN, g)
    end
  end
end
```

---

## Template Library Structure

Organize templates in a library:

```
terrain_templates/
├── README.md                    # Overview and usage
├── rooms/
│   ├── basic_room.lua          # Simple rectangular room
│   ├── decorated_room.lua      # Room with features
│   ├── treasure_room.lua       # Valuable items room
│   └── boss_room.lua           # Large encounter room
├── corridors/
│   ├── straight.lua            # Straight corridor
│   ├── l_shaped.lua            # L-shaped turn
│   └── junction.lua            # T or cross junction
├── themed/
│   ├── forest_clearing.lua     # Natural outdoor area
│   ├── dungeon_chamber.lua     # Stone dungeon room
│   ├── volcanic_cave.lua       # Lava-themed area
│   └── water_grotto.lua        # Aquatic area
└── special/
    ├── safe_spawn.lua          # Starting area (no dangers)
    └── challenge_arena.lua     # Combat encounter area
```

---

## Testing Templates

### Validation Checklist

For each template:

- [ ] All terrain IDs exist in catalog
- [ ] All terrain is from appropriate categories
- [ ] No terrain has `is_dangerous: true` (unless intended)
- [ ] No terrain has `change_level` or `change_zone` (unless intended)
- [ ] Blocking terrain is where expected (walls)
- [ ] Non-blocking terrain is where expected (floors)
- [ ] Theme consistency (all IDs match theme keywords)
- [ ] Layout is sensible (rooms enclosed, corridors connect)
- [ ] Features don't block required paths

### Testing Script

```python
def test_template(template, catalog):
    """Validate a template against the catalog."""
    errors = []
    
    for terrain_type, ids in template['terrain'].items():
        for tid in ids:
            if tid not in catalog['meta']:
                errors.append(f"Unknown terrain ID: {tid}")
                continue
            
            meta = catalog['meta'][tid]
            
            # Check safety for general templates
            if template['safety_level'] == 'safe':
                if meta['is_dangerous']:
                    errors.append(f"{tid} is dangerous in 'safe' template")
                if meta.get('change_level'):
                    errors.append(f"{tid} changes level in 'safe' template")
    
    return len(errors) == 0, errors
```

---

## Deliverables

### Phase 1: Core Templates (Immediate)

1. **5 Basic Room Templates**
   - Basic room (dungeon theme)
   - Forest clearing
   - Volcanic chamber
   - Water grotto
   - Safe spawn room

2. **3 Corridor Templates**
   - Straight corridor
   - L-shaped corridor
   - Junction

3. **Validation Script**
   - Python script to validate all templates
   - Check safety constraints
   - Verify terrain IDs exist

### Phase 2: Template Library (Extended)

4. **Theme Variations**
   - 3-5 templates per theme
   - Dungeon, forest, volcanic, water, ice, cave

5. **Special Purpose**
   - Boss rooms
   - Treasure rooms
   - Challenge arenas

6. **Documentation**
   - Usage guide for each template
   - Integration examples
   - Customization patterns

---

## Success Criteria

Templates are complete when:

- ✅ All terrain IDs validated against catalog
- ✅ No dangerous terrain in "safe" templates
- ✅ Theme consistency verified
- ✅ Layouts tested (rooms are enclosed, corridors connect)
- ✅ Documentation complete for each template
- ✅ Templates successfully instantiated in ToME zones
- ✅ No runtime errors when using templates

---

## Key Differences from Gallery

**Gallery** (visual reference):
- Displays ALL terrain types
- Shows examples of each category
- Includes dangerous terrain (isolated)
- Goal: Visual catalog

**Templates** (reusable patterns):
- Uses SELECTED safe terrain
- Focuses on practical layouts
- Excludes most dangerous terrain
- Goal: Reusable zone components

---

## Quick Start Commands

```bash
# 1. Verify data files present
bash verify_extractor_output.sh

# 2. Load catalog and explore
python3 -c "
import json
catalog = json.load(open('docs/te4_grid_catalog.json'))
print(f'Total IDs: {catalog[\"count\"]}')
print(f'Categories: {catalog[\"counts\"]}')
"

# 3. Start template generation
python3 generate_terrain_templates.py

# 4. Validate templates
python3 validate_templates.py
```

---

## Related Documentation

- **TERRAIN_GALLERY_SESSION_PROMPT.md** - Gallery creation (different from templates)
- **TE4_GRID_SAFETY_ANALYSIS.md** - Safety guidelines per category
- **TE4_GRID_CATALOG_QUICKREF.md** - Quick reference
- **ToME_zone_spec.md** - Zone construction patterns

---

**Last Updated**: 2026-01-31  
**Status**: Ready for implementation with complete catalog (10/10 files)
