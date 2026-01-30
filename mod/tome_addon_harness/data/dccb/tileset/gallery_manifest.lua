-- /data/dccb/tileset/gallery_manifest.lua
-- Verified ToME terrain manifest for tileset gallery
-- Virtual path: /data-dccb/dccb/tileset/gallery_manifest.lua
--
-- This file contains VERIFIED ToME terrain IDs that actually exist and load successfully
-- Based on runtime testing - only includes terrains that resolve and render
-- Organized by terrain family for surface theme development

local M = {}

-- ============================================================================
-- TERRAIN CANDIDATES - VERIFIED WORKING TERRAINS ONLY
-- ============================================================================
-- These IDs have been verified to exist and load successfully in ToME
-- Non-existent terrains have been removed to prevent blank areas in gallery

M.TERRAIN_CANDIDATES = {
  -- ===== DCCB CUSTOM TERRAINS (12 terrains) =====
  -- All DCCB custom grids are verified working
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
  {id = "DCCB_ENTRANCE", category = "DCCB/Special", description = "Entrance marker (blacklisted)"},
  
  -- ===== TOME OFFICIAL TERRAINS (8 terrains) =====
  -- Verified from runtime tile loading logs
  
  -- Forest (from forest.lua pack)
  {id = "AUTUMN_TREE", category = "ToME/Forest", description = "Autumn tree"},
  {id = "SNOW_TREE", category = "ToME/Forest", description = "Snow-covered tree"},
  
  -- Mountain (from mountain.lua pack)
  {id = "MOUNTAIN", category = "ToME/Mountain", description = "Mountain"},
  {id = "MOUNTAIN_WALL", category = "ToME/Mountain", description = "Mountain wall"},
  
  -- Water (from water.lua pack)
  {id = "WATER", category = "ToME/Water", description = "Water"},
  {id = "DEEP_WATER", category = "ToME/Water", description = "Deep water"},
  
  -- Lava (from lava.lua pack)
  {id = "LAVA", category = "ToME/Lava", description = "Lava"},
  
  -- Structures (from jungle_hut.lua pack)
  {id = "BAMBOO_HUT_FLOOR", category = "ToME/Structures", description = "Bamboo hut floor"},
}

return M
