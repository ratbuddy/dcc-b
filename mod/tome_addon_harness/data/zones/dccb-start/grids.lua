-- /mod/tome_addon_harness/data/zones/dccb-start/grids.lua
-- DCCB Stub Start Zone - Grid Definitions
-- Define minimal visible terrains for the zone

-- Load base game terrain definitions first
load("/data/general/grids/basic.lua")

-- Define WALL terrain (blocks movement and sight)
newEntity{
  define_as = "WALL",
  type = "wall", subtype = "floor",
  name = "wall",
  display = '#', color=colors.SLATE,
  always_remember = true,
  does_block_move = true,
  can_pass = {pass_wall=1},
  dig = "FLOOR",
  nice_tiler = { method="wall3d", inner={"WALL_1", 50, 1, 5}, north={"WALL_NORTH_1", 10, 1, 5}, south={"WALL_SOUTH_1", 100, 1, 5}, north_south="WALL_NORTH_SOUTH_1", small_pillar="WALL_SMALL_PILLAR_1", pillar_2="WALL_PILLAR_2", pillar_8={"WALL_PILLAR_8", 100, 1, 5}, pillar_4="WALL_PILLAR_4", pillar_6="WALL_PILLAR_6" },
}

-- Define FLOOR terrain (passable, visible)
newEntity{
  define_as = "FLOOR",
  type = "floor", subtype = "floor",
  name = "floor",
  display = '.', color=colors.DARK_GREY,
  always_remember = true,
}

