#!/usr/bin/env python3
"""
ToME Terrain ID Extraction Script
==================================

This script crawls a local clone of the official ToME repository and extracts
terrain/grid IDs, object IDs, and define_as IDs referenced by official zone content.

Usage:
------
    python extract_tome_terrain_ids.py --root /path/to/t-engine4
    python extract_tome_terrain_ids.py --root /path/to/t-engine4 --include-general
    python extract_tome_terrain_ids.py --root /path/to/t-engine4 --out my_output.json

Arguments:
    --root PATH           Path to local ToME repository root (required)
    --include-general     Also scan game/modules/tome/data/general/** (optional)
    --out FILENAME        Output JSON filename (default: tome_used_terrain_manifest.json)

Output Format:
--------------
The script generates a JSON file with the following structure:
{
    "terrain_ids": [...sorted unique terrain IDs...],
    "object_ids": [...sorted unique object IDs...],
    "define_as_ids": [...sorted unique define_as IDs...],
    "sources": {
        "ID": ["relative/path:line", ...],  // max 10 sources per ID
        ...
    }
}

Integration with DCCB:
---------------------
The generated manifest can be used to populate the DCCB tileset gallery by:
1. Running this script against your ToME installation
2. Using the terrain_ids list to generate preview images
3. Mapping IDs to their visual assets in the tileset
4. Creating gallery entries for all official terrain types

This ensures the DCCB gallery includes all terrain types used in official ToME zones.

Extraction Strategy:
-------------------
Uses regex patterns to extract:
1. makeEntityByName(..., "terrain", "<ID>")
2. makeEntityByName(..., "object", "<ID>")
3. define_as = "<ID>"

The script avoids complex Lua parsing to remain lightweight and dependency-free.
"""

import re
import os
import sys
import json
import argparse
from collections import defaultdict
from pathlib import Path


# Regex patterns for extraction
# Note: ToME IDs typically follow the pattern: starts with letter or underscore,
# followed by letters, digits, or underscores (e.g., FLOOR, WALL_GRANITE, GRASS_01)
# The re.IGNORECASE flag allows matching IDs in any case, and we normalize to uppercase
# with .upper() to ensure consistency

# Pattern 1: makeEntityByName(..., "terrain", "ID")
TERRAIN_PATTERN = re.compile(
    r'makeEntityByName\s*\([^,]*,\s*["\']terrain["\']\s*,\s*["\']([A-Z_][A-Z0-9_]*)["\']',
    re.IGNORECASE
)

# Pattern 2: makeEntityByName(..., "object", "ID")
OBJECT_PATTERN = re.compile(
    r'makeEntityByName\s*\([^,]*,\s*["\']object["\']\s*,\s*["\']([A-Z_][A-Z0-9_]*)["\']',
    re.IGNORECASE
)

# Pattern 3: define_as = "ID"
DEFINE_AS_PATTERN = re.compile(
    r'define_as\s*=\s*["\']([A-Z_][A-Z0-9_]*)["\']',
    re.IGNORECASE
)

# Maximum number of source references to keep per ID
MAX_SOURCES_PER_ID = 10


def find_lua_files(root_path, include_general=False):
    """
    Find all .lua files in the zones directory and optionally general directory.
    
    Args:
        root_path: Path to ToME repository root
        include_general: Whether to include general/** directory
    
    Returns:
        List of Path objects for .lua files
    """
    lua_files = []
    
    # Always scan zones directory
    zones_path = root_path / "game" / "modules" / "tome" / "data" / "zones"
    if zones_path.exists():
        lua_files.extend(zones_path.rglob("*.lua"))
    
    # Optionally scan general directory
    if include_general:
        general_path = root_path / "game" / "modules" / "tome" / "data" / "general"
        if general_path.exists():
            lua_files.extend(general_path.rglob("*.lua"))
    
    return lua_files


def extract_ids_from_file(file_path, root_path):
    """
    Extract terrain IDs, object IDs, and define_as IDs from a Lua file.
    
    Args:
        file_path: Path to the Lua file
        root_path: Root path for computing relative paths
    
    Returns:
        Tuple of (terrain_dict, object_dict, define_as_dict) where each dict
        maps ID -> list of "relative/path:line" strings
    """
    terrain_matches = defaultdict(list)
    object_matches = defaultdict(list)
    define_as_matches = defaultdict(list)
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        try:
            relative_path = file_path.relative_to(root_path)
        except ValueError:
            # Fallback if file_path is not under root_path (e.g., symlinks)
            relative_path = file_path
        
        for line_num, line in enumerate(lines, start=1):
            # Skip lines that are pure comments (start with -- after whitespace)
            stripped = line.lstrip()
            if stripped.startswith('--'):
                continue
            
            # Remove inline comments to avoid extracting IDs from comments
            # Note: This is a simple approach that doesn't handle -- inside string literals
            # This is acceptable per the problem statement's "avoid insane false positives"
            # requirement, which doesn't mandate perfect Lua parsing
            code_part = line.split('--')[0] if '--' in line else line
            
            # Extract terrain IDs
            for match in TERRAIN_PATTERN.finditer(code_part):
                terrain_id = match.group(1).upper()
                source = f"{relative_path}:{line_num}"
                terrain_matches[terrain_id].append(source)
            
            # Extract object IDs
            for match in OBJECT_PATTERN.finditer(code_part):
                object_id = match.group(1).upper()
                source = f"{relative_path}:{line_num}"
                object_matches[object_id].append(source)
            
            # Extract define_as IDs
            for match in DEFINE_AS_PATTERN.finditer(code_part):
                define_as_id = match.group(1).upper()
                source = f"{relative_path}:{line_num}"
                define_as_matches[define_as_id].append(source)
    
    except Exception as e:
        print(f"Warning: Error reading {file_path}: {e}", file=sys.stderr)
    
    return terrain_matches, object_matches, define_as_matches


