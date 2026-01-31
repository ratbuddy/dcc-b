# TE4 Grid List Safety Analysis for Master Area Templates

**Version**: 1.0  
**Date**: 2026-01-31  
**Status**: Authoritative

## Overview

This document analyzes the safety and usability of the TE4 grid extractor output files (located in `/docs/te4_grid_catalog.json` and `/docs/te4_grid_ids_by_category/*.txt`) for use in master area template generation.

## TL;DR: Safety Assessment

✅ **YES** - The category-specific `.txt` files are safe for master area template use with the following guidelines:

- **SAFE for templates**: `floor.txt`, `wall.txt`, `vegetation.txt`, `water.txt`, `lava.txt`, `feature.txt`
- **USE WITH CAUTION**: `door.txt` (requires context, may block when closed)
- **AVOID in generic templates**: `special.txt` (contains dangerous/transition grids)

The `te4_gallery_safe_ids.txt` file is specifically curated for gallery/showcase purposes and is the safest option for template work.

---

## Detailed Category Safety Analysis

### 1. **floor.txt** ✅ SAFE
**Category**: Passable floor terrain  
**Safety**: **VERY SAFE**

- Contains non-blocking floor terrain (FLOOR, GRASS, ROAD, SAND, etc.)
- No movement restrictions
- No dangerous side effects
- No level/zone transitions
- **Use case**: Primary walkable surface for rooms, corridors, outdoor areas

**Risks**: None for template use

---

### 2. **wall.txt** ✅ SAFE
**Category**: Blocking walls and obstacles  
**Safety**: **VERY SAFE**

- Contains blocking terrain (WALL, ROCK, MOUNTAIN, TREE_WALL, etc.)
- Predictable blocking behavior
- No dangerous side effects
- No level/zone transitions
- **Use case**: Perimeter walls, obstacles, room dividers

**Risks**: None for template use. Note that some walls may have `can_pass` conditions (e.g., ethereal passage), but this is intentional game behavior.

---

### 3. **vegetation.txt** ✅ SAFE
**Category**: Trees, bushes, thickets  
**Safety**: **SAFE**

- Contains natural vegetation (TREE, BUSH, THICKET variants)
- Most block movement (trees), some don't (grass under trees)
- No dangerous side effects
- No level/zone transitions
- **Use case**: Forest theming, outdoor decoration, natural barriers

**Risks**: Minimal. Some vegetation may block line of sight. Verify specific IDs for intended behavior.

---

### 4. **water.txt** ✅ SAFE
**Category**: Water and rivers  
**Safety**: **SAFE**

- Contains water terrain (WATER, RIVER, DEEP_WATER, SHALLOW_WATER, etc.)
- Generally passable but may have movement penalties
- Some may have drowning effects (check metadata)
- No level/zone transitions
- **Use case**: Lakes, rivers, water features

**Risks**: LOW. Some water types may damage non-swimming actors. Check `is_dangerous` flag in catalog for specific IDs if using for player-accessible areas.

---

### 5. **lava.txt** ⚠️ USE WITH CARE
**Category**: Lava terrain  
**Safety**: **MODERATE**

- Contains lava terrain (LAVA, LAVA_FLOOR, etc.)
- Passable but deals damage (`on_stand` effects)
- **Marked as dangerous** in catalog metadata
- No level/zone transitions
- **Use case**: Volcanic theming, hazard zones, challenge areas

**Risks**: MODERATE. Lava deals damage to actors standing on it. Only use in areas where hazards are expected. Check `is_dangerous: true` in metadata.

---

### 6. **feature.txt** ✅ SAFE
**Category**: Non-blocking decorative features  
**Safety**: **VERY SAFE**

- Contains decorative features (ALTAR, STATUE, PILLAR, FOUNTAIN, BRAZIER, etc.)
- Non-blocking (passable)
- No dangerous side effects
- No level/zone transitions
- **Use case**: Visual decoration, thematic elements, points of interest

**Risks**: None for template use. Features add visual interest without gameplay impact.

---

### 7. **door.txt** ⚠️ USE WITH CONTEXT
**Category**: Doors (all states)  
**Safety**: **CONTEXT-DEPENDENT**

