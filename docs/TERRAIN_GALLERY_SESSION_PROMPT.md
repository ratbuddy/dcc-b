# Terrain Gallery Map - Session Prompt

**Purpose**: Create a comprehensive terrain gallery zone in ToME that displays all available terrain types for visual reference and testing.

---

## Executive Summary

We have:
- ✅ **TE4 grid catalog** with metadata for all terrain types
- ✅ **8 categorized terrain lists** (floor, wall, vegetation, water, lava, door, feature, special)
- ✅ **Safety analysis** documenting which terrain is safe for templates
- ✅ **Pre-filtered safe list** for gallery/showcase work

**Goal**: Build a ToME zone that serves as a visual "museum" displaying all these terrain types in an organized, navigable layout.

---

## Starting Point

Before beginning, ensure you have:

1. **Catalog files** (in `/docs/` after extractor run):
   - `te4_grid_catalog.json` - Complete metadata
   - `te4_grid_ids_by_category/*.txt` - 8 category files
   - `te4_gallery_safe_ids.txt` - Pre-filtered safe list

2. **Documentation**:
   - **TERRAIN_GALLERY_PROMPT.md** - Complete implementation guide (read this first)
   - **TE4_GRID_SAFETY_ANALYSIS.md** - Safety guidelines for each category
   - **ToME_zone_spec.md** - Zone construction patterns

---

## Mission

Create a ToME zone (`terrain-gallery`) that:

1. **Displays** every grid ID from the catalog in an organized layout
2. **Groups** terrain by category with clear visual separation
3. **Provides** easy navigation between categories
4. **Isolates** dangerous terrain (special.txt) to prevent accidents
5. **Serves** as a permanent reference tool for terrain selection

---

## Implementation Approach

### Option A: Programmatic Generator (Recommended)

Create a Python script that:
1. Loads `te4_grid_catalog.json` and category files
2. Calculates layout dimensions based on terrain counts
3. Generates `zone.lua` with category rooms and corridor layout
4. Generates post_process logic to paint all terrain samples
5. Outputs complete zone files ready to load in ToME

**Advantages**: Repeatable, maintainable, scales to any catalog size

### Option B: Manual Zone Creation

1. Design layout (category rooms + corridors)
2. Write `zone.lua` with manual post_process logic
3. Paint terrain samples in grid pattern
4. Test and iterate

**Advantages**: Full control, easier to customize

---

## Layout Strategy

### Recommended: Category Rooms

```
┌──────────────┐
│    ENTRY     │
│   (FLOOR)    │
└──────┬───────┘
       │
   ┌───┴───┐
   │ FLOOR │
   │ ROOM  │
   └───┬───┘
       │
   ┌───┴───┐
   │ WALL  │
   │ ROOM  │
   └───┬───┘
       │
   ┌───┴────┐
   │FEATURE │
   │ ROOM   │
   └───┬────┘
       │
   [continue for all 8 categories]
```

Each category room displays its terrain in a grid pattern:
```
W W W W W W W W
W T T T W T T T W
W T G T W T G T W    G = Grid sample (3x3)
W T T T W T T T W    T = Neutral floor
W W W W W W W W W    W = Wall boundary
```

---

## Safety Requirements

**CRITICAL**:
1. **Isolate special.txt terrain** - Place stairs/portals in sealed room or at the end
2. **Add barriers** - Use impassable walls around dangerous terrain
3. **Safe spawn** - Start player in floor category room (safest area)
4. **Clear exits** - Always provide escape route
5. **Warning signs** - Label dangerous areas if possible

---

## Technical Details

### Zone Configuration

```lua
-- /data/zones/terrain-gallery/zone.lua
return {
  name = "Terrain Gallery",
  short_name = "terrain-gallery",
  level_range = {1, 1},
  max_level = 1,
  width = 100, height = 100,  -- Large enough for all terrain
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  
  generator = {
    map = {
      class = "engine.generator.map.Static",
      -- Use programmatic post_process for layout
    },
  },
  
  post_process = function(level)
    -- Paint category rooms with terrain samples
    -- See TERRAIN_GALLERY_PROMPT.md for complete example
  end,
}
```

