#!/usr/bin/env python3
"""
TE4 / ToME Terrain (Grid) ID Catalog Generator (All Modules)
=============================================================

Scans ALL modules under game/modules/* for grid definitions:
- **/data/zones/**/grids.lua
- **/data/general/grids/**/*.lua

Extracts from newEntity blocks (lightweight parsing):
- define_as
- base
- image
- add_mos images (optional overlays)
- semantic fields: name, type, subtype, block_move, block_sight, can_pass,
  change_level, change_zone, on_stand, on_move, door_opened, open_door,
  close_door, is_door, nice_editer.def

Derives:
- boolean flags: is_blocking, is_dangerous, is_doorish
- category: floor, wall, vegetation, water, lava, door, feature, special

Outputs:
- te4_grid_catalog.json: comprehensive metadata with categories
- te4_grid_ids_by_category/<category>.txt: IDs grouped by category
- te4_gallery_safe_ids.txt: union of safe categories
"""

import re
import sys
import json
import argparse
from collections import defaultdict
from pathlib import Path

DEFINE_AS_PATTERN = re.compile(r'define_as\s*=\s*["\']([A-Z_][A-Z0-9_]*)["\']', re.IGNORECASE)
BASE_PATTERN      = re.compile(r'base\s*=\s*["\']([A-Z_][A-Z0-9_]*)["\']', re.IGNORECASE)
IMAGE_PATTERN     = re.compile(r'image\s*=\s*["\']([^"\']+)["\']', re.IGNORECASE)

# Semantic field patterns
NAME_PATTERN      = re.compile(r'name\s*=\s*["\']([^"\']+)["\']', re.IGNORECASE)
TYPE_PATTERN      = re.compile(r'type\s*=\s*["\']([^"\']+)["\']', re.IGNORECASE)
SUBTYPE_PATTERN   = re.compile(r'subtype\s*=\s*["\']([^"\']+)["\']', re.IGNORECASE)
BLOCK_MOVE_PATTERN = re.compile(r'(?:block_move|does_block_move)\s*=\s*(true|false|[0-9]+)', re.IGNORECASE)
BLOCK_SIGHT_PATTERN = re.compile(r'block_sight\s*=\s*(true|false|[0-9]+)', re.IGNORECASE)
CAN_PASS_PATTERN  = re.compile(r'can_pass\s*=\s*(\{[^}]*\}|true|false)', re.IGNORECASE)

# Field presence checks (function/table fields)
CHANGE_LEVEL_PATTERN = re.compile(r'change_level\s*=', re.IGNORECASE)
CHANGE_ZONE_PATTERN  = re.compile(r'change_zone\s*=', re.IGNORECASE)
ON_STAND_PATTERN     = re.compile(r'on_stand\s*=', re.IGNORECASE)
ON_MOVE_PATTERN      = re.compile(r'on_move\s*=', re.IGNORECASE)
DOOR_OPENED_PATTERN  = re.compile(r'door_opened\s*=', re.IGNORECASE)
OPEN_DOOR_PATTERN    = re.compile(r'open_door\s*=', re.IGNORECASE)
CLOSE_DOOR_PATTERN   = re.compile(r'close_door\s*=', re.IGNORECASE)
IS_DOOR_PATTERN      = re.compile(r'is_door\s*=', re.IGNORECASE)
NICE_EDITER_PATTERN  = re.compile(r'nice_editer\s*=\s*\{[^}]*def\s*=\s*["\']([^"\']+)["\']', re.IGNORECASE)

# Add_mos is usually a table that includes image=... entries.
# We'll just grab ANY image=... while inside a newEntity block and store them as add_mos_images too.
# (We'll still store the first image=... as the main image, same as before.)
MAX_SOURCES_PER_ID = 20

def find_grid_files(root_path: Path, include_general: bool, include_zones: bool):
    """Scan all modules under game/modules/* for grids."""
    modules_root = root_path / "game" / "modules"
    if not modules_root.exists():
        raise FileNotFoundError(f"Expected {modules_root} to exist. Is --root correct?")

    files = []
    for moddir in modules_root.iterdir():
        if not moddir.is_dir():
            continue

        if include_zones:
            zones_path = moddir / "data" / "zones"
            if zones_path.exists():
                files.extend(zones_path.rglob("grids.lua"))

        if include_general:
            general_grids_path = moddir / "data" / "general" / "grids"
            if general_grids_path.exists():
                files.extend(general_grids_path.rglob("*.lua"))

    # de-dupe + stable order
    return sorted(set(files))