- Contains door terrain (DOOR_CLOSED, DOOR_OPEN, DOOR_LOCKED, etc.)
- Blocking when closed, passable when open
- Has interactive behavior (open/close mechanics)
- No dangerous side effects
- No level/zone transitions
- **Use case**: Room entrances, building interiors, controlled access

**Risks**: MODERATE. Closed doors block movement and may confuse AI. Locked doors require keys. Use with understanding of door state and context. Consider placing in open state for templates or ensure proper door logic.

---

### 8. **special.txt** ❌ AVOID IN GENERIC TEMPLATES
**Category**: Dangerous or special terrain  
**Safety**: **DANGEROUS**

- Contains level-transition terrain (STAIRS_UP, STAIRS_DOWN, UP_*, DOWN_*)
- Contains zone-transition terrain (PORTAL, WORMHOLE, ZONE_ENTRY, ZONE_EXIT)
- Contains terrain with `on_stand` or `on_move` effects
- Contains terrain with `change_level` or `change_zone` properties
- **Use case**: Intentional level transitions, quest triggers, special mechanics

**Risks**: HIGH. These grids can:
- Teleport actors to different levels/zones
- Trigger unexpected events
- Break area isolation
- Cause navigation issues

**DO NOT USE** in generic templates unless you specifically intend level/zone transitions.

---

## Recommended Usage Patterns

### Pattern 1: Gallery/Showcase Maps
**Use**: `te4_gallery_safe_ids.txt`

This pre-filtered list excludes `special.txt` and `door.txt`, containing only:
- floor + wall + vegetation + water + lava + feature

Best for: Visual galleries, tile showcases, safe testing environments.

### Pattern 2: Generic Room/Area Templates
**Use**: `floor.txt` + `wall.txt` + `feature.txt`

Safe, predictable terrain for:
- Room generation
- Corridor generation
- Basic area templates

### Pattern 3: Outdoor/Natural Templates
**Use**: `floor.txt` + `vegetation.txt` + `water.txt` + `feature.txt` + selective `wall.txt`

For: Forest areas, outdoor zones, natural environments.

### Pattern 4: Hazardous/Challenge Templates
**Use**: Pattern 2 + selective `lava.txt`

For: Volcanic zones, challenge areas where hazards are intentional.

### Pattern 5: Building/Dungeon Templates
**Use**: `floor.txt` + `wall.txt` + `door.txt` (DOOR_OPEN only) + `feature.txt`

For: Building interiors, dungeon rooms with controlled access.

---

## Safety Checklist for Template Authors

Before using a grid ID in a template, verify:

1. ✅ **Category**: Is it in a safe category for your use case?
2. ✅ **Blocking**: Does `is_blocking` match your intent? (Check catalog)
3. ✅ **Dangerous**: Is `is_dangerous: false`? (Check catalog)
4. ✅ **Transitions**: Does it have `change_level` or `change_zone`? (Avoid unless intentional)
5. ✅ **Effects**: Does it have `on_stand` or `on_move`? (Avoid unless intentional)
6. ✅ **Context**: Is it appropriate for the template's purpose?

---

## Accessing the Grid Catalog Metadata

For detailed metadata about any grid ID:

```python
import json

# Load the catalog
with open('docs/te4_grid_catalog.json', 'r') as f:
    catalog = json.load(f)

# Check a specific grid ID
grid_id = "FLOOR"
meta = catalog['meta'][grid_id]

print(f"Category: {meta['category']}")
print(f"Blocking: {meta['is_blocking']}")
print(f"Dangerous: {meta['is_dangerous']}")
print(f"Name: {meta['name']}")
```

---

## Related Documentation

- **TE4_EXTRACTOR_USAGE.md**: How to run the extractor and understand output format
- **TERRAIN_GALLERY_PROMPT.md**: Prompt for creating a comprehensive terrain gallery map
- **ToME_zone_spec.md**: Zone construction patterns for ToME (updated with grid references)

---

## Revision History

- **v1.0** (2026-01-31): Initial safety analysis for extractor output
