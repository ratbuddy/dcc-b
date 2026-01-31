#!/bin/bash
# Helper script to verify extractor output files are in place
# Usage: ./verify_extractor_output.sh

set -e

echo "=== TE4 Grid Extractor Output Verification ==="
echo ""

DOCS_DIR="docs"
MISSING=()

# Check main files
echo "Checking main files..."
if [ -f "$DOCS_DIR/te4_grid_catalog.json" ]; then
    SIZE=$(wc -c < "$DOCS_DIR/te4_grid_catalog.json")
    echo "  ✅ te4_grid_catalog.json (${SIZE} bytes)"
else
    echo "  ❌ te4_grid_catalog.json - MISSING"
    MISSING+=("te4_grid_catalog.json")
fi

if [ -f "$DOCS_DIR/te4_gallery_safe_ids.txt" ]; then
    LINES=$(wc -l < "$DOCS_DIR/te4_gallery_safe_ids.txt")
    echo "  ✅ te4_gallery_safe_ids.txt (${LINES} IDs)"
else
    echo "  ❌ te4_gallery_safe_ids.txt - MISSING"
    MISSING+=("te4_gallery_safe_ids.txt")
fi

echo ""
echo "Checking category files..."

CATEGORIES=("floor" "wall" "feature" "vegetation" "water" "lava" "door" "special")
for cat in "${CATEGORIES[@]}"; do
    FILE="$DOCS_DIR/te4_grid_ids_by_category/${cat}.txt"
    if [ -f "$FILE" ]; then
        LINES=$(wc -l < "$FILE")
        echo "  ✅ ${cat}.txt (${LINES} IDs)"
    else
        echo "  ❌ ${cat}.txt - MISSING"
        MISSING+=("te4_grid_ids_by_category/${cat}.txt")
    fi
done

echo ""
echo "=== Summary ==="

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "✅ All extractor output files are present!"
    echo ""
    echo "You can now:"
    echo "  • Use terrain lists in templates (see TE4_GRID_SAFETY_ANALYSIS.md)"
    echo "  • Create a gallery map (see TERRAIN_GALLERY_SESSION_PROMPT.md)"
    echo "  • Reference terrain metadata in zone generation"
    exit 0
else
    echo "❌ Missing ${#MISSING[@]} file(s):"
    for f in "${MISSING[@]}"; do
        echo "  - docs/$f"
    done
    echo ""
    echo "To fix:"
    echo "  1. Copy existing files: See EXTRACTOR_OUTPUT_GUIDE.md"
    echo "  2. Or regenerate: python3 extract_tome_terrain_ids.py --root /path/to/tome4 --out docs/te4_grid_catalog.json"
    exit 1
fi