def merge_sources(all_sources):
    """
    Merge source dictionaries and limit to MAX_SOURCES_PER_ID per ID.
    
    Args:
        all_sources: Dict mapping ID -> list of sources
    
    Returns:
        Dict with sources limited to MAX_SOURCES_PER_ID per ID
    """
    merged = defaultdict(list)
    
    for id_key, sources in all_sources.items():
        # Remove duplicates while preserving order
        unique_sources = []
        seen = set()
        for source in sources:
            if source not in seen:
                unique_sources.append(source)
                seen.add(source)
                if len(unique_sources) >= MAX_SOURCES_PER_ID:
                    break
        
        merged[id_key] = unique_sources
    
    return dict(merged)


def extract_all_ids(root_path, include_general=False):
    """
    Extract all IDs from ToME repository.
    
    Args:
        root_path: Path to ToME repository root
        include_general: Whether to include general/** directory
    
    Returns:
        Dict with terrain_ids, object_ids, define_as_ids, and sources
    """
    print(f"Scanning ToME repository at: {root_path}")
    if include_general:
        print("Including general/** directory")
    
    lua_files = find_lua_files(root_path, include_general)
    print(f"Found {len(lua_files)} .lua files to process")
    
    all_terrain = defaultdict(list)
    all_objects = defaultdict(list)
    all_define_as = defaultdict(list)
    
    for lua_file in lua_files:
        terrain, objects, define_as = extract_ids_from_file(lua_file, root_path)
        
        # Merge results
        for tid, sources in terrain.items():
            all_terrain[tid].extend(sources)
        for oid, sources in objects.items():
            all_objects[oid].extend(sources)
        for did, sources in define_as.items():
            all_define_as[did].extend(sources)
    
    print(f"Extracted {len(all_terrain)} unique terrain IDs")
    print(f"Extracted {len(all_objects)} unique object IDs")
    print(f"Extracted {len(all_define_as)} unique define_as IDs")
    
    # Limit sources per ID
    all_terrain = merge_sources(all_terrain)
    all_objects = merge_sources(all_objects)
    all_define_as = merge_sources(all_define_as)
    
    # Combine all sources
    all_sources = {}
    all_sources.update(all_terrain)
    all_sources.update(all_objects)
    all_sources.update(all_define_as)
    
    return {
        "terrain_ids": sorted(all_terrain.keys()),
        "object_ids": sorted(all_objects.keys()),
        "define_as_ids": sorted(all_define_as.keys()),
        "sources": all_sources
    }


def main():
    parser = argparse.ArgumentParser(
        description='Extract terrain and object IDs from ToME repository',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --root /home/me/t-engine4
  %(prog)s --root C:\\src\\t-engine4 --include-general
  %(prog)s --root /path/to/tome --out my_manifest.json
        """
    )
    
    parser.add_argument(
        '--root',
        required=True,
        help='Path to local ToME repository root (e.g., /home/me/t-engine4)'
    )
    parser.add_argument(
        '--include-general',
        action='store_true',
        help='Also scan game/modules/tome/data/general/** directory'
    )
    parser.add_argument(
        '--out',
        default='tome_used_terrain_manifest.json',
        help='Output JSON filename (default: tome_used_terrain_manifest.json)'
    )
    
    args = parser.parse_args()
    
    # Validate root path
    root_path = Path(args.root)
    if not root_path.exists():
        print(f"Error: Root path does not exist: {root_path}", file=sys.stderr)
        sys.exit(1)
    
    zones_path = root_path / "game" / "modules" / "tome" / "data" / "zones"
    if not zones_path.exists():
        print(f"Error: Expected zones directory not found: {zones_path}", file=sys.stderr)
        print("Make sure --root points to the ToME repository root directory", file=sys.stderr)
        sys.exit(1)
    
    # Extract IDs
    result = extract_all_ids(root_path, args.include_general)
    
    # Write to file
    output_path = Path(args.out)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, sort_keys=True)
    
    print(f"\nResults written to: {output_path}")
    
    # Also print to stdout
    print("\n" + "="*60)
    print("JSON OUTPUT:")
    print("="*60)
    print(json.dumps(result, indent=2, sort_keys=True))
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
