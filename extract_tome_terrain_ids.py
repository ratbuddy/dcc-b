#!/usr/bin/env python3
"""
TE4 / ToME Terrain (Grid) ID Manifest Generator (All Modules)
=============================================================

Scans ALL modules under game/modules/* for grid definitions:
- **/data/zones/**/grids.lua
- **/data/general/grids/**/*.lua

Extracts from newEntity blocks (lightweight parsing):
- define_as
- base
- image
- add_mos images (optional overlays)

Outputs:
- JSON manifest (default: te4_grid_manifest.json)
- IDs list (one per line): te4_grid_manifest_define_as_ids.txt
- Images list (unique): te4_grid_manifest_images.txt
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
        "sources": []
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

        # close entity?
        if brace_depth <= 0:
            in_entity = False
            if "define_as" in current:
                tid = current["define_as"]
                src = f"{relative_path}:{current.get('define_as_line', line_num)}"
                if current.get("base"):
                    terrain_data[tid]["base"] = terrain_data[tid]["base"] or current["base"]
                if current.get("image"):
                    terrain_data[tid]["image"] = terrain_data[tid]["image"] or current["image"]

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
    merged = defaultdict(lambda: {"base": None, "image": None, "add_mos_images": [], "sources": []})
    for d in all_dicts:
        for tid, data in d.items():
            if data.get("base") and not merged[tid]["base"]:
                merged[tid]["base"] = data["base"]
            if data.get("image") and not merged[tid]["image"]:
                merged[tid]["image"] = data["image"]

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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, help="Path to TE4 repo root (contains game/modules)")
    ap.add_argument("--out", default="te4_grid_manifest.json", help="Output JSON filename")
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

    ids = sorted(merged.keys())
    images = sorted({merged[k]["image"] for k in merged.keys() if merged[k].get("image")})
    # include add_mos images too
    for k in merged.keys():
        for im in merged[k].get("add_mos_images", []):
            images.append(im)
    images = sorted(set(images))

    out_path = Path(args.out).resolve()
    payload = {
        "grid_define_as": ids,
        "count": len(ids),
        "images": images,
        "image_count": len(images),
        "meta": merged,
    }
    out_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")

    base = out_path.with_suffix("")
    (base.parent / f"{base.name}_define_as_ids.txt").write_text("\n".join(ids) + "\n", encoding="utf-8")
    (base.parent / f"{base.name}_images.txt").write_text("\n".join(images) + "\n", encoding="utf-8")

    print(f"Wrote {out_path}")
    print(f"Grid IDs: {len(ids)}")
    print(f"Images (direct + add_mos): {len(images)}")
    print(f"Also wrote: {base.name}_define_as_ids.txt and {base.name}_images.txt")


if __name__ == "__main__":
    main()
