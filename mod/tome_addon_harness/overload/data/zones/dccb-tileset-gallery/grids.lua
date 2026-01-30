-- ToME4 DCCB addon - Grid Definitions for Tileset Gallery Zone
-- dccb-tileset-gallery: Visual catalog and validation of terrain tiles
-- This file provides terrain definitions at /data/zones/dccb-tileset-gallery/ path

-- Load base game terrain definitions first for compatibility
load("/data/general/grids/basic.lua")

-- ============================================================================
-- DCCB SURFACE GRIDS - Defined here for gallery display
-- These grids mirror the definitions from dccb-surface-master
-- ============================================================================

-- ============================================================================
-- GREEN/PLAINS THEME - Default grass and trees
-- ============================================================================

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

-- ============================================================================
-- WINTER/SNOW THEME - Snowy landscape
-- ============================================================================

-- Define GRASS_WINTER terrain (snow-covered ground)
-- Inherits tileset from FLOOR base entity
newEntity{
  base = "FLOOR",
  define_as = "GRASS_WINTER",
  type = "floor", subtype = "snow",
  name = "snowy ground",
  display = '.', color=colors.WHITE,
  always_remember = true,
}

-- Define ROAD_WINTER terrain (icy path)
-- Inherits tileset from FLOOR base entity
newEntity{
  base = "FLOOR",
  define_as = "ROAD_WINTER",
  type = "floor", subtype = "ice",
  name = "icy path",
  display = '=', color=colors.LIGHT_BLUE,
  always_remember = true,
}

-- Define TREE_WINTER terrain (snowy tree - blocks movement)
-- Inherits tileset from WALL base entity
newEntity{
  base = "WALL",
  define_as = "TREE_WINTER",
  type = "wall", subtype = "tree",
  name = "snowy tree",
  display = 'T', color=colors.WHITE,
  always_remember = true,
  block_move = true,
  block_sight = true,
  air_level = -10,
}

-- ============================================================================
-- RUINS/ANCIENT THEME - Weathered stone and overgrown
-- ============================================================================

-- Define GRASS_RUINS terrain (cracked earth with grass)
-- Inherits tileset from FLOOR base entity
newEntity{
  base = "FLOOR",
  define_as = "GRASS_RUINS",
  type = "floor", subtype = "grass",
  name = "overgrown ground",
  display = ',', color=colors.DARK_GREEN,
  always_remember = true,
}

-- Define ROAD_RUINS terrain (ancient stone path)
-- Inherits tileset from FLOOR base entity
newEntity{
  base = "FLOOR",
  define_as = "ROAD_RUINS",
  type = "floor", subtype = "stone",
  name = "ancient path",
  display = '=', color=colors.GREY,
  always_remember = true,
}

-- Define TREE_RUINS terrain (ruined pillar/wall - blocks movement)
-- Inherits tileset from WALL base entity
newEntity{
  base = "WALL",
  define_as = "TREE_RUINS",
  type = "wall", subtype = "ruins",
  name = "ruined pillar",
  display = '#', color=colors.GREY,
  always_remember = true,
  block_move = true,
  block_sight = false,
  air_level = -5,
}

-- ============================================================================
-- DCCB SPECIAL GRIDS
-- ============================================================================

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

