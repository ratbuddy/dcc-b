-- /mod/tome_addon_harness/hooks/dccb/load.lua
-- ToME Addon Hook Registration
-- Phase-2 Task 2.2.4: Absolute addon_root package.path patch
--
-- This file is executed by ToME when the addon loads. It registers
-- actual engine hooks using ToME's class:bindHook() API.

-------------------------------------------------------------------------------
-- Phase-2 Task 2.2.4: Compute absolute addon_root and fix package.path
-------------------------------------------------------------------------------
-- Get the path of this executing file
local info = debug.getinfo(1, "S")
local src = info and info.source or ""
if src:sub(1, 1) == "@" then
  src = src:sub(2)
end
src = src:gsub("\\", "/")

-- Derive addon_root by stripping known suffixes
local addon_root = nil
local function strip_suffix(path, suffix)
  if path:sub(-#suffix) == suffix then
    return path:sub(1, #path - #suffix)
  end
  return nil
end

addon_root = strip_suffix(src, "/hooks/dccb/load.lua") or strip_suffix(src, "/hooks/load.lua")

-- Ensure addon_root ends with /
if addon_root and addon_root ~= "" and addon_root:sub(-1) ~= "/" then
  addon_root = addon_root .. "/"
end

if addon_root then
  -- Prepend absolute patterns
  local extra =
    addon_root .. "?.lua;" ..
    addon_root .. "?/init.lua;" ..
    addon_root .. "?/?.lua;" ..
    addon_root .. "mod/?.lua;" ..
    addon_root .. "mod/?/init.lua;" ..
    addon_root .. "mod/?/?.lua;"
  
  package.path = extra .. package.path
  
  -- Add one-time prints guarded by global
  if not _G.__DCCB_ADDON_PATH_PATCHED then
    _G.__DCCB_ADDON_PATH_PATCHED = true
    print("[DCCB] hook src=" .. tostring(src))
    print("[DCCB] addon_root=" .. tostring(addon_root))
    print("[DCCB] package.path(head)=" .. package.path:sub(1, 200))
  end
else
  -- Fail safe: addon_root could not be resolved
  print("[DCCB] addon_root unresolved; src=" .. tostring(src))
end

-- Load harness logger
-- Note: Using addon-relative require paths with mod namespace
local hlog = require("mod.dccb.logging")

hlog.info("========================================")
hlog.info("DCCB: hooks/dccb/load.lua executed (file loaded)")
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
