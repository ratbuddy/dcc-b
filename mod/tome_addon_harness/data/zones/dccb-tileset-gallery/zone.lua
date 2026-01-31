-- /data/zones/dccb-tileset-gallery/zone.lua
-- DCCB Tileset Gallery Zone - Dense Visual Catalog and Validation Tool
-- Virtual path: /data-dccb/zones/dccb-tileset-gallery/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-tileset-gallery/ (overload)

-- This is a debug/reference zone to validate terrain tilesets
-- It displays a dense "palette map" of dozens/hundreds of terrain samples
-- Missing IDs are skipped safely, dangerous terrains (with change_level/on_stand) are filtered

-- Dense layout configuration
local CELL_W = 3              -- Cell width (3x3 per terrain)
local CELL_H = 3              -- Cell height (3x3 per terrain)
local CELL_GAP = 1            -- Gap between cells
local START_X = 2             -- Palette start X
local START_Y = 2             -- Palette start Y
local SPAWN_PAD_SIZE = 8      -- Walkable spawn pad size

return {
  name = "DCCB Tileset Gallery",
  short_name = "dccb-tileset-gallery",
  level_range = {1, 1},
  max_level = 1,
  width = 60,  -- Wide enough for dense palette (384 terrains)
  height = 100, -- Tall enough for many rows (~25 rows needed)
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  no_level_connectivity = true,
  
  -- Explicit zone entity loads (ensures grids/npcs/objects/traps are registered)
  load = {
    "/data/zones/dccb-tileset-gallery/grids.lua",
    "/data/zones/dccb-tileset-gallery/npcs.lua",
    "/data/zones/dccb-tileset-gallery/objects.lua",
    "/data/zones/dccb-tileset-gallery/traps.lua",
  },
  
  -- Generator: Empty (blank canvas for manual palette placement)
  generator = {
    map = {
      class = "engine.generator.map.Empty",
    },
    actor = {
      nb_npc = {0, 0},
    },
    object = {
      nb_object = {0, 0},
    },
    trap = {
      nb_trap = {0, 0},
    },
  },
  
  -- Debug logging on zone entry
  on_enter = function(a,b,...)
    local zone, lev
    if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
    local zname = (zone and zone.short_name) or "unknown"
    print(string.format("[DCCB-Gallery] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  end,
  
  -- Post-process: Place dense terrain palette with safe filtering
  post_process = function(a, b, c, ...)
    local Map = require "engine.Map"
    
    -- Load terrain manifest
    local manifest_ok, manifest = pcall(loadfile, "/data-dccb/dccb/tileset/gallery_manifest.lua")
    if not manifest_ok or not manifest then
      print("[DCCB-Gallery] ERROR: Cannot load gallery manifest")
      return
    end
    manifest = manifest()
    
    -- Capability-based detection: find level and zone by their methods
    local level, zone
    
    -- Find level: whichever arg is a table with .map
    for _, arg in ipairs({a, b, c}) do
      if type(arg) == "table" and arg.map then
        level = arg
        break
      end
    end
    
    -- Find zone: whichever arg is a table with .makeEntityByName or .makeEntity
    for _, arg in ipairs({a, b, c}) do
      if type(arg) == "table" and (arg.makeEntityByName or arg.makeEntity) then
        zone = arg
        break
      end
    end
    
    -- Validate we have both level and zone
    if not level or not level.map then
      print("[DCCB-Gallery] ERROR: Cannot detect level object (no .map found)")
      return
    end
    
    if not zone or not (zone.makeEntityByName or zone.makeEntity) then
      print("[DCCB-Gallery] ERROR: Cannot detect zone object (no .makeEntityByName/.makeEntity found)")
      return
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Generating Dense Tileset Palette")
    print("[DCCB-Gallery] ========================================")
    
    -- Step 1: Fill background to prevent black map
    print("[DCCB-Gallery] Step 1: Filling background...")
    local background_grid = zone:makeEntityByName(level, "terrain", "GRASS") or 
                           zone:makeEntityByName(level, "terrain", "FLOOR")
    
    if background_grid then
      if background_grid.resolve then background_grid:resolve() end
      for x = 0, level.map.w - 1 do
        for y = 0, level.map.h - 1 do
          level.map(x, y, Map.TERRAIN, background_grid)
        end
      end
      print("[DCCB-Gallery] Background filled with: " .. (background_grid.name or "unknown"))
    else
      print("[DCCB-Gallery] WARNING: No background grid available (GRASS/FLOOR not found)")
    end
    
    -- Step 2: Create spawn pad (walkable area for player)
    print("[DCCB-Gallery] Step 2: Creating spawn pad...")
    local spawn_x = level.map.w - SPAWN_PAD_SIZE - 2
    local spawn_y = level.map.h - SPAWN_PAD_SIZE - 2
    local spawn_floor = zone:makeEntityByName(level, "terrain", "GRASS") or 
                       zone:makeEntityByName(level, "terrain", "FLOOR")
    
    if spawn_floor then
      if spawn_floor.resolve then spawn_floor:resolve() end
      for x = spawn_x, spawn_x + SPAWN_PAD_SIZE - 1 do
        for y = spawn_y, spawn_y + SPAWN_PAD_SIZE - 1 do
          level.map(x, y, Map.TERRAIN, spawn_floor)
        end
      end
      print(string.format("[DCCB-Gallery] Spawn pad: %dx%d at (%d,%d)", 
        SPAWN_PAD_SIZE, SPAWN_PAD_SIZE, spawn_x, spawn_y))
    end
    
    -- Step 3: Calculate dense layout with 3x3 cells + 1 tile gap
    local map_width = level.map.w
    local cell_total = CELL_W + CELL_GAP  -- Total space per cell
    local available_width = map_width - START_X - 2
    local cols = math.floor(available_width / cell_total)
    cols = math.max(cols, 8)  -- At least 8 columns
    
    print(string.format("[DCCB-Gallery] Step 3: Layout: %d columns, %dx%d cells, %d gap", 
      cols, CELL_W, CELL_H, CELL_GAP))
    
    -- Step 4: Place terrain samples with safety checks
    print(string.format("[DCCB-Gallery] Step 4: Placing terrain samples from manifest (%d candidates)...", 
      #manifest.TERRAIN_CANDIDATES))
    
    local placed_count = 0
    local skipped_missing = 0
    local skipped_dangerous = 0
    
    -- Blacklist of known-dangerous terrains that should NOT be displayed
    -- These have actual gameplay hooks that could cause unwanted transitions
    local KNOWN_DANGEROUS = {
      DCCB_ENTRANCE = true,  -- Has on_stand message
      -- Note: We're using a blacklist approach instead of checking for hooks
      -- because many safe terrains inherit hooks from base entities
    }
    
    -- Track category for logging
    local last_category = nil
    local category_start_idx = 1
    
    -- Place each terrain candidate
    for idx, terrain_info in ipairs(manifest.TERRAIN_CANDIDATES) do
      -- Log category headers (when category changes)
      if terrain_info.category ~= last_category then
        if last_category then
          print(string.format("[DCCB-Gallery]   %s: %d terrains", last_category, idx - category_start_idx))
        end
        last_category = terrain_info.category
        category_start_idx = idx
        print(string.format("[DCCB-Gallery] Category: %s", terrain_info.category))
      end
      
      local row = math.floor((idx - 1) / cols)
      local col = (idx - 1) % cols
      
      -- Calculate position with cell spacing + gap
      local cell_total = CELL_W + CELL_GAP
      local x = START_X + (col * cell_total)
      local y = START_Y + (row * cell_total)
      
      -- Skip if out of bounds
      if x >= map_width - 2 or y >= level.map.h - 2 then
        print(string.format("[DCCB-Gallery] WARNING: Out of bounds at terrain #%d, stopping", idx))
        break
      end
      
      -- Try to make the terrain entity using "terrain" kind
      local terrain = zone:makeEntityByName(level, "terrain", terrain_info.id)
      
      if not terrain then
        -- Terrain not found (missing)
        skipped_missing = skipped_missing + 1
        -- Only log first few missing to avoid spam
        if skipped_missing <= 5 then
          print(string.format("[DCCB-Gallery] ⊘ [%2d,%2d] %-20s | MISSING", 
            x, y, terrain_info.id))
        end
      else
        -- Resolve the terrain first to get actual properties
        if terrain.resolve then terrain:resolve() end
        
        -- Check if this is a blacklisted dangerous terrain
        if KNOWN_DANGEROUS[terrain_info.id] then
          -- Blacklisted: skip it
          skipped_dangerous = skipped_dangerous + 1
          print(string.format("[DCCB-Gallery] ⚠ [%2d,%2d] %-20s | DANGEROUS (blacklisted)", 
            x, y, terrain_info.id))
        else
          -- Not blacklisted: safe to place
          level.map(x, y, Map.TERRAIN, terrain)
          placed_count = placed_count + 1
          
          -- Only log first few placements to avoid spam
          if placed_count <= 10 then
            print(string.format("[DCCB-Gallery] ✓ [%2d,%2d] %-20s | %s", 
              x, y, terrain_info.id, terrain_info.category))
          end
        end
      end
    end
    
    -- Log final category
    if last_category then
      print(string.format("[DCCB-Gallery]   %s: %d terrains", last_category, #manifest.TERRAIN_CANDIDATES - category_start_idx + 1))
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Palette generation complete")
    print("[DCCB-Gallery] ========================================")
    print(string.format("[DCCB-Gallery] Total candidates: %d", #manifest.TERRAIN_CANDIDATES))
    print(string.format("[DCCB-Gallery] ✓ Placed: %d terrains", placed_count))
    print(string.format("[DCCB-Gallery] ⊘ Skipped (missing): %d", skipped_missing))
    print(string.format("[DCCB-Gallery] ⚠ Skipped (dangerous): %d", skipped_dangerous))
    print(string.format("[DCCB-Gallery] Layout: %d columns × %d rows visible", 
      cols, math.ceil(placed_count / cols)))
    print("[DCCB-Gallery] ========================================")
  end,
}
