-- DCC-Barony entrypoint (Phase 1)
-- This is a stub showing how bootstrap would be used

--[[
  USAGE EXAMPLE:
  
  local Bootstrap = require("mod.dccb.core.bootstrap")
  
  -- Load all data
  local data = Bootstrap.load_all_data()
  
  -- data.config contains the loaded configuration
  -- data.regions_by_id contains region profiles indexed by id
  -- data.floor_rules_by_id contains floor rules indexed by id
  -- data.npc_archetypes_by_id contains NPC archetypes indexed by id
  -- data.reward_tables_by_id contains reward tables indexed by id
  -- data.mutations_by_id contains mutations indexed by id
  
  -- All data is validated during loading
  -- Missing required fields will error() with clear messages
  -- Missing optional fields will log WARN
  -- Broken references will log WARN
  
  -- For testing with absolute path:
  -- local data = Bootstrap.load_all_data("/path/to/mod/dccb/data")
--]]
