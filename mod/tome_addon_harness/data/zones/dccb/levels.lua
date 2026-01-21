-- /mod/tome_addon_harness/data/zones/dccb_start/levels.lua
-- DCCB Stub Start Zone - Level Definitions
-- Phase-2: Minimal scaffolding, single level only

return {
  {
    -- Level 1: Single simple room
    generator = {
      map = {
        class = "engine.generator.map.Roomer",
        nb_rooms = 1,
        rooms = {"simple"},
        lite_room_chance = 100,
      },
    },
  },
}
