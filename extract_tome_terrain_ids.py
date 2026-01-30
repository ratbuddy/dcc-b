#!/usr/bin/env python3
"""
ToME Terrain/Grid ID Manifest Generator
========================================

This script crawls a local clone of the official ToME repository and extracts
terrain/grid define_as IDs from grids.lua files ONLY (not npcs, objects, traps).

This produces a high-signal manifest of actual terrain IDs used for map tiles.

Usage:
------
    python extract_tome_terrain_ids.py --root /path/to/t-engine4
    python extract_tome_terrain_ids.py --root /path/to/t-engine4 --include-general
    python extract_tome_terrain_ids.py --root /path/to/t-engine4 --out my_manifest.json

Arguments:
    --root PATH           Path to local ToME repository root (required)
    --include-general     Also scan game/modules/tome/data/general/grids/** (optional)
    --out FILENAME        Output JSON filename (default: tome_terrain_manifest.json)

Output Format:
--------------
The script generates TWO files:

1. JSON file (default: tome_terrain_manifest.json):
{
    "terrain_define_as": [...sorted unique terrain define_as IDs...],
    "meta": {
        "ID": {
            "base": "...",  // optional, if present
            "image": "...",  // optional, if present
            "sources": ["relative/path:line", ...]
        }
    }
}

2. Text file (default: tome_terrain_define_as_ids.txt):
One ID per line for easy pasting into DCCB manifests.

Integration with DCCB:
---------------------
The generated manifest provides a focused list of terrain IDs:
1. Run this script against your ToME installation
2. Use terrain_define_as list for tileset gallery entries
3. Use meta information for image paths and base terrain references
4. Import IDs from .txt file directly into DCCB manifests

Extraction Strategy:
-------------------
Scans ONLY:
- game/modules/tome/data/zones/**/grids.lua
- game/modules/tome/data/general/grids/**/*.lua (if --include-general)

Extracts from grids.lua files:
- define_as = "ID"
- image = "..." (optional)
- base = "..." (optional)

Does NOT scan: npcs.lua, objects.lua, traps.lua, zone.lua, etc.

The script avoids complex Lua parsing to remain lightweight and dependency-free.
"""

import re
import os
import sys
import json
import argparse
from collections import defaultdict
from pathlib import Path


# Regex patterns for extraction from grids.lua files
# Note: ToME IDs typically follow the pattern: starts with letter or underscore,
# followed by letters, digits, or underscores (e.g., FLOOR, WALL_GRANITE, GRASS_01)
# The re.IGNORECASE flag allows matching IDs in any case, and we normalize to uppercase
# with .upper() to ensure consistency

# Pattern for define_as = "ID"
DEFINE_AS_PATTERN = re.compile(
    r'define_as\s*=\s*["\']([A-Z_][A-Z0-9_]*)["\']',
    re.IGNORECASE
)

# Pattern for base = "ID"
BASE_PATTERN = re.compile(
    r'base\s*=\s*["\']([A-Z_][A-Z0-9_]*)["\']',
    re.IGNORECASE
)

# Pattern for image = "path/to/image.png"
IMAGE_PATTERN = re.compile(
    r'image\s*=\s*["\']([^"\']+)["\']',
    re.IGNORECASE
)

# Maximum number of source references to keep per ID
MAX_SOURCES_PER_ID = 10


def find_grids_lua_files(root_path, include_general=False):
    """
    Find all grids.lua files in the zones directory and optionally general/grids directory.
    
    This function restricts scanning to only terrain/grid definition files:
    - game/modules/tome/data/zones/**/grids.lua
    - game/modules/tome/data/general/grids/**/*.lua (if include_general=True)
    
    Does NOT include: npcs.lua, objects.lua, traps.lua, zone.lua, etc.
    
    Args:
        root_path: Path to ToME repository root
        include_general: Whether to include general/grids/** directory
    
    Returns:
        List of Path objects for grids.lua files
    """
    grids_files = []
    
    # Scan zones directory for grids.lua files only
    zones_path = root_path / "game" / "modules" / "tome" / "data" / "zones"
    if zones_path.exists():
        # Find all files named "grids.lua" in zones subdirectories
        for grids_file in zones_path.rglob("grids.lua"):
            grids_files.append(grids_file)
    
    # Optionally scan general/grids directory for all .lua files
    if include_general:
        general_grids_path = root_path / "game" / "modules" / "tome" / "data" / "general" / "grids"
        if general_grids_path.exists():
            # In general/grids, all .lua files are terrain definitions
            grids_files.extend(general_grids_path.rglob("*.lua"))
    
    return grids_files


