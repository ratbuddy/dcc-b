-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hook Entrypoint
-- Phase-2 Task 2.2: First verified ToME hook - addon load lifecycle
--
-- This file is the actual ToME hook entrypoint. ToME's addon system
-- will execute this file when the addon loads, proving that we can
-- register and observe a ToME engine callback firing.
--
-- This hook represents the "addon load" lifecycle event - the safest
-- and earliest hook point for proving ToME integration works.

-- Load harness logger
local hlog = require("mod.tome_addon_harness.logging")

hlog.info("========================================")
hlog.info("DCCB ToME Hook Fired: ADDON_LOAD")
hlog.info("========================================")
hlog.info("DCCB ToME Harness: hooks/load.lua fired")
hlog.info("This confirms ToME addon hook registration works")

-- Load and run the harness loader
local Loader = require("mod.tome_addon_harness.loader")

-- Check for DEV_AUTORUN setting from init.lua
-- (passed via global if init.lua was executed first, otherwise default to false)
local dev_autorun = _G.DCCB_HARNESS_DEV_AUTORUN or false

local success, Hooks = Loader.run(dev_autorun)

if success then
  hlog.info("========================================")
  hlog.info("DCCB ToME Harness: Hook entrypoint complete")
  hlog.info("========================================")
  
  -- Store Hooks module in global for access if needed
  _G.DCCB_HOOKS = Hooks
else
  hlog.error("========================================")
  hlog.error("DCCB ToME Harness: Hook entrypoint failed")
  hlog.error("========================================")
end

-- Return success status
return success
