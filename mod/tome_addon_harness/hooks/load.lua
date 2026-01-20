-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hook Registration
-- Phase-2 Task 2.2.7: Align harness hook layout with real ToME addon convention
--
-- This file is executed by ToME when the addon loads. It registers
-- actual engine hooks using ToME's class:bindHook() API.

-- Load harness logger
local hlog = require("mod.dccb.logging")

hlog.info("========================================")
hlog.info("[DCCB] hooks/load.lua executed")
hlog.info("========================================")

-- Load the harness loader module
local Loader = require("mod.dccb.loader")

-- DEV_AUTORUN: set to false for production (ToME will trigger via hooks)
local dev_autorun = false

-------------------------------------------------------------------------------
-- Register ToME:load hook (real engine hook)
-------------------------------------------------------------------------------
class:bindHook("ToME:load", function(self, data)
  hlog.info("========================================")
  hlog.info("[DCCB] FIRED: ToME:load")
  hlog.info("========================================")
  
  -- Run the harness loader inside the hook callback
  local success, ok, Hooks = pcall(Loader.run, dev_autorun)
  
  if success then
    -- pcall succeeded, check Loader.run result
    if ok then
      hlog.info("Harness loader completed successfully")
      -- Store Hooks module in global for access if needed
      _G.DCCB_HOOKS = Hooks
    else
      hlog.error("Harness loader failed - check logs above")
    end
  else
    -- pcall itself failed
    hlog.error("Error running harness loader:")
    hlog.error(tostring(ok))  -- ok contains the error message when pcall fails
  end
  
  hlog.info("========================================")
  hlog.info("ToME:load hook callback complete")
  hlog.info("========================================")
end)

hlog.info("ToME engine hook registered: ToME:load")
hlog.info("========================================")