def extract_terrain_data_from_file(file_path, root_path):
    """
    Extract terrain define_as IDs, base, and image from a grids.lua file.
    
    This function looks for newEntity blocks and extracts:
    - define_as = "ID"
    - base = "ID" (optional)
    - image = "path" (optional)
    
    Args:
        file_path: Path to the grids.lua file
        root_path: Root path for computing relative paths
    
    Returns:
        Dict mapping terrain_id -> {
            "base": "...",  # optional
            "image": "...",  # optional
            "sources": ["relative/path:line", ...]
        }
    """
    terrain_data = defaultdict(lambda: {
        "base": None,
        "image": None,
        "sources": []
    })
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            lines = content.split('\n')
        
        try:
            relative_path = file_path.relative_to(root_path)
        except ValueError:
            # Fallback if file_path is not under root_path (e.g., symlinks)
            relative_path = file_path
        
        # Track current entity block for multi-line parsing
        current_entity = None
        current_entity_start_line = None
        in_entity_block = False
        brace_depth = 0
        
        for line_num, line in enumerate(lines, start=1):
            # Skip pure comment lines
            stripped = line.lstrip()
            if stripped.startswith('--'):
                continue
            
            # Remove inline comments (simple approach - doesn't handle -- inside string literals)
            # This limitation is acceptable per requirements for lightweight parsing
            code_part = line.split('--')[0] if '--' in line else line
            
            # Check if we're entering a newEntity block
            # Look for 'newEntity' followed by a brace (allowing whitespace between)
            if re.search(r'newEntity\s*\{', code_part):
                # Don't start a new entity if we're already in one (handle nested/malformed cases)
                if in_entity_block:
                    # Log warning but continue (could be malformed Lua)
                    print(f"Warning: Nested newEntity detected at {relative_path}:{line_num}", file=sys.stderr)
                
                in_entity_block = True
                current_entity = {}
                current_entity_start_line = line_num
                brace_depth = code_part.count('{') - code_part.count('}')
            elif in_entity_block:
                brace_depth += code_part.count('{') - code_part.count('}')
            
            # If we're in an entity block, extract fields
            if in_entity_block:
                # Extract define_as
                define_as_match = DEFINE_AS_PATTERN.search(code_part)
                if define_as_match:
                    current_entity['define_as'] = define_as_match.group(1).upper()
                    current_entity['define_as_line'] = line_num
                
                # Extract base
                base_match = BASE_PATTERN.search(code_part)
                if base_match:
                    current_entity['base'] = base_match.group(1).upper()
                
                # Extract image
                image_match = IMAGE_PATTERN.search(code_part)
                if image_match:
                    current_entity['image'] = image_match.group(1)
                
                # Check if entity block is closed (handle malformed code with negative depth)
                if brace_depth <= 0:
                    in_entity_block = False
                    # Process the completed entity
                    if 'define_as' in current_entity:
                        terrain_id = current_entity['define_as']
                        source = f"{relative_path}:{current_entity['define_as_line']}"
                        
                        # Store data
                        if current_entity.get('base'):
                            terrain_data[terrain_id]['base'] = current_entity['base']
                        if current_entity.get('image'):
                            terrain_data[terrain_id]['image'] = current_entity['image']
                        terrain_data[terrain_id]['sources'].append(source)
                    
                    current_entity = None
                    # Reset brace_depth if it went negative
                    if brace_depth < 0:
                        brace_depth = 0
    
    except Exception as e:
        print(f"Warning: Error reading {file_path}: {e}", file=sys.stderr)
    
    return dict(terrain_data)


