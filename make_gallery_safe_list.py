import json, re

manifest_path = "te4_grid_manifest.json"
out_path = "te4_gallery_safe_ids.txt"

EXCLUDE = re.compile(
    r"(^ZONE_|PORTAL|WORMHOLE|STAIRS|UP|DOWN|EXIT|ENTRANCE|TRIGGER|MARKER|VAULT|EVENT|NOTE|LORE|SIGN|DESCRIPTION|INVIS)",
    re.IGNORECASE
)

with open(manifest_path, "r", encoding="utf-8") as f:
    data = json.load(f)

safe = []
for gid in data["grid_define_as"]:
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