def extract_from_file(file_path: Path, root_path: Path):
    terrain_data = defaultdict(lambda: {
        "base": None,
        "image": None,
        "add_mos_images": [],
        "sources": [],
        # Semantic fields
        "name": None,
        "type": None,
        "subtype": None,
        "block_move": None,
        "block_sight": None,
        "can_pass": None,
        "change_level": False,
        "change_zone": False,
        "on_stand": False,
        "on_move": False,
        "door_opened": False,
        "open_door": False,
        "close_door": False,
        "is_door": False,
        "nice_editer_def": None,
    })

    try:
        content = file_path.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"Warning: Error reading {file_path}: {e}", file=sys.stderr)
        return {}

    lines = content.splitlines()
    try:
        relative_path = file_path.relative_to(root_path)
    except ValueError:
        relative_path = file_path

    in_entity = False
    brace_depth = 0
    current = {}

    for line_num, line in enumerate(lines, start=1):
        stripped = line.lstrip()
        if stripped.startswith("--"):
            continue

        # naive inline comment strip
        code_part = line.split("--")[0] if "--" in line else line

        if re.search(r'newEntity\s*\{', code_part):
            in_entity = True
            current = {}
            brace_depth = code_part.count("{") - code_part.count("}")
        elif in_entity:
            brace_depth += code_part.count("{") - code_part.count("}")

        if not in_entity:
            continue

        # define_as
        m = DEFINE_AS_PATTERN.search(code_part)
        if m:
            current["define_as"] = m.group(1).upper()
            current["define_as_line"] = line_num

        # base
        m = BASE_PATTERN.search(code_part)
        if m:
            current["base"] = m.group(1).upper()

        # image (capture all images while in entity)
        # first image becomes primary, all images go into add_mos_images pool too
        for m in IMAGE_PATTERN.finditer(code_part):
            img = m.group(1)
            if "image" not in current:
                current["image"] = img
            # collect all image occurrences inside entity
            current.setdefault("all_images", set()).add(img)

        # Extract semantic fields
        m = NAME_PATTERN.search(code_part)
        if m:
            current["name"] = m.group(1)

        m = TYPE_PATTERN.search(code_part)
        if m:
            current["type"] = m.group(1)

        m = SUBTYPE_PATTERN.search(code_part)
        if m:
            current["subtype"] = m.group(1)

        m = BLOCK_MOVE_PATTERN.search(code_part)
        if m:
            val = m.group(1).lower()
            if val == "true":
                current["block_move"] = True
            elif val == "false":
                current["block_move"] = False
            else:
                current["block_move"] = int(val)

        m = BLOCK_SIGHT_PATTERN.search(code_part)
        if m:
            val = m.group(1).lower()
            if val == "true":
                current["block_sight"] = True
            elif val == "false":
                current["block_sight"] = False
            else:
                current["block_sight"] = int(val)

        m = CAN_PASS_PATTERN.search(code_part)
        if m:
            current["can_pass"] = m.group(1)

        # Presence checks for function/table fields
        if CHANGE_LEVEL_PATTERN.search(code_part):
            current["change_level"] = True
        if CHANGE_ZONE_PATTERN.search(code_part):
            current["change_zone"] = True
        if ON_STAND_PATTERN.search(code_part):
            current["on_stand"] = True
        if ON_MOVE_PATTERN.search(code_part):
            current["on_move"] = True
        if DOOR_OPENED_PATTERN.search(code_part):
            current["door_opened"] = True
        if OPEN_DOOR_PATTERN.search(code_part):
            current["open_door"] = True
        if CLOSE_DOOR_PATTERN.search(code_part):
            current["close_door"] = True
        if IS_DOOR_PATTERN.search(code_part):
            current["is_door"] = True

        m = NICE_EDITER_PATTERN.search(code_part)
        if m:
            current["nice_editer_def"] = m.group(1)

        # close entity?
        if brace_depth <= 0:
            in_entity = False
            if "define_as" in current:
                tid = current["define_as"]
                src = f"{relative_path}:{current.get('define_as_line', line_num)}"
                
                # Merge base/image
                if current.get("base"):
                    terrain_data[tid]["base"] = terrain_data[tid]["base"] or current["base"]
                if current.get("image"):
                    terrain_data[tid]["image"] = terrain_data[tid]["image"] or current["image"]

                # Merge semantic fields
                for field in ["name", "type", "subtype", "block_move", "block_sight", "can_pass", "nice_editer_def"]:
                    if current.get(field) is not None:
                        terrain_data[tid][field] = terrain_data[tid][field] or current[field]

                # Merge boolean presence flags (OR logic)
                for field in ["change_level", "change_zone", "on_stand", "on_move", 
                             "door_opened", "open_door", "close_door", "is_door"]:
                    if current.get(field):
                        terrain_data[tid][field] = True

                if current.get("all_images"):
                    imgs = sorted(current["all_images"])
                    # store as add_mos_images candidate list too
                    existing = set(terrain_data[tid]["add_mos_images"])
                    for im in imgs:
                        if im not in existing:
                            terrain_data[tid]["add_mos_images"].append(im)

                # sources
                if src not in terrain_data[tid]["sources"]:
                    terrain_data[tid]["sources"].append(src)
                    terrain_data[tid]["sources"] = terrain_data[tid]["sources"][:MAX_SOURCES_PER_ID]

            current = {}
            if brace_depth < 0:
                brace_depth = 0

    return dict(terrain_data)