### Terrain Display Pattern

For each grid ID to display:
- Center: 3x3 or 5x5 sample of the grid
- Border: Neutral floor (FLOOR)
- Spacing: 2-3 tiles between samples
- Labels: Category headers (if engine supports text)

---

## Category Display Order

Display in order of safety (safest to most dangerous):

1. **Floor** (FLOOR, GRASS, ROAD, etc.) - Start here
2. **Wall** (WALL, ROCK, MOUNTAIN, etc.)
3. **Feature** (ALTAR, STATUE, PILLAR, etc.)
4. **Vegetation** (TREE, BUSH, THICKET, etc.)
5. **Water** (WATER, RIVER, etc.)
6. **Lava** (LAVA variants) ⚠️
7. **Door** (DOOR_CLOSED, DOOR_OPEN, etc.) ⚠️
8. **Special** (STAIRS, PORTAL, etc.) ❌ Isolated at end

---

## Deliverables

### Required Files

1. **zone.lua** - Zone definition with layout logic
2. **grids.lua** - Terrain imports
3. **npcs.lua** - Empty or minimal
4. **objects.lua** - Empty or minimal

### Optional Files

1. **Generator script** - `generate_terrain_gallery.py`
2. **Layout map** - ASCII art or diagram
3. **Usage notes** - How to navigate the gallery

---

## Success Criteria

The gallery is complete when:

- ✅ Zone loads without errors
- ✅ All 8 categories are displayed
- ✅ Terrain samples render correctly
- ✅ Player can navigate safely
- ✅ Special terrain is properly isolated
- ✅ No accidental level/zone transitions occur
- ✅ Gallery serves as useful reference tool

---

## Testing Checklist

Before considering the gallery complete:

- [ ] Load zone in ToME (no crashes)
- [ ] Walk through each category room
- [ ] Verify terrain renders (textures visible)
- [ ] Check special terrain isolation (can't accidentally trigger)
- [ ] Test escape route (can exit gallery)
- [ ] Verify category separation (clear boundaries)
- [ ] Check navigation (can reach all rooms)

---

## Quick Start Command

If using programmatic approach:

```bash
# Generate gallery zone files
python3 generate_terrain_gallery.py \
  --catalog docs/te4_grid_catalog.json \
  --output mod/terrain-gallery/data/zones/terrain-gallery

# Load ToME and test
cd /path/to/tome4
# Load game and use changeLevel to visit terrain-gallery zone
```

---

## Reference Documentation

**Must Read**:
- **TERRAIN_GALLERY_PROMPT.md** - Complete implementation details
- **TE4_GRID_SAFETY_ANALYSIS.md** - Safety guidelines

**Helpful**:
- **ToME_zone_spec.md** - Zone construction patterns
- **TE4_GRID_CATALOG_QUICKREF.md** - Quick category reference
- **TE4_GRID_RESOURCES_INDEX.md** - Documentation navigation

---

## Advanced Features (Optional)

If time permits:
1. Interactive labels on hover/inspect
2. Metadata display for each terrain
3. Search/filter functionality
4. Comparison views for similar terrain
5. Animation testing area

---

## Known Limitations

- Static layout (not dynamically generated at runtime)
- Large catalog requires very large zone
- No custom tooltip text (engine limitation)
- Special terrain may still have effects even when isolated

---

## Next Steps

1. Read **TERRAIN_GALLERY_PROMPT.md** for complete implementation guide
2. Choose implementation approach (programmatic vs manual)
3. Review safety guidelines in **TE4_GRID_SAFETY_ANALYSIS.md**
4. Begin zone creation
5. Test incrementally (start with one category, expand)

---

**Version**: 1.0  
**Last Updated**: 2026-01-31  
**See Also**: TERRAIN_GALLERY_PROMPT.md (full guide)
