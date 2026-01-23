-- /data/dccb/surface/painter.lua
-- Surface Template Painter for DCCB Start Zone
-- Handles deterministic rendering of surface templates using known-good Empty generator

local Map = require "engine.Map"

local painter = {}

-- Helper: Create grid entity using zone's factory
-- Returns grid entity or nil if resolution fails
local function make_grid(zone, level, def)
  if not zone or not zone.makeEntityByName then
    print(string.format("[DCCB-Painter] ERROR: zone.makeEntityByName not available"))
    return nil
  end
  
  local grid = zone:makeEntityByName(level, "grid", def)
  if not grid then
    print(string.format("[DCCB-Painter] WARNING: Failed to resolve grid '%s'", def or "nil"))
  end
  return grid
end

-- Helper: Set terrain at coordinates
-- Uses map(x, y, Map.TERRAIN, grid) pattern
local function set_terrain(level, x, y, grid)
  if not level or not level.map then
    print(string.format("[DCCB-Painter] ERROR: level.map not available"))
    return false
  end
  
  if not grid then
    return false
  end
  
  level.map(x, y, Map.TERRAIN, grid)
  return true
end

-- Apply base fill across entire map
local function apply_base_fill(level, zone, template)
  local base_def = template.base or "GRASS"
  local base_grid = make_grid(zone, level, base_def)
  
  if not base_grid then
    print(string.format("[DCCB-Painter] ERROR: Failed to create base grid '%s'", base_def))
    return 0
  end
  
  local count = 0
  for x = 0, zone.width - 1 do
    for y = 0, zone.height - 1 do
      if set_terrain(level, x, y, base_grid) then
        count = count + 1
      end
    end
  end
  
  print(string.format("[DCCB-Painter] Base fill: %d cells with '%s'", count, base_def))
  return count
end

-- Apply edge ring decoration
local function apply_edge_ring(level, zone, decoration)
  local grid_def = decoration.grid or "TREE"
  local thickness = decoration.thickness or 2
  local step = decoration.step or 1
  
  local grid = make_grid(zone, level, grid_def)
  if not grid then
    print(string.format("[DCCB-Painter] WARNING: Failed to create decoration grid '%s'", grid_def))
    return 0
  end
  
  local count = 0
  for x = 0, zone.width - 1 do
    for y = 0, zone.height - 1 do
      local is_edge = x < thickness or x >= zone.width - thickness or 
                      y < thickness or y >= zone.height - thickness
      
      if is_edge and (x + y) % step == 0 then
        if set_terrain(level, x, y, grid) then
          count = count + 1
        end
      end
    end
  end
  
  print(string.format("[DCCB-Painter] Edge ring: %d '%s' cells (thickness=%d, step=%d)", 
    count, grid_def, thickness, step))
  return count
end

-- Apply vertical road decoration
local function apply_vertical_road(level, zone, decoration)
  local grid_def = decoration.grid or "ROAD"
  local width = decoration.width or 3
  
  local grid = make_grid(zone, level, grid_def)
  if not grid then
    print(string.format("[DCCB-Painter] WARNING: Failed to create decoration grid '%s'", grid_def))
    return 0
  end
  
  local center_x = math.floor(zone.width / 2)
  local start_x = center_x - math.floor(width / 2)
  
  local count = 0
  for x = start_x, start_x + width - 1 do
    if x >= 0 and x < zone.width then
      for y = 0, zone.height - 1 do
        if set_terrain(level, x, y, grid) then
          count = count + 1
        end
      end
    end
  end
  
  print(string.format("[DCCB-Painter] Vertical road: %d '%s' cells (width=%d)", 
    count, grid_def, width))
  return count
end

-- Apply all decorations from template
local function apply_decorations(level, zone, template)
  if not template.decorations then
    print("[DCCB-Painter] No decorations in template")
    return 0
  end
  
  local total = 0
  for i, decoration in ipairs(template.decorations) do
    local kind = decoration.kind
    
    if kind == "edge_ring" then
      total = total + apply_edge_ring(level, zone, decoration)
    elseif kind == "vertical_road" then
      total = total + apply_vertical_road(level, zone, decoration)
    else
      print(string.format("[DCCB-Painter] WARNING: Unknown decoration kind '%s'", kind or "nil"))
    end
  end
  
  print(string.format("[DCCB-Painter] Total decorations: %d cells", total))
  return total
end

-- Place entrance markers
local function apply_entrances(level, zone, template)
  if not template.entrances then
    print("[DCCB-Painter] No entrances in template")
    return 0
  end
  
  local count = template.entrances.count or 1
  local grid_def = template.entrances.grid or "DCCB_ENTRANCE"
  
  local grid = make_grid(zone, level, grid_def)
  if not grid then
    print(string.format("[DCCB-Painter] WARNING: Failed to create entrance grid '%s'", grid_def))
    return 0
  end
  
  local placed = 0
  
  -- Place entrances in deterministic positions
  if count >= 1 then
    -- Position 1: center-left
    local e1_x = math.floor(zone.width / 3)
    local e1_y = math.floor(zone.height / 2)
    if set_terrain(level, e1_x, e1_y, grid) then
      placed = placed + 1
    end
  end
  
  if count >= 2 then
    -- Position 2: center-right
    local e2_x = math.floor(zone.width * 2 / 3)
    local e2_y = math.floor(zone.height / 2)
    if set_terrain(level, e2_x, e2_y, grid) then
      placed = placed + 1
    end
  end
  
  print(string.format("[DCCB-Painter] Entrances: %d '%s' markers placed", placed, grid_def))
  return placed
end

-- Main paint function
-- Paints a surface using the provided template
-- Returns true on success, false on failure
function painter.paint_surface(level, zone, template)
  -- Validate inputs
  if not level or not level.map then
    print("[DCCB-Painter] ERROR: Invalid level object (no map)")
    return false
  end
  
  if not zone or not zone.makeEntityByName then
    print("[DCCB-Painter] ERROR: Invalid zone object (no makeEntityByName)")
    return false
  end
  
  if not template then
    print("[DCCB-Painter] ERROR: No template provided")
    return false
  end
  
  local template_name = template.name or "unknown"
  print(string.format("[DCCB-Painter] Starting surface paint with template '%s'", template_name))
  
  -- Apply in deterministic order
  local base_count = apply_base_fill(level, zone, template)
  local deco_count = apply_decorations(level, zone, template)
  local entrance_count = apply_entrances(level, zone, template)
  
  print(string.format("[DCCB-Painter] Completed template '%s': base=%d, decorations=%d, entrances=%d",
    template_name, base_count, deco_count, entrance_count))
  
  return true
end

return painter