def merge(all_dicts):
    merged = defaultdict(lambda: {
        "base": None, "image": None, "add_mos_images": [], "sources": [],
        "name": None, "type": None, "subtype": None, "block_move": None,
        "block_sight": None, "can_pass": None, "change_level": False,
        "change_zone": False, "on_stand": False, "on_move": False,
        "door_opened": False, "open_door": False, "close_door": False,
        "is_door": False, "nice_editer_def": None
    })
    for d in all_dicts:
        for tid, data in d.items():
            if data.get("base") and not merged[tid]["base"]:
                merged[tid]["base"] = data["base"]
            if data.get("image") and not merged[tid]["image"]:
                merged[tid]["image"] = data["image"]

            # merge semantic fields
            for field in ["name", "type", "subtype", "block_move", "block_sight", "can_pass", "nice_editer_def"]:
                if data.get(field) is not None and not merged[tid][field]:
                    merged[tid][field] = data[field]

            # merge boolean flags (OR logic)
            for field in ["change_level", "change_zone", "on_stand", "on_move",
                         "door_opened", "open_door", "close_door", "is_door"]:
                if data.get(field):
                    merged[tid][field] = True

            # merge images
            existing = set(merged[tid]["add_mos_images"])
            for im in data.get("add_mos_images", []):
                if im not in existing:
                    merged[tid]["add_mos_images"].append(im)

            # merge sources
            for src in data.get("sources", []):
                if src not in merged[tid]["sources"]:
                    merged[tid]["sources"].append(src)
                    if len(merged[tid]["sources"]) >= MAX_SOURCES_PER_ID:
                        break

    return dict(merged)


