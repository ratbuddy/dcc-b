-- /mod/tome_addon_harness/hooks/dccb/load.lua
-- ToME Addon Hook Registration
-- This file is executed by ToME when the addon loads via short_name="dccb"
-- Using dofile with VFS paths instead of require for harness files

-- Load harness logger using dofile with VFS path
local hlog = dofile("/hooks/dccb/logging.lua")

hlog.info("========================================")
hlog.info("[DCCB] hooks/dccb/load.lua executed")
hlog.info("========================================")

-- Load the harness loader module using dofile with VFS path
local Loader = dofile("/hooks/dccb/loader.lua")

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
