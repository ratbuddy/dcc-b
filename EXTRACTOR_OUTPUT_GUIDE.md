# Extractor Output - Quick Decision Guide

**Question**: Should I run the extractor again or just copy files to /docs/?

**Answer**: **Just copy the files to /docs/** ✅

---

## Why You Don't Need to Re-run

You already ran the extractor and mentioned you "just pushed up the output from the extractor." The extractor generates static files that don't change unless:

1. The ToME4 source code gets new terrain definitions
2. You want to scan different modules
3. The extractor logic itself changes

Since you already have the output files, simply copy them to `/docs/`.

---

## What Files to Copy

The extractor generates these files (copy all to `/docs/`):

```
From wherever you ran it:
├── te4_grid_catalog.json              → docs/te4_grid_catalog.json
├── te4_gallery_safe_ids.txt           → docs/te4_gallery_safe_ids.txt
└── te4_grid_ids_by_category/          → docs/te4_grid_ids_by_category/
    ├── floor.txt                       
    ├── wall.txt                        
    ├── feature.txt                     
    ├── vegetation.txt                  
    ├── water.txt                       
    ├── lava.txt                        
    ├── door.txt                        
    └── special.txt                     
```

---

## Copy Commands

### Option 1: If files are on your local machine

```bash
# From your local machine where you ran the extractor:
cd /path/where/you/ran/extractor

# Copy to your repo
cp te4_grid_catalog.json /path/to/dcc-b/docs/
cp te4_gallery_safe_ids.txt /path/to/dcc-b/docs/
cp -r te4_grid_ids_by_category /path/to/dcc-b/docs/

# Commit and push
cd /path/to/dcc-b
git add docs/te4_grid_catalog.json
git add docs/te4_gallery_safe_ids.txt
git add docs/te4_grid_ids_by_category/
git commit -m "Add TE4 grid extractor output files"
git push
```

### Option 2: If you need to generate them now

Only do this if you don't have the files anymore:

```bash
cd /home/runner/work/dcc-b/dcc-b

# Run extractor pointing to ToME4 source
python3 extract_tome_terrain_ids.py \
  --root /path/to/tome4 \
  --out docs/te4_grid_catalog.json \
  --debug

# The script will automatically create:
# - docs/te4_grid_catalog.json
# - docs/te4_gallery_safe_ids.txt  
# - docs/te4_grid_ids_by_category/*.txt
```

---

## When You WOULD Need to Re-run

You only need to re-run the extractor if:

❌ **Don't re-run** for:
- Adding the files to /docs/ for the first time
- Moving files from one location to another
- Using existing extractor output

✅ **Do re-run** if:
- ToME4 got updated with new terrain
- You want to scan different modules (--no-general, --no-zones flags)
- The extractor script was updated with new features
- You lost the original output files

---

## Verification After Copying

After you copy/generate the files, verify they're in the right place:

```bash
cd /home/runner/work/dcc-b/dcc-b

# Check main files exist
ls -lh docs/te4_grid_catalog.json
ls -lh docs/te4_gallery_safe_ids.txt

# Check category directory exists with 8 files
ls -l docs/te4_grid_ids_by_category/
# Should show: floor.txt, wall.txt, feature.txt, vegetation.txt, 
#              water.txt, lava.txt, door.txt, special.txt

# Quick content check
wc -l docs/te4_gallery_safe_ids.txt
# Should show a reasonable number (100-1000+ IDs)
```

---

## What Happens Next

Once files are in `/docs/`:

1. ✅ All documentation references will work
2. ✅ Template authors can use the category lists safely
3. ✅ Gallery map creation can begin (using TERRAIN_GALLERY_SESSION_PROMPT.md)
4. ✅ Zone generation can reference terrain metadata

---

## Quick Answer Summary

**Just copy the files you already generated to `/docs/`.**

You don't need to re-run the extractor unless:
- You lost the files
- You need updated data from a newer ToME4 version
- You want different scanning options

The extractor output is static and doesn't change based on where the files are stored.

---

**Recommended Next Step**: 
```bash
# Copy your existing output files to docs/
cp <your-extractor-output>/* docs/

# Or if you need to generate fresh:
python3 extract_tome_terrain_ids.py --root /path/to/tome4 --out docs/te4_grid_catalog.json
```
