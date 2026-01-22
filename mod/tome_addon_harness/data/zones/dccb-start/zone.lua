-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- DCCB Stub Start Zone - Surface Template System
-- Virtual path: /data-dccb/zones/dccb-start/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-start/ (overload)

-- Template selection (deterministic for now, can be randomized later)
local DCCB_SURFACE_TEMPLATE = "plains"  -- Options: "plains", "road"

return {
  name = "DCCB Start",
  short_name = "dccb-start",
  level_range = {1, 1},
  max_level = 1,
  width = 30,
  height = 30,
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  no_level_connectivity = true,
  
  -- Debug logging on zone entry
  on_enter = function(a,b,...)
    local zone, lev
    if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
    local zname = (zone and zone.short_name) or "unknown"
    print(string.format("[DCCB-Zone] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  end,
  
  -- Post-process: use surface template painter for deterministic layout
  post_process = function(a, b, c, ...)
    local Map = require "engine.Map"
    
    -- Signature-agnostic: detect level argument
    local level, zone
    if type(a) == "table" and a.map then
      level = a
      zone = level.zone or b
    elseif type(b) == "table" and b.map then
      level = b
      zone = level.zone or a
    else
      level = a
      zone = level and level.zone
    end
    
    -- Fallback dimensions if zone is nil
    if not zone then
      zone = {width = 30, height = 30, short_name = "dccb-start"}
    end
    
    -- Load painter module
    local painter_ok, painter = pcall(function()
      return loadfile("/data-dccb/dccb/surface/painter.lua")()
    end)
    
    if not painter_ok or not painter then
      print("[DCCB-Zone] ERROR: Failed to load painter module")
      print(string.format("[DCCB-Zone] Error: %s", tostring(painter)))
      -- Fall back to minimal inline implementation
      local fallback_template = {
        name = "fallback",
        base = "GRASS",
        entrances = {count = 1, grid = "DCCB_ENTRANCE"}
      }
      
      -- Minimal fallback: just fill with grass
      for x = 0, zone.width - 1 do
        for y = 0, zone.height - 1 do
          local grid = zone:makeEntityByName(level, "grid", "GRASS")
          if grid then
            level.map(x, y, Map.TERRAIN, grid)
          end
        end
      end
      
      -- Place one entrance
      local e_x = math.floor(zone.width / 2)
      local e_y = math.floor(zone.height / 2)
      local entrance_grid = zone:makeEntityByName(level, "grid", "DCCB_ENTRANCE")
      if entrance_grid then
        level.map(e_x, e_y, Map.TERRAIN, entrance_grid)
      end
      
      print("[DCCB-Zone] Fallback surface generated (painter unavailable)")
      return
    end
    
    -- Load selected template
    local template_path = string.format("/data-dccb/dccb/surface/templates/%s.lua", DCCB_SURFACE_TEMPLATE)
    local template_ok, template = pcall(function()
      return loadfile(template_path)()
    end)
    
    if not template_ok or not template then
      print(string.format("[DCCB-Zone] WARNING: Failed to load template '%s'", DCCB_SURFACE_TEMPLATE))
      print(string.format("[DCCB-Zone] Error: %s", tostring(template)))
      -- Use fallback template
      template = {
        name = "fallback",
        base = "GRASS",
        entrances = {count = 1, grid = "DCCB_ENTRANCE"}
      }
      print("[DCCB-Zone] Using fallback template")
    else
      print(string.format("[DCCB-Zone] Loaded template '%s'", DCCB_SURFACE_TEMPLATE))
    end
    
    -- Paint the surface using the template
    local success = painter.paint_surface(level, zone, template)
    
    if not success then
      print("[DCCB-Zone] WARNING: Surface painting failed")
    end
    
    print(string.format("[DCCB-Zone] Surface template '%s' applied", template.name or "unknown"))
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
  
  -- Level 1 configuration
  levels = {
    [1] = {
      generator = {
        map = {
          class = "engine.generator.map.Empty",
          zoom = 1,
        },
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
    },
  },
}
