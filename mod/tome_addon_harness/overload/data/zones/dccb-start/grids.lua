-- ToME4 DCCB addon - Grid Definitions (Overload)
-- DCCB Start Zone terrains
-- This file provides terrain definitions at /data/zones/dccb-start/ (global zone path)

print("[DCCB] grids.lua loaded: /data/zones/dccb-start/grids.lua")

-- Load base game terrain definitions first for compatibility
load("/data/general/grids/basic.lua")

-- NOTE:
-- We intentionally keep these definitions minimal and ASCII-based for stability.
-- No change_level / change_zone here. No stairs. No randomness.
-- The zone post_process will paint these terrains using:
--   local g = zone:makeEntity(level, "terrain", { define_as="GRASS" }, nil, true)
--   map(x, y, Map.TERRAIN, g)

-- Define WALL terrain (blocks movement and sight)
newEntity{
  base = "WALL",
  define_as = "WALL",
  type = "wall", subtype = "wall",
  name = "wall",
  display = '#', color = colors.LIGHT_UMBER,
  always_remember = true,
  block_move = true,
  block_sight = true,
  air_level = -20,
}

-- Define FLOOR terrain (passable, visible)
newEntity{
  base = "FLOOR",
  define_as = "FLOOR",
  type = "floor", subtype = "floor",
  name = "floor",
  display = '.', color = colors.WHITE,
  always_remember = true,
}

-- Define GRASS terrain (passable surface tile)
newEntity{
  base = "FLOOR",
  define_as = "GRASS",
  type = "floor", subtype = "grass",
  name = "grass",
  display = ',', color = colors.LIGHT_GREEN,
  always_remember = true,
}

-- Define TREE terrain (blocks movement and sight)
newEntity{
  base = "WALL",
  define_as = "TREE",
  type = "wall", subtype = "tree",
  name = "tree",
  display = 'T', color = colors.GREEN,
  always_remember = true,
  block_move = true,
  block_sight = true,
  air_level = -10,
}

-- Define ROAD terrain (passable surface tile)
newEntity{
  base = "FLOOR",
  define_as = "ROAD",
  type = "floor", subtype = "road",
  name = "road",
  display = '=', color = colors.UMBER,
  always_remember = true,
}

-- Define DCCB_ENTRANCE terrain (visual dungeon entrance marker)
-- Does NOT cause level transitions - placeholder for future dungeon connections
newEntity{
  base = "FLOOR",
  define_as = "DCCB_ENTRANCE",
  type = "floor", subtype = "marker",
  name = "sealed dungeon entrance",
  display = '>', color = colors.YELLOW,
  always_remember = true,
  notice = true,

  -- Keep this fail-soft: if 'game' isn't ready, do nothing.
  on_stand = function(self, x, y, who)
    if not who or not who.player then return end
    if not game then return end

    -- One-time message per entrance per run
    local key = ("dccb_entrance_%d_%d"):format(x, y)
    if not game[key] then
      if game.log then
        game.log("#YELLOW#[DCCB] Dungeon entrance not implemented yet.")
      else
        print("[DCCB] Dungeon entrance not implemented yet.")
      end
      game[key] = true
    end
  end,
}
