-- ToME4 DCCB addon - Zone Definition (Overload)
-- DCCB Stub Start Zone - Minimal Custom Zone for Testing
-- This file provides zone config at /data/zones/dccb-start/ path

local _M = {}

_M.name = "DCCB Start"
_M.short_name = "dccb-start"
_M.level_range = {1, 1}
_M.max_level = 1
_M.width = 30
_M.height = 30
_M.persistent = "zone"
_M.all_remembered = true
_M.all_lited = true
_M.no_level_connectivity = true

-- Debug logging on zone entry (dot-call signature)
function _M:on_enter(lev, old_lev, ...)
  print(string.format("[DCCB-Zone] Entered zone '%s' level %d", self.short_name or "unknown", lev or 0))
  
  -- Verify overload files exist
  if fs then
    print(string.format("[DCCB] exists global grids: %s", tostring(fs.exists("/data/zones/dccb-start/grids.lua"))))
    print(string.format("[DCCB] exists global npcs: %s", tostring(fs.exists("/data/zones/dccb-start/npcs.lua"))))
  end
end

-- Use minimal procedural generator
-- Simple single room with Roomer generator
_M.generator = {
  map = {
    class = "engine.generator.map.Roomer",
    nb_rooms = 1,
    rooms = {"simple"},
    lite_room_chance = 100,
    -- Terrain mappings as table format
    ['#'] = {"WALL"},
    ['.'] = {"FLOOR"},
    up = "UP",
    down = "DOWN",
    door = "DOOR",
  },
  -- Explicit zero spawn generators
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
}

-- No actors or objects for minimal scaffolding
_M.levels = {
  [1] = {
    generator = {
      map = {
        class = "engine.generator.map.Roomer",
        nb_rooms = 1,
        rooms = {"simple"},
        lite_room_chance = 100,
        -- Terrain mappings as table format
        ['#'] = {"WALL"},
        ['.'] = {"FLOOR"},
        up = "UP",
        down = "DOWN",
        door = "DOOR",
      },
      -- Explicit zero spawn generators
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
}

return _M
