# DCCB Start Zone - Surface Map Generator

## Overview

This zone implements a procedural surface map generator that creates overworld-style terrain layouts with multiple templates.

## Features

### Terrain Types
- **GRASS**: Passable surface tile (`,` in light green)
- **TREE**: Blocking terrain (T in green)
- **ROAD**: Passable surface tile (`=` in umber)
- **DOWN**: Stair tiles for descent (`>` in white)

### Templates

#### 1. Green Fields (`green_fields`)
- Open grass field with scattered trees
- Tree density: ~12% across the map
- Creates an open, pastoral environment

#### 2. Forest Road (`forest_road`)
- Road cutting across the map (horizontal or diagonal)
- Trees clustered around the road (~22% density on grass)
- Creates a more structured terrain with clear pathways

### Stair Placement
- 2-4 DOWN stairs placed randomly on passable tiles (GRASS or ROAD)
- Minimum distance of 8 tiles between stairs
- Maximum 1000 placement attempts to ensure reasonable distribution

## Generation Process

1. **Template Selection**: Randomly chooses between available templates
2. **Base Fill**: Fills entire map with GRASS tiles
3. **Template Application**: Applies template-specific features (trees, roads)
4. **Stair Placement**: Places 2-4 DOWN stairs with spacing constraints
5. **Logging**: Outputs `[DCCB-Surface] template=<id> stairs=<n>` to log

## Map Size
- Width: 50 tiles
- Height: 50 tiles
- Full overworld traversal space (not a single room)

## Spawn Configuration
- Actors (NPCs): 0
- Objects (items): 0
- Traps: 0

This is a visual proof-of-concept for procedural surface generation and does not include gameplay elements yet.

## TODO
- Replace math.random with `/core/rng.lua` stream per DCC-Engineering policy
- Add more template variations
- Implement actual dungeon connections for DOWN stairs
