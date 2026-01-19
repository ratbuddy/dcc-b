-- /mod/tome_addon_harness/init.lua
-- ToME Addon Harness for DCCB Integration
-- Phase-2 Task 2.1: Minimal harness to load DCCB in ToME environment
--
-- This file is the entrypoint for the ToME addon.
-- It safely loads DCCB integration hooks and provides developer toggles.

-- Developer toggle: set to true to auto-run DCCB systems on load (for testing)
-- WARNING: Normally this should be false - ToME will trigger on_run_start via hooks
local DEV_AUTORUN = false

-- Load harness logger (safe logging helper)
local hlog = require("mod.tome_addon_harness.logging")

hlog.info("========================================")
hlog.info("DCCB ToME Harness loaded")
hlog.info("========================================")
hlog.info("Version: 0.1 (Phase-2 Task 2.1)")
hlog.info("DEV_AUTORUN:", DEV_AUTORUN)

-- Step 1: Safely require DCCB integration hooks
local Hooks = nil
local hooks_ok, hooks_result = pcall(function()
  return require("mod.dccb.integration.tome_hooks")
end)

if not hooks_ok then
  hlog.error("Failed to load DCCB integration hooks:")
  hlog.error(tostring(hooks_result))
  hlog.error("Harness load aborted - DCCB integration unavailable")
  return
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
  return
end

hlog.info("DCCB hooks installed successfully")

-- Step 3: If DEV_AUTORUN is enabled, manually trigger on_run_start
if DEV_AUTORUN then
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
hlog.info("DCCB ToME Harness initialization complete")
hlog.info("========================================")

-- Return module table (ToME convention - may be unused)
return {
  name = "DCCB ToME Addon Harness",
  version = "0.1",
  hooks = Hooks
}
