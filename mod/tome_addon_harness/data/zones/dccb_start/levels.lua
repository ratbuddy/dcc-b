-- /mod/tome_addon_harness/data/zones/dccb_start/levels.lua
-- DCCB Stub Start Zone - Level Definitions
-- Phase-2: Minimal scaffolding, single level only

return {
  {
    -- Level 1: Single static room
    generator = {
      map = {
        class = "engine.generator.map.Static",
        map = "dccb_start_1",
      },
    },
  },
}