def derive_flags_and_category(tid: str, meta: dict) -> dict:
    """
    Derive boolean flags and coarse category for a grid ID.
    Returns dict with: is_blocking, is_dangerous, is_doorish, category
    """
    result = {}
    
    # Derive is_blocking
    block_move = meta.get("block_move")
    result["is_blocking"] = (block_move is True or block_move == 1)
    
    # Derive is_dangerous
    result["is_dangerous"] = any([
        meta.get("change_level"),
        meta.get("change_zone"),
        meta.get("on_stand"),
        meta.get("on_move")
    ])
    
    # Derive is_doorish
    has_door_field = any([
        meta.get("door_opened"),
        meta.get("open_door"),
        meta.get("close_door"),
        meta.get("is_door")
    ])
    result["is_doorish"] = "DOOR" in tid or has_door_field
    
    # Derive category
    tid_upper = tid.upper()
    type_str = (meta.get("type") or "").lower()
    subtype_str = (meta.get("subtype") or "").lower()
    
    # Check in priority order - specific terrain types first, then special behaviors
    if result["is_doorish"]:
        category = "door"
    elif any(kw in tid_upper for kw in ["LAVA"]):
        category = "lava"
    elif any(kw in tid_upper for kw in ["WATER", "RIVER"]):
        category = "water"
    elif any(kw in tid_upper for kw in ["TREE", "BUSH", "THICKET"]):
        category = "vegetation"
    elif result["is_dangerous"] or any(kw in tid_upper for kw in [
        "PORTAL", "WORMHOLE", "ZONE_", "STAIRS", "UP", "DOWN", "EXIT", "ENTRANCE"
    ]):
        category = "special"
    elif result["is_blocking"] or any(kw in tid_upper for kw in ["WALL", "ROCK", "MOUNTAIN"]):
        category = "wall"
    elif any(kw in tid_upper for kw in [
        "ALTAR", "STATUE", "PILLAR", "HUT", "COLUMN", "FOUNTAIN", "BRAZIER"
    ]) and not result["is_blocking"]:
        category = "feature"
    elif (not result["is_blocking"] and 
          ("floor" in type_str or "floor" in subtype_str)) or any(kw in tid_upper for kw in [
        "GRASS", "FLOOR", "ROAD", "SAND", "SNOW", "ICE", "DIRT", "PATH", "GROUND"
    ]):
        category = "floor"
    else:
        # Default: if blocking -> wall, else -> floor
        category = "wall" if result["is_blocking"] else "floor"
    
    result["category"] = category
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, help="Path to TE4 repo root (contains game/modules)")
    ap.add_argument("--out", default="te4_grid_catalog.json", help="Output JSON filename")
    ap.add_argument("--no-general", action="store_true", help="Disable scanning data/general/grids")
    ap.add_argument("--no-zones", action="store_true", help="Disable scanning data/zones/**/grids.lua")
    ap.add_argument("--debug", action="store_true", help="Print file counts and a few sample paths")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    include_general = not args.no_general
    include_zones = not args.no_zones

    grid_files = find_grid_files(root, include_general, include_zones)
    if args.debug:
        print(f"Found {len(grid_files)} grid files.")
        for p in grid_files[:10]:
            print("  ", p)

    all_data = [extract_from_file(p, root) for p in grid_files]
    merged = merge(all_data)

    # Derive flags and categories for each ID
    for tid, meta in merged.items():
        derived = derive_flags_and_category(tid, meta)
        meta.update(derived)

    ids = sorted(merged.keys())
    images = sorted({merged[k]["image"] for k in merged.keys() if merged[k].get("image")})
    # include add_mos images too
    for k in merged.keys():
        for im in merged[k].get("add_mos_images", []):
            images.append(im)
    images = sorted(set(images))

    # Count by category
    category_counts = defaultdict(int)
    ids_by_category = defaultdict(list)
    for tid in ids:
        cat = merged[tid].get("category", "unknown")
        category_counts[cat] += 1
        ids_by_category[cat].append(tid)

    # Build catalog output
    out_path = Path(args.out).resolve()
    catalog = {
        "ids": ids,
        "count": len(ids),
        "images": images,
        "image_count": len(images),
        "meta": merged,
        "counts": dict(category_counts),
    }
    out_path.write_text(json.dumps(catalog, indent=2, sort_keys=True), encoding="utf-8")

    # Output category-specific files
    category_dir = out_path.parent / "te4_grid_ids_by_category"
    category_dir.mkdir(exist_ok=True)
    
    for cat, cat_ids in ids_by_category.items():
        cat_file = category_dir / f"{cat}.txt"
        cat_file.write_text("\n".join(sorted(cat_ids)) + "\n", encoding="utf-8")

    # Generate gallery safe list: union of safe categories, excluding special and door
    safe_categories = ["floor", "wall", "vegetation", "water", "lava", "feature"]
    safe_ids = []
    for cat in safe_categories:
        safe_ids.extend(ids_by_category.get(cat, []))
    safe_ids = sorted(set(safe_ids))
    
    safe_list_path = out_path.parent / "te4_gallery_safe_ids.txt"
    safe_list_path.write_text("\n".join(safe_ids) + "\n", encoding="utf-8")

    print(f"Wrote {out_path}")
    print(f"Grid IDs: {len(ids)}")
    print(f"Images (direct + add_mos): {len(images)}")
    print(f"Categories: {dict(category_counts)}")
    print(f"Category files written to: {category_dir}")
    print(f"Gallery safe IDs: {len(safe_ids)} (written to {safe_list_path.name})")


if __name__ == "__main__":
    main()
