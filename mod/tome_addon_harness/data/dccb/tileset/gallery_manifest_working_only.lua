-- ToME Tales of Maj'Eyal
-- DCCB Tileset Gallery Manifest - WORKING TERRAINS ONLY
-- 
-- This manifest contains ONLY terrains that have been verified to work
-- with the general terrain packs loaded by the gallery.
-- 
-- Purpose: Provide a clean catalog of usable terrains for template development
-- No missing terrains = No grass spots = Professional reference
--
-- Source: Runtime verification from actual gallery execution
-- Verified: 2026-01-31
-- General packs loaded: basic, water, forest, lava, mountain, jungle_hut,
--   autumn, beach, crystal, desert, ice, swamp, temple, void, grass, road,
--   ruins, sand, snow, stone, tree, wall

local M = {}

-- Verified working terrains organized by category
-- All terrains listed here have been confirmed to load successfully
M.TERRAIN_CANDIDATES = {
  -- ========================================
  -- DCCB CUSTOM TERRAINS (12 terrains)
  -- ========================================
  
  -- DCCB/Base (2)
  {id = "FLOOR", category = "DCCB/Base", description = "Standard floor tile"},
  {id = "WALL", category = "DCCB/Base", description = "Standard wall tile"},
  
  -- DCCB/Green (3)
  {id = "GRASS", category = "DCCB/Green", description = "Grass terrain"},
  {id = "ROAD", category = "DCCB/Green", description = "Dirt road"},
  {id = "TREE", category = "DCCB/Green", description = "Tree"},
  
  -- DCCB/Winter (3)
  {id = "GRASS_WINTER", category = "DCCB/Winter", description = "Snowy grass"},
  {id = "ROAD_WINTER", category = "DCCB/Winter", description = "Icy road"},
  {id = "TREE_WINTER", category = "DCCB/Winter", description = "Winter tree"},
  
  -- DCCB/Ruins (3)
  {id = "GRASS_RUINS", category = "DCCB/Ruins", description = "Overgrown ruins ground"},
  {id = "ROAD_RUINS", category = "DCCB/Ruins", description = "Ancient path"},
  {id = "TREE_RUINS", category = "DCCB/Ruins", description = "Ruined pillar"},
  
  -- DCCB/Special (1 - blacklisted)
  {id = "DCCB_ENTRANCE", category = "DCCB/Special", description = "Dungeon entrance marker"},
  
  -- ========================================
  -- ToME GENERAL PACK TERRAINS (verified working)
  -- ========================================
  
  -- ToME/Floor (verified from runtime)
  {id = "BAMBOO_HUT_FLOOR", category = "ToME/Structures", description = "Bamboo hut floor"},
  {id = "CRYSTAL_FLOOR", category = "ToME/Floor", description = "Crystal floor"},
  {id = "FLOWER", category = "ToME/Vegetation", description = "Flower decoration"},
  {id = "LEVER", category = "ToME/Feature", description = "Lever"},
  {id = "MARBLE_FLOOR", category = "ToME/Floor", description = "Marble floor"},
  {id = "OLDSTONE_FLOOR", category = "ToME/Floor", description = "Old stone floor"},
  {id = "SANDFLOOR", category = "ToME/Floor", description = "Sandy floor"},
  {id = "SAND", category = "ToME/Floor", description = "Sand terrain"},
  
  -- ToME/Wall (verified from runtime)
  {id = "ROCKY_GROUND", category = "ToME/Wall", description = "Rocky ground"},
  {id = "HALF_WALL", category = "ToME/Wall", description = "Half wall"},
  {id = "CRYSTAL_WALL", category = "ToME/Wall", description = "Crystal wall"},
  {id = "GLASSWALL", category = "ToME/Wall", description = "Glass wall"},
  {id = "HARDFLOOR", category = "ToME/Floor", description = "Hard floor"},
  {id = "HARDWALL", category = "ToME/Wall", description = "Hard wall"},
  
  -- ToME/Mountain (verified from previous runs)
  {id = "MOUNTAIN", category = "ToME/Mountain", description = "Mountain terrain"},
  {id = "MOUNTAIN_WALL", category = "ToME/Wall", description = "Mountain wall"},
  
  -- ToME/Water (verified from previous runs)
  {id = "WATER", category = "ToME/Water", description = "Water"},
  {id = "DEEP_WATER", category = "ToME/Water", description = "Deep water"},
  
  -- ToME/Lava (verified from previous runs)
  {id = "LAVA", category = "ToME/Lava", description = "Lava"},
  
  -- ToME/Forest (verified from previous runs)
  {id = "AUTUMN_TREE", category = "ToME/Vegetation", description = "Autumn tree"},
  {id = "SNOW_TREE", category = "ToME/Vegetation", description = "Snow tree"},
}

-- Statistics
M.stats = {
  total = #M.TERRAIN_CANDIDATES,
  dccb_custom = 12,
  tome_official = #M.TERRAIN_CANDIDATES - 12,
  verified = "2026-01-31",
  source = "Runtime verification with general packs",
}

print(string.format("[DCCB-Gallery] Manifest: %d verified working terrains", M.stats.total))
print(string.format("[DCCB-Gallery]   DCCB custom: %d", M.stats.dccb_custom))
print(string.format("[DCCB-Gallery]   ToME official: %d", M.stats.tome_official))

return M
