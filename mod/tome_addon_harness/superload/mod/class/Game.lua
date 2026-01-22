-- ToME4 DCCB addon - Game.lua Superload
-- Intercepts Game:changeLevelReal to redirect first zone transition to DCCB Start
-- This ensures the player goes to DCCB Start BEFORE Trollmire loads

local _M = loadPrevious(...)

-- Module-level one-shot redirect flag
local dccb_start_redirect_done = false

-- Store the original changeLevelReal implementation
local base_changeLevelReal = _M.changeLevelReal

-- Superload Game:changeLevelReal to intercept the first zone transition
function _M:changeLevelReal(lev, zone, ...)
  -- Target zone for redirect
  local target = "dccb+dccb-start"
  
  -- Check if redirect has already been done
  if dccb_start_redirect_done then
    -- Already redirected, pass through unchanged
    return base_changeLevelReal(self, lev, zone, ...)
  end
  
  -- Check if we're already going to the target zone (loop prevention)
  if zone == target then
    -- Already going to dccb-start, pass through unchanged
    return base_changeLevelReal(self, lev, zone, ...)
  end
  
  -- Check if zone is a table with short_name (loop prevention)
  if type(zone) == "table" and zone.short_name == "dccb-start" then
    -- Already going to dccb-start, pass through unchanged
    return base_changeLevelReal(self, lev, zone, ...)
  end
  
  -- This is the first zone transition and we're not already going to dccb-start
  -- Perform the one-shot redirect
  print("[DCCB] early redirect: changeLevelReal from " .. tostring(zone) .. " to " .. target)
  
  -- Set the flag to prevent future redirects
  dccb_start_redirect_done = true
  
  -- Redirect to DCCB Start level 1
  return base_changeLevelReal(self, 1, target, ...)
end

return _M
