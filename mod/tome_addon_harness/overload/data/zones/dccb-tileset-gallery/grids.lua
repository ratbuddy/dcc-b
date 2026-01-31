-- ToME4 DCCB addon - Grid Definitions for Tileset Gallery Zone
-- dccb-tileset-gallery: Visual catalog and validation of terrain tiles
-- This file provides terrain definitions at /data/zones/dccb-tileset-gallery/ path

-- Load base game terrain definitions first for compatibility
load("/data/general/grids/basic.lua")

-- ============================================================================
-- COMPREHENSIVE TERRAIN PACK LOADING
-- Loads ALL general terrain packs from definitive master list
-- ============================================================================

print("[DCCB-Gallery] Loading general terrain packs...")

-- Try to load definitive master list of ALL general packs
local pack_list_ok, pack_list_fn = pcall(loadfile, "/data-dccb/dccb/tileset/te4_general_grid_packs.lua")
local all_packs

if pack_list_ok and pack_list_fn then
  local list_ok, list = pcall(pack_list_fn)
  if list_ok and type(list) == "table" then
    all_packs = list
    print("[DCCB-Gallery] Loaded definitive pack list: " .. #all_packs .. " packs")
  else
    print("[DCCB-Gallery] WARNING: Failed to execute pack list, using fallback")
  end
end

-- Fallback: minimal known-good list if pack list unavailable
if not all_packs then
  print("[DCCB-Gallery] Using fallback pack list (9 packs)")
  all_packs = {
    "/data/general/grids/water.lua",
    "/data/general/grids/forest.lua",
    "/data/general/grids/lava.lua",
    "/data/general/grids/mountain.lua",
    "/data/general/grids/jungle_hut.lua",
    "/data/general/grids/crystal.lua",
    "/data/general/grids/ice.lua",
    "/data/general/grids/sand.lua",
    "/data/general/grids/void.lua",
  }
end

-- Load each pack with error handling
local loaded_count = 0
local failed_count = 0
local failures = {}

for _, path in ipairs(all_packs) do
  local ok, err = pcall(load, path)
  if ok then
    loaded_count = loaded_count + 1
    print("[DCCB-Gallery] ✓ Loaded pack: " .. path)
  else
    failed_count = failed_count + 1
    table.insert(failures, {path = path, error = tostring(err)})
    print("[DCCB-Gallery] ✗ FAILED to load: " .. path)
    if err then
      print("[DCCB-Gallery]   Error: " .. tostring(err))
    end
  end
end

-- Print summary
print("[DCCB-Gallery] ========================================")
print("[DCCB-Gallery] Pack Loading Summary:")
print(string.format("[DCCB-Gallery]   Attempted: %d", #all_packs))
print(string.format("[DCCB-Gallery]   Loaded: %d", loaded_count))
print(string.format("[DCCB-Gallery]   Failed: %d", failed_count))

if #failures > 0 then
  local show_count = math.min(5, #failures)
  print(string.format("[DCCB-Gallery] First %d failure(s):", show_count))
  for i = 1, show_count do
    print("[DCCB-Gallery]   - " .. failures[i].path)
  end
end
print("[DCCB-Gallery] ========================================")

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

