# Testing dccb-tileset-gallery Zone

## Quick Start

The gallery zone is ready to test! Here's how to access it.

## Method 1: ToME Debug Console (Easiest)

### Step 1: Open ToME Debug Console
In ToME, press one of these keys:
- **`~`** (tilde key, above Tab)
- **Ctrl + D**
- Or enable debug mode in game settings

### Step 2: Enter Command
Copy and paste this exact command:
```lua
game:changeLevel(1, "dccb+dccb-tileset-gallery")
```

Press Enter. You should immediately transition to the gallery zone.

### Step 3: Verify Success
You should see in the log (te4_log.txt):
```
[DCCB-Gallery] Entered zone 'dccb-tileset-gallery' level 1
[DCCB-Gallery] ========================================
[DCCB-Gallery] Generating Tileset Palette
[DCCB-Gallery] ========================================
[DCCB-Gallery] Placing 13 grids in palette
[DCCB-Gallery] Layout: 5 grids per row, spacing=4
[DCCB-Gallery] ✓ [ 5, 5] FLOOR           | Base Game | Standard floor tile
... (12 more grids)
[DCCB-Gallery] Palette generation complete
[DCCB-Gallery] Total grids attempted: 13
```

## Method 2: ToME Debug Menu

### Step 1: Enable Debug Mode
1. In ToME main menu, go to **Settings**
2. Enable **Debug Mode**
3. Start or load a game

### Step 2: Access Zone Menu
1. Press **Ctrl + D** or **F12** (depending on ToME version)
2. Select **"Change Zone"** from debug menu
3. Enter zone name: `dccb+dccb-tileset-gallery`
4. Enter level: `1`

### Step 3: Confirm
You'll be transported to the gallery zone.

## Method 3: Add Temporary Handoff (For Quick Testing)

If you want automatic access when starting a new game, you can temporarily modify dccb-start:

### Temporary Change to dccb-start/zone.lua

Add this to the `on_enter` function in `/mod/tome_addon_harness/data/zones/dccb-start/zone.lua`:

```lua
on_enter = function(a,b,...)
  local zone, lev
  if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
  local zname = (zone and zone.short_name) or "unknown"
  print(string.format("[DCCB-Zone] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  
  -- TEMPORARY: Auto-redirect to gallery for testing
  if game and game.player and not game._DCCB_GALLERY_TESTED then
    game._DCCB_GALLERY_TESTED = true
    print("[DCCB] TEMPORARY: Redirecting to gallery for testing")
    game:changeLevel(1, "dccb+dccb-tileset-gallery")
  end
end,
```

**Remember to remove this after testing!**

## What to Look For

### Visual Inspection
Walk around the map and you should see:
- **13 terrain tiles** arranged in a grid
- **Starting at coordinates (5, 5)**
- **5 tiles per row** with 4-cell spacing between them

### Expected Layout
```
Row 1 (y=5):
  x=5:  FLOOR (grey/beige floor tile)
  x=9:  WALL (stone wall tile)
  x=13: GRASS (green grass tile)
  x=17: ROAD (brown dirt tile)
  x=21: TREE (green tree tile)

Row 2 (y=9):
  x=5:  GRASS_WINTER (white/floor tile)
  x=9:  ROAD_WINTER (blue/floor tile)
  x=13: TREE_WINTER (white/wall tile)
  x=17: GRASS_RUINS (dark green/floor tile)
  x=21: ROAD_RUINS (grey/floor tile)

Row 3 (y=13):
  x=5:  TREE_RUINS (grey/wall tile)
  x=9:  DCCB_ENTRANCE (grass with yellow > marker)
```

### Check Log File
Open `te4_log.txt` and search for `[DCCB-Gallery]`. You should see:
- Entry message
- All 13 grids with ✓ (checkmark) markers
- Coordinates and descriptions
- Completion message

### What Success Looks Like
✅ All grids show **✓** in log (no ✗ failures)  
✅ All tiles render as **PNG graphics** (not ASCII characters)  
✅ Colors match themes (white for winter, grey for ruins, green for plains)  
✅ Layout is organized and clear

### What Failure Looks Like
❌ Some grids show **✗** in log (grid not found)  
❌ Some tiles render as **ASCII** (., ,, =, T, #, >) instead of graphics  
❌ Missing tiles or gaps in the layout

## Troubleshooting

### "Zone not found" Error
**Problem:** ToME can't find the zone  
**Solution:** Make sure all these files exist:
```
mod/tome_addon_harness/data/zones/dccb-tileset-gallery/zone.lua
mod/tome_addon_harness/overload/data/zones/dccb-tileset-gallery/grids.lua
mod/tome_addon_harness/overload/data/zones/dccb-tileset-gallery/npcs.lua
mod/tome_addon_harness/overload/data/zones/dccb-tileset-gallery/objects.lua
mod/tome_addon_harness/overload/data/zones/dccb-tileset-gallery/traps.lua
```

### Console Command Not Working
**Problem:** Command doesn't execute  
**Solution:** 
- Make sure you're in-game (not main menu)
- Try alternative console key (~ or Ctrl+D)
- Check debug mode is enabled

### Tiles Show as ASCII
**Problem:** See characters instead of graphics  
**Solution:** This indicates tileset issues. Check the log:
- Look for which grids have ✓ vs ✗
- Note which tiles render as ASCII
- This is actually useful info for debugging tilesets!

### Empty Map
**Problem:** Zone loads but no tiles visible  
**Solution:**
- Check te4_log.txt for errors
- Verify post_process ran (should see palette generation messages)
- Make sure you're looking at the right area (start is at 5,5)

## After Testing

### Revert Temporary Changes
If you added the temporary handoff in dccb-start, remove it:
1. Delete the temporary redirect code from `on_enter`
2. Keep the original logging-only version

### Report Results
When reporting test results, include:
1. **Log excerpt:** Copy the `[DCCB-Gallery]` section from te4_log.txt
2. **Visual confirmation:** Note which tiles render correctly
3. **Any issues:** Which grids show ✗ or ASCII fallback
4. **Screenshot:** (optional but helpful)

## Expected Test Duration
- **First access:** ~30 seconds (finding console, entering command)
- **Visual inspection:** ~2 minutes (walking around, checking tiles)
- **Log analysis:** ~1 minute (reviewing te4_log.txt)
- **Total:** ~5 minutes for complete validation

## Next Steps After Testing
Once you confirm the gallery works:
1. Note any tileset issues for future refinement
2. Use gallery as reference when developing new themes
3. Add new grids to catalog as needed (see USAGE.md)

---

**Status:** Zone is fully implemented and ready for testing  
**Prerequisites:** None (zone is self-contained)  
**Recommended Method:** Debug console (Method 1)
