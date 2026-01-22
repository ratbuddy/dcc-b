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

-- Custom map generator class
local SurfaceGenerator = {}
SurfaceGenerator.__index = SurfaceGenerator

function SurfaceGenerator:new(zone, level, data)
  local o = {zone=zone, level=level, data=data}
  setmetatable(o, self)
  return o
end

function SurfaceGenerator:generate(lev, old_lev)
  local Map = require "engine.Map"
  
  -- TODO: Replace with /core/rng.lua stream per DCC-Engineering policy
  -- Using ToME's rng for now as a minimal fallback
  local rng_func = rng or math.random
  
  -- Select template randomly
  local templates = {"green_fields", "forest_road"}
  local template_id = templates[rng_func(#templates)]
  
  -- Initialize map with GRASS
  for x = 0, self.zone.width - 1 do
    for y = 0, self.zone.height - 1 do
      Map:addGrid(lev, x, y, "GRASS")
    end
  end
  
  -- Apply template
  if template_id == "green_fields" then
    -- Scatter trees across the field (10-15% density)
    for x = 0, self.zone.width - 1 do
      for y = 0, self.zone.height - 1 do
        if rng_func(100) <= 12 then
          Map:addGrid(lev, x, y, "TREE")
        end
      end
    end
  elseif template_id == "forest_road" then
    -- Create a road cutting across the map
    local road_type = rng_func(2) -- 1=horizontal, 2=diagonal
    
    if road_type == 1 then
      -- Horizontal road in the middle third
      local road_start = math.floor(self.zone.height / 3)
      local road_end = math.floor(self.zone.height * 2 / 3)
      for x = 0, self.zone.width - 1 do
        for y = road_start, road_end do
          Map:addGrid(lev, x, y, "ROAD")
        end
      end
    else
      -- Diagonal road
      local road_width = 3
      for x = 0, self.zone.width - 1 do
        local center_y = math.floor((x / self.zone.width) * self.zone.height)
        for dy = -road_width, road_width do
          local y = center_y + dy
          if y >= 0 and y < self.zone.height then
            Map:addGrid(lev, x, y, "ROAD")
          end
        end
      end
    end
    
    -- Add clustered trees around the road (20-25% density outside road)
    for x = 0, self.zone.width - 1 do
      for y = 0, self.zone.height - 1 do
        local g = Map.grids[x][y]
        -- Only place trees on GRASS, not ROAD
        if g and g.define_as == "GRASS" and rng_func(100) <= 22 then
          Map:addGrid(lev, x, y, "TREE")
        end
      end
    end
  end
  
  -- Place 2-4 DOWN stairs on passable tiles
  local num_stairs = rng_func(3) + 1 -- 2-4 stairs
  local stairs_placed = 0
  local min_distance = 8 -- Minimum distance between stairs
  local stair_positions = {}
  
  local max_attempts = 1000
  local attempts = 0
  
  while stairs_placed < num_stairs and attempts < max_attempts do
    attempts = attempts + 1
    
    local x = rng_func(self.zone.width - 1)
    local y = rng_func(self.zone.height - 1)
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
        Map:addGrid(lev, x, y, "DOWN")
        table.insert(stair_positions, {x=x, y=y})
        stairs_placed = stairs_placed + 1
      end
    end
  end
  
  -- Log the generation result
  print(string.format("[DCCB-Surface] template=%s stairs=%d", template_id, stairs_placed))
  
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
