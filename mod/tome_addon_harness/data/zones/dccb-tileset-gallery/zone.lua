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
    
    -- Define grid catalog to display
    local grid_catalog = {
      -- Base game grids (from /data/general/grids/basic.lua)
      {id = "FLOOR", category = "Base Game", description = "Standard floor tile"},
      {id = "WALL", category = "Base Game", description = "Standard wall tile"},
      
      -- DCCB Green/Plains theme
      {id = "GRASS", category = "Green Theme", description = "Grass (explicit tileset)"},
      {id = "ROAD", category = "Green Theme", description = "Dirt road (explicit tileset)"},
      {id = "TREE", category = "Green Theme", description = "Tree (explicit tileset)"},
      
      -- DCCB Winter/Snow theme
      {id = "GRASS_WINTER", category = "Winter Theme", description = "Snowy ground (inherited)"},
      {id = "ROAD_WINTER", category = "Winter Theme", description = "Icy path (inherited)"},
      {id = "TREE_WINTER", category = "Winter Theme", description = "Snowy tree (inherited)"},
      
      -- DCCB Ruins/Ancient theme
      {id = "GRASS_RUINS", category = "Ruins Theme", description = "Overgrown ground (inherited)"},
      {id = "ROAD_RUINS", category = "Ruins Theme", description = "Ancient path (inherited)"},
      {id = "TREE_RUINS", category = "Ruins Theme", description = "Ruined pillar (inherited)"},
      
      -- DCCB Special
      {id = "DCCB_ENTRANCE", category = "Special", description = "Dungeon entrance marker"},
    }
    
    -- Layout configuration
    local start_x = 5
    local start_y = 5
    local grid_spacing = 4  -- Space between grid samples
    local grids_per_row = 5
    
    print(string.format("[DCCB-Gallery] Placing %d grids in palette", #grid_catalog))
    print("[DCCB-Gallery] Layout: " .. grids_per_row .. " grids per row, spacing=" .. grid_spacing)
    
    -- Place each grid in the catalog
    for idx, grid_info in ipairs(grid_catalog) do
      local row = math.floor((idx - 1) / grids_per_row)
      local col = (idx - 1) % grids_per_row
      
      local x = start_x + (col * grid_spacing)
      local y = start_y + (row * grid_spacing)
      
      -- Try to make the grid entity
      local grid = zone:makeEntityByName(level, "grid", grid_info.id)
      
      if grid then
        -- Resolve grid if it has a resolve method
        if grid.resolve then
          grid:resolve()
        end
        
        -- Place the grid
        level.map(x, y, Map.TERRAIN, grid)
        
        -- Log successful placement
        print(string.format("[DCCB-Gallery] ✓ [%2d,%2d] %-15s | %s | %s", 
          x, y, grid_info.id, grid_info.category, grid_info.description))
      else
        -- Log failed placement (grid not found)
        print(string.format("[DCCB-Gallery] ✗ [%2d,%2d] %-15s | %s | NOT FOUND", 
          x, y, grid_info.id, grid_info.category))
      end
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Palette generation complete")
    print("[DCCB-Gallery] Total grids attempted: " .. #grid_catalog)
    print("[DCCB-Gallery] ========================================")
  end,
}
