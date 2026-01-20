-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hook Registration
-- Phase-2 Task 2.2.1: Register real ToME engine hook via class:bindHook
--
-- This file is executed by ToME when the addon loads. It registers
-- actual engine hooks using ToME's class:bindHook() API.

-------------------------------------------------------------------------------
-- Phase-2 Task 2.2.3: Compute addon_root and fix package.path deterministically
-------------------------------------------------------------------------------
if not _G.__DCCB_ADDON_PATH_PATCHED then
  _G.__DCCB_ADDON_PATH_PATCHED = true
  
  -- Get the path of this executing file
  local source = debug.getinfo(1, "S").source
  
  -- Strip leading @ if present
  if source and source:sub(1, 1) == "@" then
    source = source:sub(2)
  end
  
  -- Normalize backslashes to forward slashes
  if source then
    source = source:gsub("\\", "/")
  end
  
  -- Derive addon_root by removing trailing hooks/load.lua or hooks/dccb/load.lua
  local addon_root = nil
  if source then
    -- Try to match hooks/dccb/load.lua first, then hooks/load.lua
    -- pattern1: captures everything before <dir1>/<dir2>/load.lua (e.g., hooks/dccb/load.lua)
    -- pattern2: captures everything before <dir>/load.lua (e.g., hooks/load.lua)
    local pattern1 = "(.*/)[^/]*/[^/]*/load%.lua$"
    local pattern2 = "(.*/)[^/]*/load%.lua$"
    
    addon_root = source:match(pattern1) or source:match(pattern2)
  end
  
  if addon_root then
    -- Prepend deterministic patterns to package.path
    local patterns = {
      addon_root .. "?.lua",
      addon_root .. "?/init.lua",
      addon_root .. "?/?.lua",
      addon_root .. "mod/?.lua",
      addon_root .. "mod/?/init.lua",
      addon_root .. "mod/?/?.lua",
    }
    
    -- Prepend patterns (put them BEFORE existing package.path)
    local new_patterns = table.concat(patterns, ";")
    package.path = new_patterns .. ";" .. package.path
    
    -- Print one-time markers with [DCCB] prefix
    print("[DCCB] addon_root=" .. addon_root)
    
    -- Truncate package.path to ~200 chars for logging
    local path_preview = package.path
    if #path_preview > 200 then
      path_preview = path_preview:sub(1, 200) .. "..."
    end
    print("[DCCB] package.path=" .. path_preview)
  else
    -- Fail safe: addon_root could not be determined
    print("[DCCB] addon_root unresolved")
  end
end

-- Load harness logger
-- Note: Using addon-relative require paths
local hlog = require("dccb.logging")

hlog.info("========================================")
hlog.info("DCCB: hooks/load.lua executed (file loaded)")
hlog.info("========================================")
hlog.info("Registering ToME engine hooks via class:bindHook...")

-- Load the harness loader module
local Loader = require("dccb.loader")

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
