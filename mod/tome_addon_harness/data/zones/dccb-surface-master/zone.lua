-- /data/zones/dccb-surface-master/zone.lua
-- DCCB Surface Master Zone - Canonical Surface Generator Showcase
-- Virtual path: /data-dccb/zones/dccb-surface-master/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-surface-master/ (overload)

-- Template selection: nil for auto-select (using seed), or a string to override
-- Debug override: set to "plains", "road", "courtyard", "winter", "winter_road", or "ruins" to force a specific template
local DCCB_SURFACE_TEMPLATE = nil  -- Changed from "plains" to nil for auto-selection

-- Template registry: available templates for auto-selection
-- Themed templates: plains/road/courtyard (green), winter/winter_road (snowy), ruins (ancient)
local DCCB_TEMPLATES = {"plains", "road", "courtyard", "winter", "winter_road", "ruins"}

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
    
    -- Determine which template to use
    local selected_template_name
    
    if type(DCCB_SURFACE_TEMPLATE) == "string" then
      -- Override mode: use the specified template
      selected_template_name = DCCB_SURFACE_TEMPLATE
      local template_list = table.concat(DCCB_TEMPLATES, ",")
      print(string.format("[DCCB-SurfaceMaster] Template override: %s (templates=%s)", 
        selected_template_name, template_list))
    else
      -- Auto-selection mode: pick based on seed
      local seed
      local seed_source
      
      -- Try to get a stable seed in order of preference
      if game and type(game.run_seed) == "number" and game.run_seed > 0 then
        seed = game.run_seed
        seed_source = "game.run_seed"
      elseif game and game._DCCB_RUN_SEED and type(game._DCCB_RUN_SEED) == "number" then
        -- Reuse cached seed from earlier in this run
        seed = game._DCCB_RUN_SEED
        seed_source = "game._DCCB_RUN_SEED (cached)"
      elseif game and game.start_time and type(game.start_time) == "number" and game.start_time > 0 then
        seed = game.start_time
        seed_source = "game.start_time"
      elseif game and game.real_start_time and type(game.real_start_time) == "number" and game.real_start_time > 0 then
        seed = game.real_start_time
        seed_source = "game.real_start_time"
      elseif game and game.date and type(game.date) == "number" and game.date > 0 then
        seed = game.date
        seed_source = "game.date"
      elseif game and game.calendar and type(game.calendar) == "number" and game.calendar > 0 then
        seed = game.calendar
        seed_source = "game.calendar"
      elseif game and tostring(game):match("0x(%x+)") then
        -- Try to extract memory address as a seed
        local game_str = tostring(game)
        local addr_str = game_str:match("0x(%x+)")
        local addr_num = tonumber(addr_str, 16)
        if addr_num and addr_num > 0 then
          seed = addr_num
          seed_source = "game object address"
        else
          seed = os.time()
          seed_source = "os.time() [FALLBACK]"
        end
      else
        seed = os.time()
        seed_source = "os.time() [FALLBACK]"
      end
      
      -- Normalize seed to integer >= 1
      seed = math.floor(tonumber(seed) or 0)
      if seed < 1 then
        seed = 1
      end
      
      -- Cache seed for this run if game object exists and we computed it fresh
      if game and not game._DCCB_RUN_SEED and seed_source ~= "game._DCCB_RUN_SEED (cached)" then
        game._DCCB_RUN_SEED = seed
      end
      
      -- Select template using modulo
      local index = (seed % #DCCB_TEMPLATES) + 1
      selected_template_name = DCCB_TEMPLATES[index]
      
      local template_list = table.concat(DCCB_TEMPLATES, ",")
      print(string.format("[DCCB-SurfaceMaster] Template auto-selected: %s (seed=%d from %s, idx=%d/%d, templates=%s)", 
        selected_template_name, seed, seed_source, index, #DCCB_TEMPLATES, template_list))
    end
    
    -- Load selected template
    local template_path = string.format("/data-dccb/dccb/surface/templates/%s.lua", selected_template_name)
    local template_ok, template = pcall(function()
      return loadfile(template_path)()
    end)
    
    if not template_ok or not template then
      print(string.format("[DCCB-SurfaceMaster] WARNING: Failed to load template '%s'", selected_template_name))
      print(string.format("[DCCB-SurfaceMaster] Error: %s", tostring(template)))
      
      -- Try fallback to "plains" if we didn't already try it
      if selected_template_name ~= "plains" then
        print("[DCCB-SurfaceMaster] Attempting fallback to 'plains' template")
        template_ok, template = pcall(function()
          return loadfile("/data-dccb/dccb/surface/templates/plains.lua")()
        end)
        
        if template_ok and template then
          print("[DCCB-SurfaceMaster] Successfully loaded 'plains' fallback template")
          selected_template_name = "plains"
        end
      end
      
      -- If still failed, use inline fallback template
      if not template_ok or not template then
        template = {
          name = "fallback",
          base = "GRASS",
          entrances = {count = 1, grid = "DCCB_ENTRANCE"}
        }
        print("[DCCB-SurfaceMaster] Using inline fallback template")
        selected_template_name = "fallback"
      end
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
