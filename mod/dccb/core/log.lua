-- /mod/dccb/core/log.lua
-- Centralized logging system for DCC-Barony mod
-- Provides level-based logging with consistent prefixes
-- No engine calls - only uses print/stdio

local log = {}

-- Log levels (higher number = more verbose)
local LEVELS = {
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  DEBUG = 4
}

-- Current active log level (default to INFO)
local current_level = LEVELS.INFO

-- Set the current logging level
-- @param level string - one of "ERROR", "WARN", "INFO", "DEBUG"
function log.set_level(level)
  local level_upper = string.upper(level)
  if LEVELS[level_upper] then
    current_level = LEVELS[level_upper]
  else
    print("[DCCB][WARN] Unknown log level: " .. tostring(level))
  end
end

-- Get the current logging level
-- @return string - current level name
function log.get_level()
  for name, value in pairs(LEVELS) do
    if value == current_level then
      return name
    end
  end
  return "INFO"
end

-- Internal: format and print a log message
-- @param level_name string - the level name for the prefix
-- @param level_value number - the numeric level value
-- @param ... - message parts to concatenate
local function log_message(level_name, level_value, ...)
  if level_value <= current_level then
    local parts = {...}
    local message = ""
    for i, part in ipairs(parts) do
      if i > 1 then
        message = message .. " "
      end
      message = message .. tostring(part)
    end
    print("[DCCB][" .. level_name .. "] " .. message)
  end
end

-- Log an ERROR message (always shown unless level < ERROR)
function log.error(...)
  log_message("ERROR", LEVELS.ERROR, ...)
end

-- Log a WARN message (shown if level >= WARN)
function log.warn(...)
  log_message("WARN", LEVELS.WARN, ...)
end

-- Log an INFO message (shown if level >= INFO)
function log.info(...)
  log_message("INFO", LEVELS.INFO, ...)
end

-- Log a DEBUG message (shown only if level == DEBUG)
function log.debug(...)
  log_message("DEBUG", LEVELS.DEBUG, ...)
end

return log
