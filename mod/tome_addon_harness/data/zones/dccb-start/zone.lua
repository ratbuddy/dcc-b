-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- DCCB Stub Start Zone - Minimal Custom Zone for Testing
-- Phase-2: Scaffolding task, no procedural generation yet
-- Virtual path: /data-dccb/zones/dccb-start/zone.lua

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
  
  -- Debug logging on zone entry (one-time per level)
  on_enter = function(self, level)
    print(string.format("[DCCB-Zone] Entered zone '%s' level %d", self.short_name or "unknown", level or 0))
  end,
  
  -- Use minimal procedural generator
  -- Simple single room with Roomer generator
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
  
  -- No actors or objects for minimal scaffolding
  levels = {
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
  },
}
