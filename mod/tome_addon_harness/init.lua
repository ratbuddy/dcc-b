-- /mod/tome_addon_harness/init.lua
-- ToME Addon Harness for DCCB Integration
-- Phase-2 Task 2.2: Descriptor-style entry point
--
-- This file serves as the addon descriptor/metadata entry point.
-- The actual runtime loader logic has been moved to loader.lua and
-- is invoked via hooks/load.lua when ToME's addon system loads the addon.
--
-- This follows the ToME addon pattern:
--   init.lua (descriptor) → hooks/load.lua (entrypoint) → loader.lua (runtime)

-- Load harness logger for basic logging
local hlog = require("mod.tome_addon_harness.logging")

-- Developer toggle: set to true to auto-run DCCB systems on load (for testing)
-- WARNING: Normally this should be false - ToME will trigger on_run_start via hooks
local DEV_AUTORUN = false

-- Store DEV_AUTORUN in global so hooks/load.lua can access it
_G.DCCB_HARNESS_DEV_AUTORUN = DEV_AUTORUN

hlog.info("========================================")
hlog.info("DCCB ToME Addon Descriptor: init.lua")
hlog.info("========================================")
hlog.info("Version: 0.2 (Phase-2 Task 2.2)")
hlog.info("Hooks enabled: true")
hlog.info("DEV_AUTORUN:", DEV_AUTORUN)
hlog.info("Waiting for ToME to trigger hooks/load.lua...")

-- Return addon descriptor (ToME convention)
-- This metadata describes the addon to ToME's addon system
return {
  name = "DCCB ToME Addon Harness",
  version = "0.2",
  description = "Dungeon Crawler Challenge Broadcast integration for Tales of Maj'Eyal",
  author = "DCCB Project",
  hooks_enabled = true,
  dev_autorun = DEV_AUTORUN
}
