#!/usr/bin/env python3
"""
Generate comprehensive gallery manifest from extracted terrain data.
Uses the safety-first approach outlined in TERRAIN_TEMPLATE_MAPS_PROMPT.md
"""

import json
from pathlib import Path

def load_category(category_name):
    """Load terrain IDs from a category file."""
    path = Path(f'docs/te4_grid_ids_by_category/{category_name}.txt')
    if not path.exists():
        return []
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]

def load_safe_ids():
    """Load pre-filtered safe IDs."""
    path = Path('docs/te4_gallery_safe_ids.txt')
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]

def generate_manifest():
    """Generate the gallery manifest Lua file."""
    
    # Load categories (safe ones only, as per safety analysis)
    floors = load_category('floor')
    walls = load_category('wall')
    features = load_category('feature')
    vegetation = load_category('vegetation')
    water = load_category('water')
    lava = load_category('lava')
    
    # DCCB custom grids (always include these first)
    dccb_grids = [
        ("FLOOR", "DCCB/Base", "Standard floor"),
        ("WALL", "DCCB/Base", "Standard wall"),
        ("GRASS", "DCCB/Green", "Grass"),
        ("ROAD", "DCCB/Green", "Dirt road"),
        ("TREE", "DCCB/Green", "Tree"),
        ("GRASS_WINTER", "DCCB/Winter", "Snowy ground"),
        ("ROAD_WINTER", "DCCB/Winter", "Icy path"),
        ("TREE_WINTER", "DCCB/Winter", "Snowy tree"),
        ("GRASS_RUINS", "DCCB/Ruins", "Overgrown ground"),
        ("ROAD_RUINS", "DCCB/Ruins", "Ancient path"),
        ("TREE_RUINS", "DCCB/Ruins", "Ruined pillar"),
        ("DCCB_ENTRANCE", "DCCB/Special", "Entrance marker (blacklisted)"),
    ]
    
    # Generate Lua file
    output = []
    output.append("-- /data/dccb/tileset/gallery_manifest.lua")
    output.append("-- Comprehensive ToME terrain manifest for tileset gallery")
    output.append("-- Virtual path: /data-dccb/dccb/tileset/gallery_manifest.lua")
    output.append("--")
    output.append("-- Generated from extracted terrain data (779 total IDs)")
    output.append("-- Uses only SAFE categories: floor, wall, feature, vegetation, water, lava")
    output.append("-- Excludes: door.txt (context-dependent), special.txt (dangerous)")
    output.append("-- Total safe terrains: 372 IDs")
    output.append("")
    output.append("local M = {}")
    output.append("")
    output.append("-- " + "="*76)
    output.append("-- TERRAIN CANDIDATES - COMPREHENSIVE SAFE LIST")
    output.append("-- " + "="*76)
    output.append("-- All IDs extracted from ToME source and categorized by safety")
    output.append("-- See docs/TE4_GRID_SAFETY_ANALYSIS.md for safety guidelines")
    output.append("")
    output.append("M.TERRAIN_CANDIDATES = {")
    output.append("  -- " + "="*74)
    output.append("  -- DCCB CUSTOM TERRAINS (12 terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- DCCB-specific grids for themed surface zones")
    
    for terrain_id, category, desc in dccb_grids:
        output.append(f'  {{id = "{terrain_id}", category = "{category}", description = "{desc}"}},')
    
    output.append("")
    output.append("  -- " + "="*74)
    output.append(f"  -- TOME FLOOR TERRAINS ({len(floors)} terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- Safe passable floor terrain - no blocking, no dangerous effects")
    output.append("  -- From: docs/te4_grid_ids_by_category/floor.txt")
    
    for terrain_id in floors:
        output.append(f'  {{id = "{terrain_id}", category = "ToME/Floor", description = "Floor terrain"}},')
    
    output.append("")
    output.append("  -- " + "="*74)
    output.append(f"  -- TOME WALL TERRAINS ({len(walls)} terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- Safe blocking terrain - predictable obstacles, no dangerous effects")
    output.append("  -- From: docs/te4_grid_ids_by_category/wall.txt")
    
    for terrain_id in walls:
        output.append(f'  {{id = "{terrain_id}", category = "ToME/Wall", description = "Wall terrain"}},')
    
    output.append("")
    output.append("  -- " + "="*74)
    output.append(f"  -- TOME FEATURE TERRAINS ({len(features)} terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- Safe decorative features - non-blocking, no dangerous effects")
    output.append("  -- From: docs/te4_grid_ids_by_category/feature.txt")
    
    for terrain_id in features:
        output.append(f'  {{id = "{terrain_id}", category = "ToME/Feature", description = "Feature terrain"}},')
    
    output.append("")
    output.append("  -- " + "="*74)
    output.append(f"  -- TOME VEGETATION TERRAINS ({len(vegetation)} terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- Safe natural elements - trees, bushes, etc.")
    output.append("  -- From: docs/te4_grid_ids_by_category/vegetation.txt")
    
    for terrain_id in vegetation:
        output.append(f'  {{id = "{terrain_id}", category = "ToME/Vegetation", description = "Vegetation terrain"}},')
    
    output.append("")
    output.append("  -- " + "="*74)
    output.append(f"  -- TOME WATER TERRAINS ({len(water)} terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- Safe water terrain - may have movement penalties but no transitions")
    output.append("  -- From: docs/te4_grid_ids_by_category/water.txt")
    
    for terrain_id in water:
        output.append(f'  {{id = "{terrain_id}", category = "ToME/Water", description = "Water terrain"}},')
    
    output.append("")
    output.append("  -- " + "="*74)
    output.append(f"  -- TOME LAVA TERRAINS ({len(lava)} terrains)")
    output.append("  -- " + "="*74)
    output.append("  -- CAUTION: Lava deals damage - use in hazard zones only")
    output.append("  -- From: docs/te4_grid_ids_by_category/lava.txt")
    
    for terrain_id in lava:
        output.append(f'  {{id = "{terrain_id}", category = "ToME/Lava", description = "Lava terrain (dangerous)"}},')
    
    output.append("}")
    output.append("")
    output.append("-- " + "="*76)
    output.append("-- STATISTICS")
    output.append("-- " + "="*76)
    total = len(dccb_grids) + len(floors) + len(walls) + len(features) + len(vegetation) + len(water) + len(lava)
    output.append(f"-- Total terrains: {total}")
    output.append(f"-- DCCB custom: {len(dccb_grids)}")
    output.append(f"-- ToME floor: {len(floors)}")
    output.append(f"-- ToME wall: {len(walls)}")
    output.append(f"-- ToME feature: {len(features)}")
    output.append(f"-- ToME vegetation: {len(vegetation)}")
    output.append(f"-- ToME water: {len(water)}")
    output.append(f"-- ToME lava: {len(lava)}")
    output.append("--")
    output.append("-- Excluded categories:")
    output.append("--   - door.txt (157 IDs) - context-dependent, may block")
    output.append("--   - special.txt (250 IDs) - dangerous, level transitions")
    output.append("")
    output.append("return M")
    
    return "\n".join(output)

if __name__ == '__main__':
    manifest_lua = generate_manifest()
    output_path = Path('mod/tome_addon_harness/data/dccb/tileset/gallery_manifest.lua')
    output_path.write_text(manifest_lua)
    print(f"Generated gallery manifest: {output_path}")
    print(f"Total terrains: {manifest_lua.count('{id =')}")
