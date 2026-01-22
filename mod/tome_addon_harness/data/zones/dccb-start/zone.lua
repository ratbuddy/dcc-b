-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- DCCB Stub Start Zone - Stable Surface Generator
-- Virtual path: /data-dccb/zones/dccb-start/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-start/ (overload)

return {
  name = "DCCB Start",
  short_name = "dccb-start",
  -- IMPORTANT: register the zone entity lists so zone:makeEntity("terrain", ...) can find GRASS/TREE/etc
  -- These paths are the *global* zone paths provided by overload/...
  load = {
    "/data/zones/dccb-start/grids.lua",
    "/data/zones/dccb-start/objects.lua",
    "/data/zones/dccb-start/traps.lua",
    "/data/zones/dccb-start/npcs.lua",
  },
  level_range = {1, 1},
  max_level = 1,
  width = 30,
  height = 30,
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  no_level_connectivity = true,
  
  -- Debug logging on zone entry
  on_enter = function(a,b,...)
    local zone, lev
    if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
    local zname = (zone and zone.short_name) or "unknown"
    print(string.format("[DCCB-Zone] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  end,
  
  -- Post-process: fill with grass and place 1-2 inert entrance markers
	post_process = function(a, b, c, ...)
	  -- Find the level object safely
	  local level =
		   (type(a) == "table" and a.map and a)
		or (type(b) == "table" and b.map and b)
		or (type(c) == "table" and c.map and c)

	  if not level or not level.map then
		print("[DCCB] post_process: could not locate level/map, aborting")
		return
	  end

	-- Find the zone object safely
	local zone =
		 (type(a) == "table" and a.makeEntity and a)
	  or (type(b) == "table" and b.makeEntity and b)
	  or (type(c) == "table" and c.makeEntity and c)
	  or level.zone

	if not zone then
	  print("[DCCB] post_process: could not locate zone object, aborting")
	  return
	end

	  local Map  = require "engine.Map"
	  local map  = level.map

	  print("[DCCB] post_process: begin surface fill")

	  local w = level.map.w
	  local h = level.map.h

		-- Helper to safely make terrain (grid entity)
		local function make_terrain(def)
		  if not zone.makeEntityByName then
			print("[DCCB] zone.makeEntityByName missing")
			return nil
		  end

		  -- Correct signature: (level, kind, define_as)
		  -- For terrains defined in grids.lua, kind is "grid"
		  local g = zone:makeEntityByName(level, "grid", def)
		  if not g then
			print("[DCCB] FAILED to resolve grid by name:", def)
			return nil
		  end

		  if g.resolve then g:resolve() end
		  return g
		end

	  -- Test construction once
	  local grass = make_terrain("GRASS")
	  local tree  = make_terrain("TREE")
	  local ent   = make_terrain("DCCB_ENTRANCE")

	  print("[DCCB] terrain resolve test:",
		"GRASS=", grass and grass.name,
		"TREE=",  tree and tree.name,
		"ENT=",   ent and ent.name
	  )

	  if not grass then
		print("[DCCB] CRITICAL: GRASS did not resolve. Check grids.lua loading.")
		return
	  end

	  -- Fill whole map with grass
	  for x = 0, w - 1 do
		for y = 0, h - 1 do
		  local g = make_terrain("GRASS")
		  map(x, y, Map.TERRAIN, g)
		end
	  end

	  -- Simple predictable edge trees (proof-of-life pattern)
	  if tree then
		for x = 0, w - 1 do
		  for y = 0, h - 1 do
			if (x < 3 or x > w-4 or y < 3 or y > h-4) and ((x + y) % 3 == 0) then
			  local t = make_terrain("TREE")
			  if t then map(x, y, Map.TERRAIN, t) end
			end
		  end
		end
	  end

	  -- Two inert markers
	  if ent then
		local e1x, e1y = math.floor(w/3),     math.floor(h/2)
		local e2x, e2y = math.floor(w*2/3),   math.floor(h/2)

		map(e1x, e1y, Map.TERRAIN, make_terrain("DCCB_ENTRANCE"))
		map(e2x, e2y, Map.TERRAIN, make_terrain("DCCB_ENTRANCE"))
	  end

	  print("[DCCB-Surface] stable Empty-map surface generated")
	end,
  
  -- Single stable generator: Empty (no Roomer, no intra-zone stairs)
  generator = {
    map = {
      class = "engine.generator.map.Empty",
      zoom = 1,
      -- NO up/down/door mappings - prevents intra-zone stair generation
    },
    -- Zero spawns
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
  
  -- Level 1 configuration
  levels = {
    [1] = {
      generator = {
        map = {
          class = "engine.generator.map.Empty",
          zoom = 1,
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
