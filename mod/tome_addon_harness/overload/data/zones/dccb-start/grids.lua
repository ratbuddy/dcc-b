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
  always_remember = true,
}

-- Define GRASS terrain (passable surface tile)
newEntity{
  base = "FLOOR",
  define_as = "GRASS",
  type = "floor", subtype = "grass",
  name = "grass",
  display = ',', color=colors.LIGHT_GREEN,
  always_remember = true,
}

-- Define TREE terrain (blocks movement and sight)
newEntity{
  base = "WALL",
  define_as = "TREE",
  type = "wall", subtype = "tree",
  name = "tree",
  display = 'T', color=colors.GREEN,
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
  always_remember = true,
}

-- Define DOWN stair terrain
newEntity{
  base = "FLOOR",
  define_as = "DOWN",
  type = "floor", subtype = "floor",
  name = "stairs down",
  display = '>', color=colors.WHITE,
  always_remember = true,
  change_level = 1,
}
