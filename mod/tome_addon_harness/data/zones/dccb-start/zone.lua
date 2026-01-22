-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- DCCB Stub Start Zone - Surface Map Generator
-- NOTE: This is a duplicate of the overload version to work around ToME loading order
-- Virtual path: /data-dccb/zones/dccb-start/zone.lua

return {
  name = "DCCB Start",
  short_name = "dccb-start",
  level_range = {1, 1},
  max_level = 1,
  width = 30,
  height = 30,
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  no_level_connectivity = true,
  
  -- Debug logging on zone entry (robust signature)
  on_enter = function(a,b,...)
    local zone, lev
    if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
    local zname = (zone and zone.short_name) or "unknown"
    print(string.format("[DCCB-Zone] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  end,
  
  -- Post-process function to apply surface templates
  post_process = function(level)
    local Map = require "engine.Map"
    local zone = level.zone
    
    -- TODO: Replace with /core/rng.lua stream per DCC-Engineering policy
    -- Using rng.range/rng.table if available, fallback to math.random
    local rng_range = (rng and rng.range) or function(min, max)
      if not min or not max or min > max then
        error("rng_range: invalid range")
      end
      return math.random(min, max)
    end
    local rng_table = (rng and rng.table) or function(t)
      if not t or #t == 0 then
        error("rng_table: empty or nil table")
      end
      return t[math.random(1, #t)]
    end
    
    -- Constants for map generation
    local ROAD_WIDTH = 3
    local MIN_ENTRANCE_DISTANCE = 8
    local MAX_ENTRANCE_PLACEMENT_ATTEMPTS = 1000
    local SAFE_CLEARING_MARGIN = 5 -- Keep edges clear for spawning
    
    -- Select template randomly
    local templates = {"green_fields", "forest_road"}
    local template_id = rng_table(templates)
    
    -- Apply template
    if template_id == "green_fields" then
      -- Scatter trees across the field (8-15% density)
      -- Keep a safe clearing around the center
      local center_x = math.floor(zone.width / 2)
      local center_y = math.floor(zone.height / 2)
      local clearing_radius = 8
      
      for x = 0, zone.width - 1 do
        for y = 0, zone.height - 1 do
          -- Skip safe clearing area
          local dx = x - center_x
          local dy = y - center_y
          local dist_from_center = math.sqrt(dx*dx + dy*dy)
          
          if dist_from_center > clearing_radius and rng_range(1, 100) <= 12 then
            Map:addGrid(level, x, y, "TREE")
          end
        end
      end
      
    elseif template_id == "forest_road" then
      -- Create a road cutting across the map
      local road_type = rng_range(1, 2) -- 1=horizontal, 2=diagonal
      
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
        for x = 0, zone.width - 1 do
          local center_y = math.floor((x / zone.width) * zone.height)
          for dy = -ROAD_WIDTH, ROAD_WIDTH do
            local y = center_y + dy
            if y >= 0 and y < zone.height then
              Map:addGrid(level, x, y, "ROAD")
            end
          end
        end
      end
      
      -- Add clustered trees around the road (15-25% density)
      -- Keep safe margins around edges
      for x = SAFE_CLEARING_MARGIN, zone.width - 1 - SAFE_CLEARING_MARGIN do
        for y = SAFE_CLEARING_MARGIN, zone.height - 1 - SAFE_CLEARING_MARGIN do
          local g = Map.grids[x][y]
          -- Only place trees on GRASS, not ROAD
          if g and g.define_as == "GRASS" and rng_range(1, 100) <= 20 then
            Map:addGrid(level, x, y, "TREE")
          end
        end
      end
    end
    
    -- Place 2-4 DCCB_ENTRANCE markers on passable tiles
    local num_entrances = rng_range(2, 4)
    local entrances_placed = 0
    local entrance_positions = {}
    
    local attempts = 0
    
    while entrances_placed < num_entrances and attempts < MAX_ENTRANCE_PLACEMENT_ATTEMPTS do
      attempts = attempts + 1
      
      -- Generate coordinates (avoid edges)
      local x = rng_range(SAFE_CLEARING_MARGIN, zone.width - 1 - SAFE_CLEARING_MARGIN)
      local y = rng_range(SAFE_CLEARING_MARGIN, zone.height - 1 - SAFE_CLEARING_MARGIN)
      local g = Map.grids[x][y]
      
      -- Check if tile is passable (GRASS or ROAD)
      if g and (g.define_as == "GRASS" or g.define_as == "ROAD") then
        -- Check minimum distance from other entrances (Manhattan distance)
        local valid = true
        for _, pos in ipairs(entrance_positions) do
          local manhattan_dist = math.abs(x - pos.x) + math.abs(y - pos.y)
          if manhattan_dist < MIN_ENTRANCE_DISTANCE then
            valid = false
            break
          end
        end
        
        if valid then
          Map:addGrid(level, x, y, "DCCB_ENTRANCE")
          table.insert(entrance_positions, {x=x, y=y})
          entrances_placed = entrances_placed + 1
        end
      end
    end
    
    -- Log the generation result
    print(string.format("[DCCB-Surface] template=%s entrances=%d", template_id, entrances_placed))
  end,
  
  -- Generator configuration using Filled generator
  generator = {
    map = {
      class = "engine.generator.map.Filled",
      edge_entrances = {0, 0}, -- No edge entrances
      zoom = 1,
      ['#'] = "WALL", -- Required by Filled generator API
      ['.'] = "GRASS", -- Fill entire map with GRASS
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
  },
  
  -- Level-specific configuration
  levels = {
    [1] = {
      generator = {
        map = {
          class = "engine.generator.map.Filled",
          edge_entrances = {0, 0},
          zoom = 1,
          ['#'] = "WALL",
          ['.'] = "GRASS",
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
  },
}