def merge_terrain_data(all_terrain_data):
    """
    Merge terrain data from multiple files and limit sources per ID.
    
    Args:
        all_terrain_data: List of dicts from extract_terrain_data_from_file
    
    Returns:
        Dict mapping terrain_id -> {base, image, sources}
    """
    merged = defaultdict(lambda: {
        "base": None,
        "image": None,
        "sources": []
    })
    
    for terrain_data in all_terrain_data:
        for terrain_id, data in terrain_data.items():
            # Merge base (prefer first non-None value, warn on conflicts)
            if data.get('base'):
                if merged[terrain_id]['base'] and merged[terrain_id]['base'] != data['base']:
                    print(f"Warning: Conflicting 'base' for {terrain_id}: "
                          f"{merged[terrain_id]['base']} vs {data['base']}", file=sys.stderr)
                elif not merged[terrain_id]['base']:
                    merged[terrain_id]['base'] = data['base']
            
            # Merge image (prefer first non-None value, warn on conflicts)
            if data.get('image'):
                if merged[terrain_id]['image'] and merged[terrain_id]['image'] != data['image']:
                    print(f"Warning: Conflicting 'image' for {terrain_id}: "
                          f"{merged[terrain_id]['image']} vs {data['image']}", file=sys.stderr)
                elif not merged[terrain_id]['image']:
                    merged[terrain_id]['image'] = data['image']
            
            # Merge sources (deduplicate and limit)
            for source in data.get('sources', []):
                if source not in merged[terrain_id]['sources']:
                    merged[terrain_id]['sources'].append(source)
                    if len(merged[terrain_id]['sources']) >= MAX_SOURCES_PER_ID:
                        break
    
    # Convert to regular dict and clean up None values
    result = {}
    for terrain_id, data in merged.items():
        cleaned_data = {"sources": data['sources']}
        if data['base']:
            cleaned_data['base'] = data['base']
        if data['image']:
            cleaned_data['image'] = data['image']
        result[terrain_id] = cleaned_data
    
    return result


def extract_all_terrain_data(root_path, include_general=False):
    """
    Extract all terrain data from ToME repository grids.lua files.
    
    Args:
        root_path: Path to ToME repository root
        include_general: Whether to include general/grids/** directory
    
    Returns:
        Dict with terrain_define_as and meta fields
    """
    print(f"Scanning ToME repository at: {root_path}")
    if include_general:
        print("Including general/grids/** directory")
    
    grids_files = find_grids_lua_files(root_path, include_general)
    print(f"Found {len(grids_files)} grids.lua files to process")
    
    all_terrain_data = []
    
    for grids_file in grids_files:
        terrain_data = extract_terrain_data_from_file(grids_file, root_path)
        if terrain_data:
            all_terrain_data.append(terrain_data)
    
    # Merge all terrain data
    merged_meta = merge_terrain_data(all_terrain_data)
    
    print(f"Extracted {len(merged_meta)} unique terrain define_as IDs")
    
    return {
        "terrain_define_as": sorted(merged_meta.keys()),
        "meta": merged_meta
    }


def main():
    parser = argparse.ArgumentParser(
        description='Extract terrain define_as IDs from ToME grids.lua files',
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
        help='Also scan game/modules/tome/data/general/grids/** directory'
    )
    parser.add_argument(
        '--out',
        default='tome_terrain_manifest.json',
        help='Output JSON filename (default: tome_terrain_manifest.json)'
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
    
    # Extract terrain data
    result = extract_all_terrain_data(root_path, args.include_general)
    
    # Write JSON file
    output_path = Path(args.out)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, sort_keys=True)
    
    print(f"\nJSON results written to: {output_path}")
    
    # Write text file with one ID per line
    # Derive text filename from JSON output path to preserve user's naming preference
    txt_output_path = output_path.with_suffix('.txt')
    with open(txt_output_path, 'w', encoding='utf-8') as f:
        for terrain_id in result['terrain_define_as']:
            f.write(f"{terrain_id}\n")
    
    print(f"Text ID list written to: {txt_output_path}")
    
    # Also print summary to stdout
    print("\n" + "="*60)
    print("EXTRACTION SUMMARY:")
    print("="*60)
    print(f"Total terrain IDs: {len(result['terrain_define_as'])}")
    print(f"\nFirst 20 IDs:")
    for terrain_id in result['terrain_define_as'][:20]:
        print(f"  - {terrain_id}")
    if len(result['terrain_define_as']) > 20:
        print(f"  ... and {len(result['terrain_define_as']) - 20} more")
    
    print("\n" + "="*60)
    print("JSON OUTPUT (first 50 lines):")
    print("="*60)
    json_str = json.dumps(result, indent=2, sort_keys=True)
    json_lines = json_str.split('\n')
    print('\n'.join(json_lines[:50]))
    if len(json_lines) > 50:
        print(f"... ({len(json_lines) - 50} more lines)")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
