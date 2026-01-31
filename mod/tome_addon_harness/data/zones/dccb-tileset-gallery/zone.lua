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
  width = 64,  -- Safe, proven size (bounds-aware placement)
  height = 64, -- Small, predictable (prevents out-of-bounds)
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
  -- MUST be 64×64 for safe, bounds-aware placement
  generator = {
    map = {
      class = "engine.generator.map.Empty",
      width = 64,
      height = 64,
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
    
    -- Load terrain manifest (comprehensive extracted list)
    -- Now using full manifest since all general packs are loaded
    print("[DCCB-Gallery] Loading manifest from: /data-dccb/dccb/tileset/gallery_manifest.lua")
    local manifest_ok, manifest = pcall(loadfile, "/data-dccb/dccb/tileset/gallery_manifest.lua")
    if not manifest_ok or not manifest then
      print("[DCCB-Gallery] ERROR: Cannot load gallery manifest")
      print("[DCCB-Gallery] Error: " .. tostring(manifest))
      return
    end
    manifest = manifest()
    
    -- Debug: Log manifest info
    if manifest and manifest.TERRAIN_CANDIDATES then
      local count = #manifest.TERRAIN_CANDIDATES
      print(string.format("[DCCB-Gallery] Manifest loaded: %d terrain candidates", count))
      if count > 0 then
        local first_few = {}
        for i = 1, math.min(5, count) do
          table.insert(first_few, manifest.TERRAIN_CANDIDATES[i].id)
        end
        print("[DCCB-Gallery] First 5 IDs: " .. table.concat(first_few, ", "))
      end
    else
      print("[DCCB-Gallery] ERROR: Manifest loaded but has no TERRAIN_CANDIDATES")
      return
    end
    
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
    
    -- Read actual map bounds at runtime (NEVER assume size)
    local map = level.map
    local W, H = map.w, map.h
    print(string.format("[DCCB-Gallery] Map bounds: %d x %d", W, H))
    
    -- Step 1: Fill background to prevent black map
    print("[DCCB-Gallery] Step 1: Filling background...")
    local background_grid = zone:makeEntityByName(level, "terrain", "GRASS") or 
                           zone:makeEntityByName(level, "terrain", "FLOOR")
    
    if background_grid then
      if background_grid.resolve then background_grid:resolve() end
      for x = 0, W - 1 do
        for y = 0, H - 1 do
          level.map(x, y, Map.TERRAIN, background_grid)
        end
      end
      print("[DCCB-Gallery] Background filled with: " .. (background_grid.name or "unknown"))
    else
      print("[DCCB-Gallery] WARNING: No background grid available (GRASS/FLOOR not found)")
    end
    
    -- Step 2: Calculate dynamic layout based on actual bounds
    local stride_x = CELL_W + CELL_GAP  -- 4
    local stride_y = CELL_H + CELL_GAP  -- 4
    local margin = 2
    
    local max_cols = math.max(1, math.floor((W - START_X - margin) / stride_x))
    local max_rows = math.max(1, math.floor((H - START_Y - margin) / stride_y))
    local capacity = max_cols * max_rows
    
    print(string.format("[DCCB-Gallery] Step 2: Layout: %d cols × %d rows (max capacity: %d)", 
      max_cols, max_rows, capacity))
    print(string.format("[DCCB-Gallery]   Cell: %dx%d, Gap: %d, Stride: %dx%d", 
      CELL_W, CELL_H, CELL_GAP, stride_x, stride_y))
    
    -- Step 3: Place spawn pad AFTER knowing bounds
    print("[DCCB-Gallery] Step 3: Creating spawn pad...")
    -- Clamp spawn pad to safe location within bounds
    local pad_x = math.max(2, math.min(W - SPAWN_PAD_SIZE - 2, W - SPAWN_PAD_SIZE - margin))
    local pad_y = math.max(2, math.min(H - SPAWN_PAD_SIZE - 2, H - SPAWN_PAD_SIZE - margin))
    
    local spawn_floor = zone:makeEntityByName(level, "terrain", "GRASS") or 
                       zone:makeEntityByName(level, "terrain", "FLOOR")
    
    if spawn_floor then
      if spawn_floor.resolve then spawn_floor:resolve() end
      -- Clamp spawn pad size to never exceed bounds
      local pad_w = math.min(SPAWN_PAD_SIZE, W - pad_x)
      local pad_h = math.min(SPAWN_PAD_SIZE, H - pad_y)
      for x = pad_x, pad_x + pad_w - 1 do
        for y = pad_y, pad_y + pad_h - 1 do
          if x < W and y < H then  -- Extra safety check
            level.map(x, y, Map.TERRAIN, spawn_floor)
          end
        end
      end
      print(string.format("[DCCB-Gallery] Spawn pad: %dx%d at (%d,%d)", 
        pad_w, pad_h, pad_x, pad_y))
    end
    
    -- Step 4: Place terrain samples with BOUNDS-SAFE placement
    print(string.format("[DCCB-Gallery] Step 4: Placing terrain samples from manifest (%d candidates)...", 
      #manifest.TERRAIN_CANDIDATES))
    
    local placed_count = 0
    local skipped_missing = 0
    local skipped_dangerous = 0
    local stopped_reason = nil
    
    -- Blacklist of known-dangerous terrains that should NOT be displayed
    local KNOWN_DANGEROUS = {
      DCCB_ENTRANCE = true,  -- Has on_stand message
    }
    
    -- Track category for logging
    local last_category = nil
    local category_start_idx = 1
    
    -- Place each terrain candidate (BOUNDS-AWARE)
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
      
      -- Calculate position from index
      local row = math.floor((idx - 1) / max_cols)
      local col = (idx - 1) % max_cols
      
      local x = START_X + (col * stride_x)
      local y = START_Y + (row * stride_y)
      
      -- BOUNDS CHECK: Stop if cell would exceed map bounds
      if x + CELL_W - 1 >= W or y + CELL_H - 1 >= H then
        print(string.format("[DCCB-Gallery] Palette full at terrain #%d, stopping placement", idx))
        stopped_reason = "Map full"
        break
      end
      
      -- Try to make the terrain entity
      local terrain = zone:makeEntityByName(level, "terrain", terrain_info.id)
      
      if not terrain then
        -- Terrain not found (missing)
        skipped_missing = skipped_missing + 1
        if skipped_missing <= 5 then
          print(string.format("[DCCB-Gallery] ⊘ [%2d,%2d] %-20s | MISSING", 
            x, y, terrain_info.id))
        end
      else
        -- Resolve the terrain first
        if terrain.resolve then terrain:resolve() end
        
        -- Check if blacklisted
        if KNOWN_DANGEROUS[terrain_info.id] then
          skipped_dangerous = skipped_dangerous + 1
          print(string.format("[DCCB-Gallery] ⚠ [%2d,%2d] %-20s | DANGEROUS (blacklisted)", 
            x, y, terrain_info.id))
        else
          -- Safe to place: place entire cell (3×3)
          for cx = 0, CELL_W - 1 do
            for cy = 0, CELL_H - 1 do
              local px, py = x + cx, y + cy
              if px < W and py < H then  -- Extra safety
                level.map(px, py, Map.TERRAIN, terrain)
              end
            end
          end
          placed_count = placed_count + 1
          
          -- Only log first few placements
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
    print(string.format("[DCCB-Gallery] Map bounds: %d × %d", W, H))
    print(string.format("[DCCB-Gallery] Layout capacity: %d cols × %d rows = %d max", max_cols, max_rows, capacity))
    print(string.format("[DCCB-Gallery] Total candidates: %d", #manifest.TERRAIN_CANDIDATES))
    print(string.format("[DCCB-Gallery] ✓ Placed: %d terrains", placed_count))
    print(string.format("[DCCB-Gallery] ⊘ Skipped (missing): %d", skipped_missing))
    print(string.format("[DCCB-Gallery] ⚠ Skipped (dangerous): %d", skipped_dangerous))
    if stopped_reason then
      print(string.format("[DCCB-Gallery] Stopped due to: %s", stopped_reason))
    end
    print(string.format("[DCCB-Gallery] Actual layout: %d columns × %d rows", 
      max_cols, math.ceil(placed_count / max_cols)))
    print("[DCCB-Gallery] ========================================")
  end,
}
