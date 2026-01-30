-- /data/dccb/tileset/gallery_manifest.lua
-- Curated ToME terrain manifest for tileset gallery
-- Virtual path: /data-dccb/dccb/tileset/gallery_manifest.lua
--
-- This file contains the authoritative list of ToME terrain IDs for DCCB surface templates
-- Extracted from official ToME grids.lua files
-- Organized by terrain family for surface theme development

local M = {}

-- ============================================================================
-- TERRAIN CANDIDATES - CURATED OFFICIAL TOME TERRAINS
-- ============================================================================
-- These IDs are extracted from ToME's official grid definitions
-- Missing IDs are skipped gracefully, dangerous ones (with change_level/on_stand) are filtered

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
  {id = "DCCB_ENTRANCE", category = "DCCB/Special", description = "Entrance marker (dangerous: has on_stand)"},
  
  -- ===== CORE_BASE - Essential base terrains =====
  {id = "ROAD", category = "ToME/Core", description = "Road (duplicate with DCCB)"},
  {id = "ROCK", category = "ToME/Core", description = "Rock"},
  
  -- ===== OUTDOOR_PLAINS - Open terrain surfaces =====
  {id = "DIRT", category = "ToME/Plains", description = "Dirt ground"},
  {id = "SAND", category = "ToME/Plains", description = "Sandy ground"},
  {id = "BEACH_UP", category = "ToME/Plains", description = "Beach (upward)"},
  {id = "BEACH_DOWN", category = "ToME/Plains", description = "Beach (downward)"},
  
  -- ===== FOREST - Trees and vegetation =====
  {id = "AUTUMN_TREE", category = "ToME/Forest", description = "Autumn tree"},
  {id = "SNOW_TREE", category = "ToME/Forest", description = "Snow-covered tree"},
  {id = "THICKET", category = "ToME/Forest", description = "Thicket"},
  {id = "BUSH", category = "ToME/Forest", description = "Bush"},
  
  -- ===== STONE_RUINS - Stone structures and ruins =====
  {id = "STONE_FLOOR", category = "ToME/Ruins", description = "Stone floor"},
  {id = "STONE_WALL", category = "ToME/Ruins", description = "Stone wall"},
  {id = "RUIN_FLOOR", category = "ToME/Ruins", description = "Ruined floor"},
  {id = "RUIN_WALL", category = "ToME/Ruins", description = "Ruined wall"},
  {id = "PILLAR", category = "ToME/Ruins", description = "Pillar"},
  {id = "ALTAR", category = "ToME/Ruins", description = "Altar (may be dangerous)"},
  {id = "ALTAR_BARE", category = "ToME/Ruins", description = "Bare altar"},
  {id = "ALTAR_CORRUPT", category = "ToME/Ruins", description = "Corrupt altar"},
  
  -- ===== MOUNTAIN_CAVE - Rocky and cave terrain =====
  {id = "MOUNTAIN", category = "ToME/Mountain", description = "Mountain"},
  {id = "MOUNTAIN_WALL", category = "ToME/Mountain", description = "Mountain wall"},
  {id = "CAVE_FLOOR", category = "ToME/Cave", description = "Cave floor"},
  {id = "CAVE_WALL", category = "ToME/Cave", description = "Cave wall"},
  {id = "AUTUMN_ROCK", category = "ToME/Mountain", description = "Autumn rock"},
  
  -- ===== WATER - Water terrain family =====
  {id = "WATER", category = "ToME/Water", description = "Water"},
  {id = "DEEP_WATER", category = "ToME/Water", description = "Deep water"},
  {id = "SHALLOW_WATER", category = "ToME/Water", description = "Shallow water"},
  {id = "RIVER", category = "ToME/Water", description = "River"},
  
  -- ===== LAVA - Volcanic terrain =====
  {id = "LAVA", category = "ToME/Lava", description = "Lava"},
  {id = "DEEP_LAVA", category = "ToME/Lava", description = "Deep lava"},
  
  -- ===== SNOW_ICE - Winter terrain =====
  {id = "SNOW", category = "ToME/Snow", description = "Snow"},
  {id = "ICE", category = "ToME/Ice", description = "Ice"},
  {id = "SNOW_FLOOR", category = "ToME/Snow", description = "Snow floor"},
  {id = "SNOW_WALL", category = "ToME/Snow", description = "Snow wall"},
  
  -- ===== STRUCTURES - Built structures =====
  {id = "BAMBOO_HUT_FLOOR", category = "ToME/Structures", description = "Bamboo hut floor"},
  {id = "BAMBOO_HUT_WALL", category = "ToME/Structures", description = "Bamboo hut wall"},
  {id = "BAMBOO_HUT_DOOR", category = "ToME/Structures", description = "Bamboo hut door (may be dangerous)"},
}

return M
