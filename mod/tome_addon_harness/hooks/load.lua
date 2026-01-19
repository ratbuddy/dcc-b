-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hook Registration
-- Phase-2 Task 2.2.1: Register real ToME engine hook via class:bindHook
--
-- This file is executed by ToME when the addon loads. It registers
-- actual engine hooks using ToME's class:bindHook() API.

-- Load harness logger
-- Note: require paths follow ToME module search paths
local hlog = require("mod.dccb.logging")

hlog.info("========================================")
hlog.info("DCCB: hooks/load.lua executed (file loaded)")
hlog.info("========================================")
hlog.info("Registering ToME engine hooks via class:bindHook...")

-- Load the harness loader module
local Loader = require("mod.dccb.loader")

-- DEV_AUTORUN: set to false for production (ToME will trigger via hooks)
-- This is no longer read from init.lua to keep init.lua descriptor-only
local dev_autorun = false

-------------------------------------------------------------------------------
-- Register ToME:load hook (first verified engine hook)
-- This is a real ToME engine hook that fires during addon loading
-------------------------------------------------------------------------------
class:bindHook("ToME:load", function(self, data)
  hlog.info("========================================")
  hlog.info("FIRED: ToME:load (REAL ENGINE HOOK)")
  hlog.info("========================================")
  hlog.info("Hook data received:", data and type(data) or "nil")
  
  -- Log hook signature details
  if data then
    hlog.info("Hook payload type:", type(data))
    if type(data) == "table" then
      local keys = {}
      for k, _ in pairs(data) do
        table.insert(keys, k)
      end
      if #keys > 0 then
        hlog.info("Hook payload keys:", table.concat(keys, ", "))
      else
        hlog.info("Hook payload: empty table")
      end
    end
  end
  
  hlog.info("This is a VERIFIED ToME engine hook callback")
  hlog.info("========================================")
  
  -- Run the harness loader inside the hook callback
  hlog.info("Executing harness loader from ToME:load hook...")
  local success, Hooks = Loader.run(dev_autorun)
  
  if success then
    hlog.info("Harness loader completed successfully")
    -- Store Hooks module in global for access if needed
    _G.DCCB_HOOKS = Hooks
  else
    hlog.error("Harness loader failed - check logs above")
  end
  
  hlog.info("========================================")
  hlog.info("ToME:load hook callback complete")
  hlog.info("========================================")
end)

hlog.info("ToME engine hook registered: ToME:load")
hlog.info("Waiting for ToME engine to fire the hook...")
hlog.info("========================================")
