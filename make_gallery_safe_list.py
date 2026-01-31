#!/usr/bin/env python3
"""
Legacy Gallery Safe List Generator
===================================

NOTE: The enhanced extract_tome_terrain_ids.py now generates te4_gallery_safe_ids.txt
automatically based on proper semantic categorization. This script is kept for backward
compatibility with the old te4_grid_manifest.json format.

Filters grid IDs based on simple pattern matching to exclude dangerous/special grids.
"""

import json, re

manifest_path = "te4_grid_manifest.json"
out_path = "te4_gallery_safe_ids.txt"

EXCLUDE = re.compile(
    r"(^ZONE_|PORTAL|WORMHOLE|STAIRS|UP|DOWN|EXIT|ENTRANCE|TRIGGER|MARKER|VAULT|EVENT|NOTE|LORE|SIGN|DESCRIPTION|INVIS)",
    re.IGNORECASE
)

with open(manifest_path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Support both old format (grid_define_as) and new format (ids)
ids_key = "ids" if "ids" in data else "grid_define_as"

safe = []
for gid in data[ids_key]:
    if EXCLUDE.search(gid):
        continue
    meta = data["meta"].get(gid, {})
    has_image = bool(meta.get("image")) or bool(meta.get("add_mos_images"))
    if not has_image:
        continue
    safe.append(gid)

safe = sorted(set(safe))

with open(out_path, "w", encoding="utf-8") as f:
    f.write("\n".join(safe) + "\n")

print(f"Wrote {out_path} ({len(safe)} ids)")
print(f"Note: extract_tome_terrain_ids.py now generates this file automatically with better categorization.")
