-- ToME4 DCCB addon - Grid Definitions for Surface Master Zone
-- dccb-surface-master: Canonical surface generator showcase zone
-- This file provides terrain definitions at /data/zones/dccb-surface-master/ path

-- Load base game terrain definitions first for compatibility
load("/data/general/grids/basic.lua")

-- Define GRASS terrain (passable surface tile)
newEntity{
  base = "FLOOR",
  define_as = "GRASS",
  type = "floor", subtype = "grass",
  name = "grass",
  display = ',', color=colors.LIGHT_GREEN,
  image = "terrain/grass.png",
  always_remember = true,
}

-- Define ROAD terrain (passable surface tile)
newEntity{
  base = "FLOOR",
  define_as = "ROAD",
  type = "floor", subtype = "road",
  name = "road",
  display = '=', color=colors.UMBER,
  image = "terrain/road_dirt_6_1.png",
  always_remember = true,
}

-- Define TREE terrain (blocks movement and sight)
newEntity{
  base = "WALL",
  define_as = "TREE",
  type = "wall", subtype = "tree",
  name = "tree",
  display = 'T', color=colors.GREEN,
  image = "terrain/tree.png",
  always_remember = true,
  block_move = true,
  block_sight = true,
  air_level = -10,
}

-- Define SNOW terrain (optional placeholder - passable surface)
newEntity{
  base = "FLOOR",
  define_as = "SNOW",
  type = "floor", subtype = "snow",
  name = "snow",
  display = '.', color=colors.WHITE,
  image = "terrain/snow_ground.png",
  always_remember = true,
}

-- Define RUINS terrain (optional placeholder - blocks movement)
newEntity{
  base = "WALL",
  define_as = "RUINS",
  type = "wall", subtype = "ruins",
  name = "ruins",
  display = '#', color=colors.GREY,
  image = "terrain/grey_stone_wall1.png",
  always_remember = true,
  block_move = true,
  block_sight = false,
  air_level = -5,
}

-- Define DCCB_ENTRANCE terrain (visual dungeon entrance marker)
-- Does NOT cause level transitions - placeholder for future dungeon connections
newEntity{
  base = "FLOOR",
  define_as = "DCCB_ENTRANCE",
  type = "floor", subtype = "floor",
  name = "dungeon entrance",
  display = '>', color=colors.YELLOW,
  image = "terrain/grass.png",
  always_remember = true,
  -- NO change_level or change_zone - this is just a visual marker
  on_stand = function(self, x, y, who)
    if who.player then
      -- Use per-entrance tracking via grid coordinates
      local key = string.format("dccb_entrance_%d_%d", x, y)
      if not game[key] then
        game.log("#YELLOW#[DCCB] Dungeon entrance not implemented yet.")
        game[key] = true
      end
    end
  end,
}
