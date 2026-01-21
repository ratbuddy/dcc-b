-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- DCCB Stub Start Zone - Minimal Custom Zone for Testing
-- Phase-2: Scaffolding task, no procedural generation yet
-- Virtual path: /data-dccb/zones/dccb-start/zone.lua

return {
  name = "DCCB Start",
  short_name = "dccb-start",
  level_range = {1, 1},
  max_level = 1,
  decay = {300, 800},
  width = 30,
  height = 30,
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  
  -- Use minimal procedural generator
  -- Simple single room with Roomer generator
  generator = {
    map = {
      class = "engine.generator.map.Roomer",
      nb_rooms = 1,
      rooms = {"simple"},
      lite_room_chance = 100,
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
        },
      },
    },
  },
}
