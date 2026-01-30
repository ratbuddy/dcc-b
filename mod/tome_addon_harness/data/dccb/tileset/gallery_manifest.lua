-- /data/dccb/tileset/gallery_manifest.lua
-- Comprehensive terrain and object ID manifest for tileset gallery
-- Virtual path: /data-dccb/dccb/tileset/gallery_manifest.lua
--
-- This file contains extensive lists of terrain and object IDs to probe
-- Many IDs may not exist in all ToME installations - that's expected
-- The gallery will safely skip missing IDs

local M = {}

-- ============================================================================
-- TERRAIN CANDIDATES
-- ============================================================================
-- Comprehensive list of terrain IDs to try displaying
-- Organized by category for maintainability
-- Missing IDs are skipped gracefully

M.TERRAIN_CANDIDATES = {
  -- ===== DCCB CUSTOM TERRAINS =====
  {id = "FLOOR", category = "DCCB/Base", description = "Standard floor"},
  {id = "WALL", category = "DCCB/Base", description = "Standard wall"},
  {id = "GRASS", category = "DCCB/Green", description = "Grass"},
  {id = "ROAD", category = "DCCB/Green", description = "Dirt road"},
  {id = "TREE", category = "DCCB/Green", description = "Tree"},
  {id = "GRASS_WINTER", category = "DCCB/Winter", description = "Snowy ground"},
  {id = "ROAD_WINTER", category = "DCCB/Winter", description = "Icy path"},
  {id = "TREE_WINTER", category = "DCCB/Winter", description = "Snowy tree"},
  {id = "GRASS_RUINS", category = "DCCB/Ruins", description = "Overgrown ground"},
  {id = "ROAD_RUINS", category = "DCCB/Ruins", description = "Ancient path"},
  {id = "TREE_RUINS", category = "DCCB/Ruins", description = "Ruined pillar"},
  {id = "DCCB_ENTRANCE", category = "DCCB/Special", description = "Entrance marker"},
  
  -- ===== BASE / GENERIC TERRAINS =====
  {id = "HARDFLOOR", category = "ToME/Base", description = "Hard floor"},
  {id = "HARDWALL", category = "ToME/Base", description = "Hard wall"},
  {id = "DIRT", category = "ToME/Base", description = "Dirt ground"},
  {id = "SAND", category = "ToME/Base", description = "Sandy ground"},
  {id = "ROCK", category = "ToME/Base", description = "Rocky ground"},
  {id = "STONE_FLOOR", category = "ToME/Base", description = "Stone floor"},
  {id = "STONE_WALL", category = "ToME/Base", description = "Stone wall"},
  {id = "GRANITE_FLOOR", category = "ToME/Base", description = "Granite floor"},
  {id = "GRANITE_WALL", category = "ToME/Base", description = "Granite wall"},
  {id = "MARBLE_FLOOR", category = "ToME/Base", description = "Marble floor"},
  {id = "MARBLE_WALL", category = "ToME/Base", description = "Marble wall"},
  
  -- ===== FOREST TERRAINS =====
  {id = "FOREST_TREE", category = "ToME/Forest", description = "Forest tree"},
  {id = "TREE_OLDER", category = "ToME/Forest", description = "Old tree"},
  {id = "TREE_BURNT", category = "ToME/Forest", description = "Burnt tree"},
  {id = "DENSE_FOREST", category = "ToME/Forest", description = "Dense forest"},
  {id = "TREE_WALL", category = "ToME/Forest", description = "Tree wall"},
  {id = "BUSH", category = "ToME/Forest", description = "Bush"},
  {id = "THICKET", category = "ToME/Forest", description = "Thicket"},
  {id = "FOREST_FLOOR", category = "ToME/Forest", description = "Forest floor"},
  {id = "FOREST_GRASS", category = "ToME/Forest", description = "Forest grass"},
  {id = "TALL_GRASS", category = "ToME/Forest", description = "Tall grass"},
  
  -- ===== WATER TERRAINS =====
  {id = "WATER", category = "ToME/Water", description = "Shallow water"},
  {id = "DEEP_WATER", category = "ToME/Water", description = "Deep water"},
  {id = "SHALLOW_WATER", category = "ToME/Water", description = "Shallow water"},
  {id = "WATER_BUBBLE", category = "ToME/Water", description = "Bubbling water"},
  {id = "WATER_FLOOR", category = "ToME/Water", description = "Water floor"},
  {id = "UNDERWATER_FLOOR", category = "ToME/Water", description = "Underwater floor"},
  {id = "UNDERWATER_WALL", category = "ToME/Water", description = "Underwater wall"},
  {id = "POOL", category = "ToME/Water", description = "Pool"},
  
  -- ===== LAVA TERRAINS =====
  {id = "LAVA", category = "ToME/Lava", description = "Lava"},
  {id = "DEEP_LAVA", category = "ToME/Lava", description = "Deep lava"},
  {id = "LAVA_DEEP", category = "ToME/Lava", description = "Deep lava alt"},
  {id = "VOLCANIC_FLOOR", category = "ToME/Lava", description = "Volcanic floor"},
  {id = "LAVA_FLOOR", category = "ToME/Lava", description = "Lava floor"},
  {id = "MOLTEN_ROCK", category = "ToME/Lava", description = "Molten rock"},
  
  -- ===== MOUNTAIN / CAVE TERRAINS =====
  {id = "MOUNTAIN", category = "ToME/Mountain", description = "Mountain"},
  {id = "MOUNTAIN_WALL", category = "ToME/Mountain", description = "Mountain wall"},
  {id = "MOUNTAIN_FLOOR", category = "ToME/Mountain", description = "Mountain floor"},
  {id = "CAVE_WALL", category = "ToME/Cave", description = "Cave wall"},
  {id = "CAVE_FLOOR", category = "ToME/Cave", description = "Cave floor"},
  {id = "ROCKY_GROUND", category = "ToME/Cave", description = "Rocky ground"},
  {id = "ROUGH_ROCK", category = "ToME/Cave", description = "Rough rock"},
  {id = "CAVE_MOSS", category = "ToME/Cave", description = "Cave moss"},
  
  -- ===== SNOW / ICE TERRAINS =====
  {id = "SNOW", category = "ToME/Snow", description = "Snow"},
  {id = "SNOW_FLOOR", category = "ToME/Snow", description = "Snow floor"},
  {id = "SNOW_GROUND", category = "ToME/Snow", description = "Snow ground"},
  {id = "ICE", category = "ToME/Ice", description = "Ice"},
  {id = "ICE_FLOOR", category = "ToME/Ice", description = "Ice floor"},
  {id = "ICE_WALL", category = "ToME/Ice", description = "Ice wall"},
  {id = "FROZEN_GROUND", category = "ToME/Ice", description = "Frozen ground"},
  
  -- ===== DUNGEON / SPECIAL TERRAINS =====
  {id = "DOOR", category = "ToME/Dungeon", description = "Door"},
  {id = "DOOR_OPEN", category = "ToME/Dungeon", description = "Open door"},
  {id = "DOOR_CLOSED", category = "ToME/Dungeon", description = "Closed door"},
  {id = "CHASM", category = "ToME/Dungeon", description = "Chasm"},
  {id = "PIT", category = "ToME/Dungeon", description = "Pit"},
  {id = "VOID", category = "ToME/Dungeon", description = "Void"},
  
  -- ===== MISC / VARIED TERRAINS =====
  {id = "SWAMP", category = "ToME/Misc", description = "Swamp"},
  {id = "MUD", category = "ToME/Misc", description = "Mud"},
  {id = "BOG", category = "ToME/Misc", description = "Bog"},
  {id = "SAND_FLOOR", category = "ToME/Misc", description = "Sand floor"},
  {id = "DESERT_SAND", category = "ToME/Misc", description = "Desert sand"},
  {id = "COBBLESTONE", category = "ToME/Misc", description = "Cobblestone"},
  {id = "FLAGSTONE", category = "ToME/Misc", description = "Flagstone"},
  {id = "CRYSTAL", category = "ToME/Misc", description = "Crystal"},
  {id = "CRYSTAL_WALL", category = "ToME/Misc", description = "Crystal wall"},
  {id = "FUNGUS", category = "ToME/Misc", description = "Fungus"},
  {id = "SLIME", category = "ToME/Misc", description = "Slime"},
}

-- ============================================================================
-- OBJECT CANDIDATES (Optional)
-- ============================================================================
-- List of object IDs to try displaying on a separate page/region
-- Objects are placed on top of floor terrain using Map.OBJECT

M.OBJECT_CANDIDATES = {
  {id = "BARREL", category = "Objects/Container", description = "Barrel"},
  {id = "CHEST", category = "Objects/Container", description = "Chest"},
  {id = "CRATE", category = "Objects/Container", description = "Crate"},
  {id = "POT", category = "Objects/Container", description = "Pot"},
  {id = "ALTAR", category = "Objects/Special", description = "Altar"},
  {id = "FOUNTAIN", category = "Objects/Special", description = "Fountain"},
  {id = "STATUE", category = "Objects/Deco", description = "Statue"},
  {id = "PILLAR", category = "Objects/Deco", description = "Pillar"},
  {id = "TORCH", category = "Objects/Light", description = "Torch"},
  {id = "BRAZIER", category = "Objects/Light", description = "Brazier"},
}

return M
