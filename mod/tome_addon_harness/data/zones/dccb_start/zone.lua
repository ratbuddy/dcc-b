-- /mod/tome_addon_harness/data/zones/dccb_start/zone.lua
-- DCCB Stub Start Zone - Minimal Custom Zone for Testing
-- Phase-2: Scaffolding task, no procedural generation yet

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
  
  -- No random generation for now - we'll use a static map
  generator = {
    map = {
      class = "engine.generator.map.Static",
      map = "dccb_start_1",
    },
  },
  
  -- No actors or objects for minimal scaffolding
  levels = {
    [1] = {
      generator = {
        map = {
          class = "engine.generator.map.Static",
          map = "dccb_start_1",
        },
      },
    },
  },
  
  -- Safe spawn point (will be in the center of our static map)
  default_spawn_point = {15, 15},
}
