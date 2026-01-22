-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- DCCB Stub Start Zone - Stable Surface Generator
-- Virtual path: /data-dccb/zones/dccb-start/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-start/ (overload)

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
  
  -- Post-process: fill with grass and place 1-2 inert entrance markers
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
    
    -- Fill entire map with GRASS
    for x = 0, zone.width - 1 do
      for y = 0, zone.height - 1 do
        Map:addGrid(level, x, y, "GRASS")
      end
    end
    
    -- Scatter some trees for outdoor look (simple stable pattern, no randomization)
    -- Place trees in a predictable pattern around the edges
    for x = 0, zone.width - 1 do
      for y = 0, zone.height - 1 do
        -- Place trees near edges to create border
        if x < 3 or x >= zone.width - 3 or y < 3 or y >= zone.height - 3 then
          if (x + y) % 3 == 0 then -- predictable pattern
            Map:addGrid(level, x, y, "TREE")
          end
        end
      end
    end
    
    -- Place 1-2 inert DCCB_ENTRANCE markers in fixed positions for stability
    -- Position 1: center-left
    local e1_x = math.floor(zone.width / 3)
    local e1_y = math.floor(zone.height / 2)
    Map:addGrid(level, e1_x, e1_y, "DCCB_ENTRANCE")
    
    -- Position 2: center-right
    local e2_x = math.floor(zone.width * 2 / 3)
    local e2_y = math.floor(zone.height / 2)
    Map:addGrid(level, e2_x, e2_y, "DCCB_ENTRANCE")
    
    print("[DCCB-Surface] Stable surface generated with 2 entrance markers")
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
