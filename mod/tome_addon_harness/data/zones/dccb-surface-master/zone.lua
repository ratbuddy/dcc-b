-- /data/zones/dccb-surface-master/zone.lua
-- DCCB Surface Master Zone - Canonical Surface Generator Showcase
-- Virtual path: /data-dccb/zones/dccb-surface-master/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-surface-master/ (overload)

-- Template selection: Fixed to "plains" for deterministic demo mode
-- This showcases the surface painter/template system in a predictable way
local DCCB_SURFACE_TEMPLATE = "plains"

-- Template registry: available templates for reference
local DCCB_TEMPLATES = {"plains", "road", "courtyard"}

return {
  name = "DCCB Surface Master",
  short_name = "dccb-surface-master",
  level_range = {1, 1},
  max_level = 1,
  width = 30,
  height = 30,
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  no_level_connectivity = true,
  
  -- Explicit zone entity loads (ensures grids/npcs/objects/traps are registered)
  load = {
    "/data/zones/dccb-surface-master/grids.lua",
    "/data/zones/dccb-surface-master/npcs.lua",
    "/data/zones/dccb-surface-master/objects.lua",
    "/data/zones/dccb-surface-master/traps.lua",
  },
  
  -- Debug logging on zone entry
  on_enter = function(a,b,...)
    local zone, lev
    if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
    local zname = (zone and zone.short_name) or "unknown"
    print(string.format("[DCCB-SurfaceMaster] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  end,
  
  -- Post-process: use surface template painter for deterministic layout
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
      print("[DCCB-SurfaceMaster] ERROR: Cannot detect level object (no .map found)")
      return
    end
    
    if not zone or not (zone.makeEntityByName or zone.makeEntity) then
      print("[DCCB-SurfaceMaster] ERROR: Cannot detect zone object (no .makeEntityByName/.makeEntity found)")
      return
    end
    
    -- Load painter module
    local painter_ok, painter = pcall(function()
      return loadfile("/data-dccb/dccb/surface/painter.lua")()
    end)
    
    if not painter_ok or not painter then
      print("[DCCB-SurfaceMaster] ERROR: Failed to load painter module")
      print(string.format("[DCCB-SurfaceMaster] Error: %s", tostring(painter)))
      
      -- Safe fallback: verify we have the required capabilities
      if not zone.makeEntityByName then
        print("[DCCB-SurfaceMaster] ERROR: Cannot fallback - zone.makeEntityByName unavailable")
        return
      end
      
      if not level.map then
        print("[DCCB-SurfaceMaster] ERROR: Cannot fallback - level.map unavailable")
        return
      end
      
      -- Use level.map dimensions (source of truth)
      local map_w = level.map.w
      local map_h = level.map.h
      
      -- Minimal fallback: fill with GRASS and place 1 entrance
      for x = 0, map_w - 1 do
        for y = 0, map_h - 1 do
          local grid = zone:makeEntityByName(level, "grid", "GRASS")
          if grid then
            level.map(x, y, Map.TERRAIN, grid)
          end
        end
      end
      
      -- Place one entrance in center
      local e_x = math.floor(map_w / 2)
      local e_y = math.floor(map_h / 2)
      local entrance_grid = zone:makeEntityByName(level, "grid", "DCCB_ENTRANCE")
      if entrance_grid then
        level.map(e_x, e_y, Map.TERRAIN, entrance_grid)
      end
      
      print("[DCCB-SurfaceMaster] Fallback surface generated (painter unavailable)")
      return
    end
    
    -- Deterministic template selection: use the fixed template name
    local selected_template_name = DCCB_SURFACE_TEMPLATE
    local template_list = table.concat(DCCB_TEMPLATES, ",")
    print(string.format("[DCCB-SurfaceMaster] Template fixed: %s (available templates=%s)", 
      selected_template_name, template_list))
    
    -- Load selected template
    local template_path = string.format("/data-dccb/dccb/surface/templates/%s.lua", selected_template_name)
    local template_ok, template = pcall(function()
      return loadfile(template_path)()
    end)
    
    if not template_ok or not template then
      print(string.format("[DCCB-SurfaceMaster] WARNING: Failed to load template '%s'", selected_template_name))
      print(string.format("[DCCB-SurfaceMaster] Error: %s", tostring(template)))
      
      -- Use inline fallback template
      template = {
        name = "fallback",
        base = "GRASS",
        entrances = {count = 1, grid = "DCCB_ENTRANCE"}
      }
      print("[DCCB-SurfaceMaster] Using inline fallback template")
      selected_template_name = "fallback"
    else
      print(string.format("[DCCB-SurfaceMaster] Loaded template '%s'", selected_template_name))
    end
    
    -- Paint the surface using the template
    local success = painter.paint_surface(level, zone, template)
    
    if not success then
      print("[DCCB-SurfaceMaster] WARNING: Surface painting failed")
    end
    
    print(string.format("[DCCB-SurfaceMaster] Surface template '%s' applied", template.name or "unknown"))
  end,
  
  -- Single stable generator: Empty (no Roomer, no intra-zone stairs)
  generator = {
    map = {
      class = "engine.generator.map.Empty",
      zoom = 1,
      -- NO up/down/door mappings - prevents intra-zone stair generation
    },
    -- Zero spawns
    actor = {
      class = "engine.generator.actor.Random",
      nb_npc = {0, 0},
    },
    object = {
      class = "engine.generator.object.Random",
      nb_object = {0, 0},
    },
    trap = {
      class = "engine.generator.trap.Random",
      nb_trap = {0, 0},
    },
  },
}
