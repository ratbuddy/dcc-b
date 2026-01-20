-- /mod/tome_addon_harness/mod/dccb/logging.lua
-- Tiny defensive logging helper for ToME Addon Harness
-- Tries ToME logger first, falls back to print()

local hlog = {}

-- Check for ToME logger globals (unknown exact API - defensive check)
local tome_logger = nil

-- Try common ToME logging interfaces (defensive - don't assume)
if game and game.log then
  tome_logger = game.log
elseif _G.log then
  tome_logger = _G.log
end

-- Generic log function - tries ToME logger, falls back to print
local function log_message(level, ...)
  local args = {...}
  local message = table.concat(args, " ")
  local prefix = "[DCCB-Harness] " .. level .. ": "
  
  -- Try ToME logger if available
  if tome_logger then
    if type(tome_logger) == "function" then
      tome_logger(prefix .. message)
    elseif type(tome_logger) == "table" and tome_logger.log then
      tome_logger.log(prefix .. message)
    else
      -- Fallback to print
      print(prefix .. message)
    end
  else
    -- No ToME logger - use print
    print(prefix .. message)
  end
end

function hlog.info(...)
  log_message("INFO", ...)
end

function hlog.warn(...)
  log_message("WARN", ...)
end

function hlog.error(...)
  log_message("ERROR", ...)
end

return hlog
