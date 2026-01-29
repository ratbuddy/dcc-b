-- ToME4 DCCB addon - Grid Definitions (Overload)
-- DCCB Stub Start Zone - Minimal visible terrains
-- This file provides terrain definitions at /data/zones/dccb-start/ path

-- Load base game terrain definitions first for compatibility
load("/data/general/grids/basic.lua")

-- Define WALL terrain (blocks movement and sight)
newEntity{
  base = "WALL",
  define_as = "WALL",
  type = "wall", subtype = "wall",
  name = "wall",
  display = '#', color=colors.LIGHT_UMBER,
  image = "terrain/grey_stone_wall1.png",
  always_remember = true,
  does_block_move = true,
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
  display = '.', color=colors.WHITE,
  image = "terrain/marble_floor.png",
  always_remember = true,
}

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

-- Define TREE terrain (blocks movement and sight)
newEntity{
  base = "WALL",
  define_as = "TREE",
  type = "wall", subtype = "tree",
  name = "tree",
  display = 'T', color=colors.GREEN,
  image = "terrain/tree.png",
  always_remember = true,
  does_block_move = true,
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
  display = '=', color=colors.UMBER,
  image = "terrain/road_dirt_6_1.png",
  always_remember = true,
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
