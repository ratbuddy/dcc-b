-- ToME4 DCCB addon - Zone Definition (Overload)
-- DCCB Stub Start Zone - Surface Map Generator
-- This file provides zone config at /data/zones/dccb-start/ path

local _M = {}

_M.name = "DCCB Start"
_M.short_name = "dccb-start"
_M.level_range = {1, 1}
_M.max_level = 1
_M.width = 50
_M.height = 50
_M.persistent = "zone"
_M.all_remembered = true
_M.all_lited = true
_M.no_level_connectivity = true

-- Debug logging on zone entry (dot-call signature)
function _M:on_enter(lev, old_lev, ...)
  print(string.format("[DCCB-Zone] Entered zone '%s' level %d", self.short_name or "unknown", lev or 0))
end

-- Custom surface map generator
-- Generates overworld-style surface with templates
local function generateSurfaceMap(level, zone)
  local Map = require "engine.Map"
  local grids = level.data.grids
  
  -- TODO: Replace with /core/rng.lua stream per DCC-Engineering policy
  -- Using ToME's rng for now as a minimal fallback
  local rng = rng or math.random
  
  -- Select template randomly
  local templates = {"green_fields", "forest_road"}
  local template_id = templates[rng(#templates)]
  
  -- Initialize map with GRASS
  for x = 0, zone.width - 1 do
    for y = 0, zone.height - 1 do
      Map:addGrid(level, x, y, "GRASS")
    end
  end
  
  -- Apply template
  if template_id == "green_fields" then
    -- Scatter trees across the field (10-15% density)
    for x = 0, zone.width - 1 do
      for y = 0, zone.height - 1 do
        if rng(100) <= 12 then
          Map:addGrid(level, x, y, "TREE")
        end
      end
    end
  elseif template_id == "forest_road" then
    -- Create a road cutting across the map
    local road_type = rng(2) -- 1=horizontal, 2=diagonal
    
    if road_type == 1 then
      -- Horizontal road in the middle third
      local road_start = math.floor(zone.height / 3)
      local road_end = math.floor(zone.height * 2 / 3)
      for x = 0, zone.width - 1 do
        for y = road_start, road_end do
          Map:addGrid(level, x, y, "ROAD")
        end
      end
    else
      -- Diagonal road
      local road_width = 3
      for x = 0, zone.width - 1 do
        local center_y = math.floor((x / zone.width) * zone.height)
        for dy = -road_width, road_width do
          local y = center_y + dy
          if y >= 0 and y < zone.height then
            Map:addGrid(level, x, y, "ROAD")
          end
        end
      end
    end
    
    -- Add clustered trees around the road (20-25% density outside road)
    for x = 0, zone.width - 1 do
      for y = 0, zone.height - 1 do
        local g = Map.grids[x][y]
        -- Only place trees on GRASS, not ROAD
        if g and g.define_as == "GRASS" and rng(100) <= 22 then
          Map:addGrid(level, x, y, "TREE")
        end
      end
    end
  end
  
  -- Place 2-4 DOWN stairs on passable tiles
  local num_stairs = rng(3) + 1 -- 2-4 stairs
  local stairs_placed = 0
  local min_distance = 8 -- Minimum distance between stairs
  local stair_positions = {}
  
  local max_attempts = 1000
  local attempts = 0
  
  while stairs_placed < num_stairs and attempts < max_attempts do
    attempts = attempts + 1
    
    local x = rng(zone.width - 1)
    local y = rng(zone.height - 1)
    local g = Map.grids[x][y]
    
    -- Check if tile is passable (GRASS or ROAD)
    if g and (g.define_as == "GRASS" or g.define_as == "ROAD") then
      -- Check minimum distance from other stairs
      local valid = true
      for _, pos in ipairs(stair_positions) do
        local dx = x - pos.x
        local dy = y - pos.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < min_distance then
          valid = false
          break
        end
      end
      
      if valid then
        Map:addGrid(level, x, y, "DOWN")
        table.insert(stair_positions, {x=x, y=y})
        stairs_placed = stairs_placed + 1
      end
    end
  end
  
  -- Log the generation result
  print(string.format("[DCCB-Surface] template=%s stairs=%d", template_id, stairs_placed))
  
  return true
end

-- Custom map generator class
local SurfaceGenerator = {}
SurfaceGenerator.__index = SurfaceGenerator

function SurfaceGenerator:new(zone, level, data)
  local o = {zone=zone, level=level, data=data}
  setmetatable(o, self)
  return o
end

function SurfaceGenerator:generate(lev, old_lev)
  generateSurfaceMap(lev, self.zone)
  return true
end

-- Generator configuration
_M.generator = {
  map = {
    class = SurfaceGenerator,
  },
  -- Explicit zero spawn generators
  actor = {
    class = "engine.generator.actor.Random",
    nb_npc = {0, 0},
  },
  object = {
    class = "engine.generator.object.Random",
    nb_object = {0, 0},
  },
  trap = {
    class = "engine.generator.trap.Random",
    nb_trap = {0, 0},
  },
}

-- Level-specific configuration
_M.levels = {
  [1] = {
    generator = {
      map = {
        class = SurfaceGenerator,
      },
      actor = {
        class = "engine.generator.actor.Random",
        nb_npc = {0, 0},
      },
      object = {
        class = "engine.generator.object.Random",
        nb_object = {0, 0},
      },
      trap = {
        class = "engine.generator.trap.Random",
        nb_trap = {0, 0},
      },
    },
  },
}

return _M
