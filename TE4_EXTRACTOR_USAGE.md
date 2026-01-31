# TE4 Grid Extractor Usage

## Overview

The `extract_tome_terrain_ids.py` script extracts grid (terrain) definitions from ToME4 (Tales of Maj'Eyal) modules and generates a comprehensive catalog with semantic context and categorization.

## Basic Usage

```bash
python3 extract_tome_terrain_ids.py --root /path/to/tome4 --out te4_grid_catalog.json
```

### Required Arguments

- `--root`: Path to the TE4 repository root (must contain `game/modules/`)

### Optional Arguments

- `--out`: Output JSON filename (default: `te4_grid_catalog.json`)
- `--no-general`: Disable scanning `data/general/grids/**/*.lua`
- `--no-zones`: Disable scanning `data/zones/**/grids.lua`
- `--debug`: Print file counts and sample paths

## Output Files

The extractor generates the following files:

### 1. `te4_grid_catalog.json`

Main catalog file containing:
- `ids`: List of all grid IDs
- `count`: Total number of grid IDs
- `images`: List of all unique image paths
- `image_count`: Total number of unique images
- `meta`: Detailed metadata for each grid ID (see below)
- `counts`: Number of IDs in each category

### 2. `te4_grid_ids_by_category/<category>.txt`

One file per category, each containing grid IDs (one per line):
- `floor.txt`: Passable floor terrains
- `wall.txt`: Blocking walls and obstacles
- `vegetation.txt`: Trees, bushes, thickets
- `water.txt`: Water and rivers
- `lava.txt`: Lava terrain
- `door.txt`: Doors (any state)
- `feature.txt`: Non-blocking decorative features (altars, statues, etc.)
- `special.txt`: Dangerous or special terrains (stairs, portals, etc.)

### 3. `te4_gallery_safe_ids.txt`

Union of safe categories (floor, wall, vegetation, water, lava, feature).
Excludes: special and door categories.

## Extracted Metadata

For each grid ID, the following fields are extracted:

### Basic Fields
- `define_as`: The grid ID
- `base`: Base grid ID (if inherited)
- `image`: Primary image path
- `add_mos_images`: Additional overlay images

### Semantic Fields
- `name`: Display name
- `type`, `subtype`: Grid type classification
- `block_move`: Boolean or number indicating movement blocking
- `block_sight`: Boolean or number indicating sight blocking
- `can_pass`: Conditional passage rules (raw string)

### Presence Flags
These are set to `true` if the field exists in the source:
- `change_level`: Changes dungeon level
- `change_zone`: Changes zone
- `on_stand`: Has standing effect
- `on_move`: Has movement effect
- `door_opened`, `open_door`, `close_door`, `is_door`: Door-related fields

### Derived Flags
- `is_blocking`: `true` if `block_move` is true or 1
- `is_dangerous`: `true` if has change_level/change_zone/on_stand/on_move
- `is_doorish`: `true` if ID contains "DOOR" or has door fields

### Category
Coarse category derived from ID name, type, and behavior:
- **floor**: Non-blocking passable terrain
- **wall**: Blocking obstacles
- **vegetation**: Trees and plants
- **water**: Water terrain
- **lava**: Lava terrain
- **door**: Doors
- **feature**: Non-blocking decorative features
- **special**: Dangerous or level-transition terrain

## Category Derivation Priority

Categories are assigned in this priority order:
1. **door** - if is_doorish
2. **lava** - if ID contains "LAVA"
3. **water** - if ID contains "WATER" or "RIVER"
4. **vegetation** - if ID contains "TREE", "BUSH", or "THICKET"
5. **special** - if dangerous or contains PORTAL/WORMHOLE/STAIRS/etc.
6. **wall** - if blocking or contains WALL/ROCK/MOUNTAIN
7. **feature** - if non-blocking and contains ALTAR/STATUE/PILLAR/HUT/etc.
8. **floor** - if non-blocking floor type or contains GRASS/FLOOR/ROAD/etc.
9. Default: **wall** if blocking, **floor** otherwise

## Examples

### Extract from ToME4 installation
```bash
python3 extract_tome_terrain_ids.py --root /opt/tome4 --out tome_grids.json --debug
```

### Extract only zone grids
```bash
python3 extract_tome_terrain_ids.py --root /opt/tome4 --no-general
```

### Check specific category
```bash
# List all door IDs
cat te4_grid_ids_by_category/door.txt

# Count special grids
wc -l te4_grid_ids_by_category/special.txt
```

## Legacy Script

The `make_gallery_safe_list.py` script is kept for backward compatibility with the old `te4_grid_manifest.json` format. The enhanced extractor now generates `te4_gallery_safe_ids.txt` automatically with better categorization.

---

## Related Documentation

After generating the catalog, see these documents for usage guidance:

### Safety and Usage
- **`docs/TE4_GRID_SAFETY_ANALYSIS.md`**: Comprehensive safety analysis for each terrain category
  - Detailed risk assessment (safe, caution, avoid)
  - Recommended usage patterns
  - Safety checklist for template authors

### Zone Integration
- **`docs/ToME_zone_spec.md`**: Zone construction patterns (Section 12: Terrain Resources)
  - How to use categorized terrain in zone generators
  - Theme-based terrain selection examples
  - Safe terrain selection in post_process

- **`docs/ToME-Integration-Notes.md`**: Integration reference (Section 10: Terrain Resources)
  - Overview of terrain catalog resources
  - Integration with DCCB systems
  - Future enhancements

### Template Development
- **`docs/DCC-Engineering.md`**: Engineering spec (Section 4.1: Terrain Resources)
  - Data loading conventions
  - Terrain resource locations

### Gallery Creation
- **`docs/TERRAIN_GALLERY_PROMPT.md`**: Complete guide for creating a terrain gallery zone
  - Display all terrain types in an organized layout
  - Visual reference and testing ground
  - Implementation approaches and examples

---

## Workflow Summary

1. **Extract**: Run `extract_tome_terrain_ids.py` to generate catalog
2. **Review**: Check `TE4_GRID_SAFETY_ANALYSIS.md` for safety guidelines
3. **Select**: Choose appropriate categories for your zone theme
4. **Integrate**: Use terrain lists in zone generators and post_process
5. **Test**: Create a gallery zone using `TERRAIN_GALLERY_PROMPT.md` if needed
