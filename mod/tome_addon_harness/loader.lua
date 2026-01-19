-- /mod/tome_addon_harness/loader.lua
-- ToME Addon Harness - Runtime Loader Logic
-- Phase-2 Task 2.2: Extracted from init.lua to separate descriptor from runtime
--
-- This file contains the actual harness loading logic that was previously
-- in init.lua. It is now called from hooks/load.lua at the appropriate time
-- in ToME's addon lifecycle.

-- Load harness logger (safe logging helper)
local hlog = require("mod.tome_addon_harness.logging")

local Loader = {}

-------------------------------------------------------------------------------
-- Loader.run()
-- Main harness loader - loads DCCB integration and installs hooks
-- Returns: success (boolean), Hooks module (or nil on failure)
-------------------------------------------------------------------------------
function Loader.run(dev_autorun)
  dev_autorun = dev_autorun or false
  
  hlog.info("========================================")
  hlog.info("DCCB ToME Harness: Loader starting")
  hlog.info("========================================")
  hlog.info("DEV_AUTORUN:", dev_autorun)
  
  -- Step 1: Safely require DCCB integration hooks
  local Hooks = nil
  local hooks_ok, hooks_result = pcall(function()
    return require("mod.dccb.integration.tome_hooks")
  end)
  
  if not hooks_ok then
    hlog.error("Failed to load DCCB integration hooks:")
    hlog.error(tostring(hooks_result))
    hlog.error("Harness load aborted - DCCB integration unavailable")
    return false, nil
  end
  
  Hooks = hooks_result
  hlog.info("DCCB integration hooks loaded successfully")
  
  -- Step 2: Call Hooks.install() inside pcall
  local install_ok, install_err = pcall(function()
    Hooks.install()
  end)
  
  if not install_ok then
    hlog.error("Failed to install DCCB hooks:")
    hlog.error(tostring(install_err))
    hlog.error("Harness load completed with errors")
    return false, Hooks
  end
  
  hlog.info("DCCB hooks installed successfully")
  
  -- Step 3: If DEV_AUTORUN is enabled, manually trigger on_run_start
  if dev_autorun then
    hlog.warn("========================================")
    hlog.warn("DEV_AUTORUN enabled - manually starting DCCB")
    hlog.warn("========================================")
    
    local run_ok, run_err = pcall(function()
      Hooks.on_run_start({
        source = "dev_autorun",
        seed = os.time()
      })
    end)
    
    if not run_ok then
      hlog.error("Failed to run DCCB on_run_start:")
      hlog.error(tostring(run_err))
      hlog.error("DEV_AUTORUN failed - check logs above")
    else
      hlog.info("DEV_AUTORUN completed successfully")
    end
  end
  
  hlog.info("========================================")
  hlog.info("DCCB ToME Harness: Loader complete")
  hlog.info("========================================")
  
  return true, Hooks
end

return Loader
