#!/usr/bin/env python3
"""
Extract working terrain IDs from the log to create verified manifest.
Based on user's latest log showing which terrains actually placed.
"""

# From the log, these are the terrains that successfully placed (marked with ✓)
# Extracted from DCCB-Gallery log output

WORKING_TERRAINS = [
    # DCCB/Base (2)
    {"id": "FLOOR", "category": "DCCB/Base", "description": "Standard floor tile"},
    {"id": "WALL", "category": "DCCB/Base", "description": "Standard wall tile"},
    
    # DCCB/Green (3)
    {"id": "GRASS", "category": "DCCB/Green", "description": "Grass terrain"},
    {"id": "ROAD", "category": "DCCB/Green", "description": "Dirt road"},
    {"id": "TREE", "category": "DCCB/Green", "description": "Tree"},
    
    # DCCB/Winter (3)
    {"id": "GRASS_WINTER", "category": "DCCB/Winter", "description": "Snowy grass"},
    {"id": "ROAD_WINTER", "category": "DCCB/Winter", "description": "Icy road"},
    {"id": "TREE_WINTER", "category": "DCCB/Winter", "description": "Winter tree"},
    
    # DCCB/Ruins (2)
    {"id": "GRASS_RUINS", "category": "DCCB/Ruins", "description": "Overgrown ruins ground"},
    {"id": "ROAD_RUINS", "category": "DCCB/Ruins", "description": "Ancient path"},
    # Note: TREE_RUINS likely works but need to confirm from log
    
    # From the log, these ToME terrains loaded tiles successfully:
    # (Based on "Loading tile from tileset" or "Loading tile" messages)
    
    # Bamboo (multiple variants loaded)
    {"id": "BAMBOO_HUT_FLOOR", "category": "ToME/Structures", "description": "Bamboo hut floor"},
    # Many bamboo wall variants loaded - need to identify the base IDs
    
    # Crystal
    {"id": "CRYSTAL_FLOOR", "category": "ToME/Floor", "description": "Crystal floor"},
    
    # Flower
    {"id": "FLOWER", "category": "ToME/Vegetation", "description": "Flower decoration"},
    
    # Lever
    {"id": "LEVER", "category": "ToME/Feature", "description": "Lever"},
    
    # Marble
    {"id": "MARBLE_FLOOR", "category": "ToME/Floor", "description": "Marble floor"},
    
    # Oldstone
    {"id": "OLDSTONE_FLOOR", "category": "ToME/Floor", "description": "Old stone floor"},
    
    # Sand
    {"id": "SANDFLOOR", "category": "ToME/Floor", "description": "Sandy floor"},
    {"id": "SAND", "category": "ToME/Floor", "description": "Sand terrain"},
    
    # Walls
    {"id": "ROCKY_GROUND", "category": "ToME/Wall", "description": "Rocky ground"},
    {"id": "HALF_WALL", "category": "ToME/Wall", "description": "Half wall"},
    
    # Crystal walls/features
    {"id": "CRYSTAL_WALL", "category": "ToME/Wall", "description": "Crystal wall"},
    # Multiple floating rocks loaded
    
    # Glass
    {"id": "GLASSWALL", "category": "ToME/Wall", "description": "Glass wall"},
]

print(f"Found {len(WORKING_TERRAINS)} working terrains from log analysis")
print("\nCategories:")
categories = {}
for t in WORKING_TERRAINS:
    cat = t["category"]
    categories[cat] = categories.get(cat, 0) + 1

for cat, count in sorted(categories.items()):
    print(f"  {cat}: {count}")

print(f"\nTotal: {len(WORKING_TERRAINS)} terrains")
