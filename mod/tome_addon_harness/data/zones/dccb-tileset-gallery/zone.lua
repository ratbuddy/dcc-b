-- /data/zones/dccb-tileset-gallery/zone.lua
-- DCCB Tileset Gallery Zone - Visual Catalog and Validation Tool
-- Virtual path: /data-dccb/zones/dccb-tileset-gallery/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-tileset-gallery/ (overload)

-- This is a debug/reference zone to validate terrain tilesets
-- It displays a "palette map" of all DCCB surface grids and key base game grids

return {
  name = "DCCB Tileset Gallery",
  short_name = "dccb-tileset-gallery",
  level_range = {1, 1},
  max_level = 1,
  width = 50,  -- Wide enough to fit palette
  height = 50, -- Tall enough to fit palette
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
  
  -- Post-process: Place grid palette in organized layout
  post_process = function(a, b, c, ...)
    local Map = require "engine.Map"
    
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
    print("[DCCB-Gallery] Generating Tileset Palette")
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
    
    -- Step 2: Define grid catalog to display
    print("[DCCB-Gallery] Step 2: Preparing terrain catalog...")
    local grid_catalog = {
      -- ===== DCCB CUSTOM GRIDS =====
      
      -- Base game grids (from /data/general/grids/basic.lua)
      {id = "FLOOR", category = "DCCB/Base", description = "Standard floor tile"},
      {id = "WALL", category = "DCCB/Base", description = "Standard wall tile"},
      
      -- DCCB Green/Plains theme
      {id = "GRASS", category = "DCCB/Green", description = "Grass (explicit tileset)"},
      {id = "ROAD", category = "DCCB/Green", description = "Dirt road (explicit)"},
      {id = "TREE", category = "DCCB/Green", description = "Tree (explicit)"},
      
      -- DCCB Winter/Snow theme
      {id = "GRASS_WINTER", category = "DCCB/Winter", description = "Snowy ground"},
      {id = "ROAD_WINTER", category = "DCCB/Winter", description = "Icy path"},
      {id = "TREE_WINTER", category = "DCCB/Winter", description = "Snowy tree"},
      
      -- DCCB Ruins/Ancient theme
      {id = "GRASS_RUINS", category = "DCCB/Ruins", description = "Overgrown ground"},
      {id = "ROAD_RUINS", category = "DCCB/Ruins", description = "Ancient path"},
      {id = "TREE_RUINS", category = "DCCB/Ruins", description = "Ruined pillar"},
      
      -- DCCB Special
      {id = "DCCB_ENTRANCE", category = "DCCB/Special", description = "Dungeon entrance marker"},
      
      -- ===== OFFICIAL TOME TERRAINS =====
      -- These IDs may or may not exist depending on loaded packs
      
      -- Forest terrain (from forest.lua)
      {id = "FOREST_TREE", category = "ToME/Forest", description = "Forest tree"},
      {id = "TREE_OLDER", category = "ToME/Forest", description = "Old tree"},
      {id = "TREE_BURNT", category = "ToME/Forest", description = "Burnt tree"},
      {id = "DENSE_FOREST", category = "ToME/Forest", description = "Dense forest"},
      
      -- Water terrain (from water.lua)
      {id = "WATER", category = "ToME/Water", description = "Shallow water"},
      {id = "DEEP_WATER", category = "ToME/Water", description = "Deep water"},
      {id = "WATER_BUBBLE", category = "ToME/Water", description = "Bubbling water"},
      
      -- Lava terrain (from lava.lua)
      {id = "LAVA", category = "ToME/Lava", description = "Lava"},
      {id = "LAVA_DEEP", category = "ToME/Lava", description = "Deep lava"},
      {id = "VOLCANIC_FLOOR", category = "ToME/Lava", description = "Volcanic floor"},
      
      -- Mountain/Rock terrain (from mountain.lua)
      {id = "MOUNTAIN", category = "ToME/Mountain", description = "Mountain"},
      {id = "MOUNTAIN_WALL", category = "ToME/Mountain", description = "Mountain wall"},
      {id = "ROCK", category = "ToME/Mountain", description = "Rocky ground"},
      
      -- Additional base terrain variants
      {id = "HARDFLOOR", category = "ToME/Base", description = "Hard floor"},
      {id = "HARDWALL", category = "ToME/Base", description = "Hard wall"},
    }
    
    -- Layout configuration
    local start_x = 5
    local start_y = 5
    local grid_spacing = 4  -- Space between grid samples
    local grids_per_row = 6  -- Increased to fit more grids
    
    print(string.format("[DCCB-Gallery] Step 3: Placing %d terrain samples...", #grid_catalog))
    print("[DCCB-Gallery] Layout: " .. grids_per_row .. " grids per row, spacing=" .. grid_spacing)
    
    local placed_count = 0
    local skipped_count = 0
    
    -- Place each grid in the catalog
    for idx, grid_info in ipairs(grid_catalog) do
      local row = math.floor((idx - 1) / grids_per_row)
      local col = (idx - 1) % grids_per_row
      
      local x = start_x + (col * grid_spacing)
      local y = start_y + (row * grid_spacing)
      
      -- Try to make the grid entity using "terrain" kind (canonical approach)
      local grid = zone:makeEntityByName(level, "terrain", grid_info.id)
      
      if grid then
        -- Resolve grid if it has a resolve method
        if grid.resolve then
          grid:resolve()
        end
        
        -- Place the grid
        level.map(x, y, Map.TERRAIN, grid)
        placed_count = placed_count + 1
        
        -- Log successful placement
        print(string.format("[DCCB-Gallery] ✓ [%2d,%2d] %-20s | %-15s | %s", 
          x, y, grid_info.id, grid_info.category, grid_info.description))
      else
        -- Log skipped placement (grid not found)
        skipped_count = skipped_count + 1
        print(string.format("[DCCB-Gallery] ⊘ [%2d,%2d] %-20s | %-15s | SKIPPED (not found)", 
          x, y, grid_info.id, grid_info.category))
      end
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Palette generation complete")
    print("[DCCB-Gallery] Total attempted: " .. #grid_catalog)
    print("[DCCB-Gallery] Placed: " .. placed_count .. " | Skipped: " .. skipped_count)
    print("[DCCB-Gallery] ========================================")
  end,
}
