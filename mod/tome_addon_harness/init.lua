-- /mod/tome_addon_harness/init.lua
-- ToME Addon Harness for DCCB Integration
-- Phase-2 Task 2.2.1: Real ToME addon descriptor with proper metadata
--
-- This file is a legitimate ToME addon descriptor that follows ToME's
-- addon conventions. It provides metadata and enables hooks that will
-- be registered via hooks/load.lua using class:bindHook().

-- Load harness logger for basic logging
local hlog = require("mod.tome_addon_harness.logging")

-- Developer toggle: set to true to auto-run DCCB systems on load (for testing)
-- WARNING: Normally this should be false - ToME will trigger on_run_start via hooks
local DEV_AUTORUN = false

-- Addon metadata constants
local ADDON_VERSION = "0.2.1"
local ADDON_PHASE = "Phase-2 Task 2.2.1"

-- Store DEV_AUTORUN in global so hooks/load.lua can access it
_G.DCCB_HARNESS_DEV_AUTORUN = DEV_AUTORUN

hlog.info("========================================")
hlog.info("DCCB ToME Addon Descriptor: init.lua")
hlog.info("========================================")
hlog.info("Version:", ADDON_VERSION, "(" .. ADDON_PHASE .. ")")
hlog.info("Hooks enabled: true")
hlog.info("DEV_AUTORUN:", DEV_AUTORUN)
hlog.info("Waiting for ToME engine to fire hooks...")

-- Return ToME addon descriptor with required fields
-- This follows ToME's addon metadata conventions
return {
  -- Required ToME addon descriptor fields
  long_name = "Dungeon Crawler Challenge Broadcast - ToME Integration",
  short_name = "dccb-tome-harness",
  for_module = "tome",
  version = {1, 0, 0},
  addon_version = ADDON_VERSION,
  weight = 100,
  author = {"DCCB Project"},
  homepage = "https://github.com/ratbuddy/dcc-b",
  description = [[Dungeon Crawler Challenge Broadcast integration for Tales of Maj'Eyal.
This addon integrates the DCCB procedural generation and meta-layer systems
with ToME's dungeon generation and gameplay mechanics.]],
  tags = {"dungeon", "procedural", "integration"},
  
  -- Enable hooks system
  hooks = true,
  
  -- Custom metadata for DCCB
  dccb_dev_autorun = DEV_AUTORUN
}
