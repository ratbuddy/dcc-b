# DCCB Start Zone - Surface Map Generator

## Overview

This zone implements a procedural surface map generator that creates overworld-style terrain layouts with multiple templates. **This is a single-level zone with no intra-zone transitions.**

## Features

### Terrain Types
- **GRASS**: Passable surface tile (`,` in light green)
- **TREE**: Blocking terrain (`T` in green)
- **ROAD**: Passable surface tile (`=` in umber)
- **DCCB_ENTRANCE**: Visual dungeon entrance marker (`>` in yellow) - does NOT cause level transitions

### Templates

#### 1. Green Fields (`green_fields`)
- Open grass field with scattered trees
- Tree density: ~12% across the map
- Safe clearing maintained around map center
- Creates an open, pastoral environment

#### 2. Forest Road (`forest_road`)
- Road cutting across the map (horizontal or diagonal)
- Trees clustered around the road (~20% density on grass)
- Safe margins around map edges
- Creates a more structured terrain with clear pathways

### Entrance Placement
- 2-4 DCCB_ENTRANCE markers placed randomly on passable tiles (GRASS or ROAD)
- Minimum Manhattan distance of 8 tiles between entrances
- Maximum 1000 placement attempts to ensure reasonable distribution
- **These are visual markers only** - they do not trigger zone transitions yet
- Standing on an entrance shows: "[DCCB] Dungeon entrance not implemented yet"

## Generation Process

1. **Base Fill**: Uses `engine.generator.map.Filled` to fill entire map with GRASS tiles
2. **Template Selection**: Randomly chooses between available templates
3. **Template Application**: Applies template-specific features (trees, roads) via `post_process` hook
4. **Entrance Placement**: Places 2-4 DCCB_ENTRANCE markers with spacing constraints
5. **Logging**: Outputs `[DCCB-Surface] template=<id> entrances=<n>` to log

## Map Size
- Width: 50 tiles
- Height: 50 tiles
- Full overworld traversal space (not a single room)
- Single level only (max_level=1, no_level_connectivity=true)

## Spawn Configuration
- Actors (NPCs): 0
- Objects (items): 0
- Traps: 0

This is a visual proof-of-concept for procedural surface generation and does not include gameplay elements yet.

## Implementation Notes

- Uses `engine.generator.map.Filled` instead of Roomer to avoid generating dungeon rooms
- Template application happens in `post_process` hook, not during initial generation
- DCCB_ENTRANCE terrain has NO `change_level` or `change_zone` properties
- Safe clearing areas ensure the player spawn and entrances don't get blocked by trees

## TODO
- Replace math.random with `/core/rng.lua` stream per DCC-Engineering policy
- Add more template variations
- Implement actual dungeon connections for DCCB_ENTRANCE markers
