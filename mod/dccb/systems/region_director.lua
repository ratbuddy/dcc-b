-- /mod/dccb/systems/region_director.lua
-- Region Director system module
-- Phase 1 Task 5: Region selection and region-derived bias/filter logic
-- 
-- Responsibilities:
-- - Region selection (random, pinned, weighted modes)
-- - Region profile management
-- - Enemy pool filtering (banned factions, allowed faction weighting)
-- - Loot pool filtering (table weights, rarity bias)
-- - Generation constraint application (asset sets, hazards, traversal)
--
-- This module is engine-agnostic and must not call ToME or any engine APIs.

local log = require("mod.dccb.core.log")
local Events = require("mod.dccb.core.events")

local RegionDirector = {}

-- Private module state
local module_state = {
  initialized = false,
  state_ref = nil,
  data_ref = nil,
  rng_stream = nil
}

-- Initialize the Region Director
-- @param state table - the global DCCBState singleton
-- @param data table - bootstrap data including regions_by_id
-- @param rng table - RNG object with stream() method
function RegionDirector.init(state, data, rng)
  log.debug("RegionDirector.init: initializing")
  
  -- Validate inputs
  if not state then
    log.error("RegionDirector.init: state is nil")
    error("RegionDirector.init: state is required")
  end
  
  if not data then
    log.error("RegionDirector.init: data is nil")
    error("RegionDirector.init: data is required")
  end
  
  if not data.regions_by_id then
    log.error("RegionDirector.init: data.regions_by_id is missing")
    error("RegionDirector.init: data.regions_by_id is required")
  end
  
  if not rng then
    log.error("RegionDirector.init: rng is nil")
    error("RegionDirector.init: rng is required")
  end
  
  -- Validate that at least one region exists
  local region_count = 0
  for _ in pairs(data.regions_by_id) do
    region_count = region_count + 1
    break
  end
  
  if region_count == 0 then
    log.error("RegionDirector.init: no regions found in data.regions_by_id")
    error("RegionDirector.init: at least one region must be defined")
  end
  
  -- Store references
  module_state.state_ref = state
  module_state.data_ref = data
  module_state.rng_stream = rng:stream("region")
  module_state.initialized = true
  
  log.info("RegionDirector initialized with", region_count, "region(s)")
end

-- Select a region based on config.region_mode
-- @param state table - the global DCCBState singleton
-- @param rng table - RNG object (for consistency, though we use cached stream)
-- @return string - the selected region_id
function RegionDirector.select_region(state, rng)
  log.debug("RegionDirector.select_region: starting region selection")
  
  if not module_state.initialized then
    log.error("RegionDirector.select_region: module not initialized")
    error("RegionDirector.select_region: call init() first")
  end
  
  local config = state.run.config
  local region_mode = config.region_mode
  local data = module_state.data_ref
  local rng_stream = module_state.rng_stream
  
  log.debug("RegionDirector.select_region: mode =", region_mode)
  
  local selected_id = nil
  
  if region_mode == "pinned" then
    -- Pinned mode: must match config.pinned_region_id
    local pinned_id = config.pinned_region_id
    
    if not pinned_id then
      log.error("RegionDirector.select_region: region_mode is 'pinned' but pinned_region_id is not set")
      error("RegionDirector.select_region: pinned_region_id is required when region_mode='pinned'")
    end
    
    if not data.regions_by_id[pinned_id] then
      log.error("RegionDirector.select_region: pinned_region_id '" .. pinned_id .. "' not found in regions_by_id")
      error("RegionDirector.select_region: pinned_region_id '" .. pinned_id .. "' does not exist")
    end
    
    selected_id = pinned_id
    log.info("RegionDirector: selected region (pinned):", selected_id)
    
  elseif region_mode == "weighted" then
    -- Weighted mode: Phase 1 placeholder - fall back to random
    log.warn("RegionDirector.select_region: weighted mode not yet implemented, falling back to random")
    region_mode = "random"
    -- Fall through to random selection below
  end
  
  if region_mode == "random" or selected_id == nil then
    -- Random mode: uniform random from all regions
    local region_ids = {}
    for id, _ in pairs(data.regions_by_id) do
      table.insert(region_ids, id)
    end
    
    -- Sort for determinism (same seed always produces same order)
    table.sort(region_ids)
    
    local random_index = rng_stream:next_int(1, #region_ids)
    selected_id = region_ids[random_index]
    
    log.info("RegionDirector: selected region (random):", selected_id, "from", #region_ids, "options")
  end
  
  -- Load the selected region profile
  local profile = data.regions_by_id[selected_id]
  
  if not profile then
    log.error("RegionDirector.select_region: selected region '" .. selected_id .. "' has no profile")
    error("RegionDirector.select_region: region profile missing for " .. selected_id)
  end
  
  -- Update state
  state.region.id = selected_id
  state.region.profile = profile
  
  -- Log selection details
  log.info("RegionDirector: region selected")
  log.info("  Region ID:", selected_id)
  log.info("  Region Name:", profile.name or "(unnamed)")
  log.info("  Seed:", state.run.seed)
  
  -- Emit REGION_SELECTED event
  Events.emit("REGION_SELECTED", {
    region_id = selected_id,
    region_name = profile.name,
    seed = state.run.seed
  })
  
  return selected_id
end

-- Get the active region profile
-- @param state table - the global DCCBState singleton
-- @return table - the RegionProfile, or error if not set
function RegionDirector.get_profile(state)
  if not state.region.profile then
    log.error("RegionDirector.get_profile: no active region profile")
    error("RegionDirector.get_profile: no region selected yet")
  end
  
  return state.region.profile
end

-- Filter enemy pool based on region profile
-- Applies banned faction filtering and allowed faction weighting
-- @param state table - the global DCCBState singleton
-- @param floor_state table - current floor state (for future use)
-- @param context table - spawn context (for future use)
-- @param candidates table - array of weighted enemy candidates { id, w, ... }
-- @return table - filtered weighted list (new table, input not mutated)
function RegionDirector.filter_enemy_pool(state, floor_state, context, candidates)
  log.debug("RegionDirector.filter_enemy_pool: starting")
  
  if not candidates or #candidates == 0 then
    log.debug("RegionDirector.filter_enemy_pool: candidates empty, returning empty list")
    return {}
  end
  
  local profile = RegionDirector.get_profile(state)
  local enemy_factions = profile.enemy_factions or {}
  local banned = enemy_factions.banned or {}
  local allowed = enemy_factions.allowed or {}
  
  -- Build banned set for fast lookup
  local banned_set = {}
  for _, faction_id in ipairs(banned) do
    banned_set[faction_id] = true
  end
  
  -- Build allowed weights map
  local allowed_weights = {}
  for _, item in ipairs(allowed) do
    if item.id then
      allowed_weights[item.id] = item.w or 1.0
    end
  end
  
  local input_count = #candidates
  
  -- Filter and reweight
  local filtered = {}
  for _, candidate in ipairs(candidates) do
    local id = candidate.id
    
    -- Skip if banned
    if banned_set[id] then
      log.debug("RegionDirector.filter_enemy_pool: banned faction:", id)
    else
      -- Create new weighted item (don't mutate input)
      local new_item = {
        id = id,
        w = candidate.w or 1.0
      }
      
      -- Apply allowed faction weight multiplier if present
      if allowed_weights[id] then
        new_item.w = new_item.w * allowed_weights[id]
        log.debug("RegionDirector.filter_enemy_pool: applied weight for faction", id, "->", new_item.w)
      end
      
      -- Copy other fields
      for key, value in pairs(candidate) do
        if key ~= "id" and key ~= "w" then
          new_item[key] = value
        end
      end
      
      table.insert(filtered, new_item)
    end
  end
  
  log.debug("RegionDirector.filter_enemy_pool: complete (input:", input_count, "output:", #filtered, ")")
  
  return filtered
end

-- Filter loot pool based on region profile
-- Applies loot_bias table_weights and rarity_bias structurally
-- @param state table - the global DCCBState singleton
-- @param floor_state table - current floor state (for future use)
-- @param context table - loot context (for future use)
-- @param candidates table - array of weighted loot candidates { id, w, ... }
-- @return table - filtered weighted list (new table, input not mutated)
function RegionDirector.filter_loot_pool(state, floor_state, context, candidates)
  log.debug("RegionDirector.filter_loot_pool: starting")
  
  if not candidates or #candidates == 0 then
    log.debug("RegionDirector.filter_loot_pool: candidates empty, returning empty list")
    return {}
  end
  
  local profile = RegionDirector.get_profile(state)
  local loot_bias = profile.loot_bias or {}
  local table_weights = loot_bias.table_weights or {}
  local rarity_bias = loot_bias.rarity_bias or 0
  
  -- Build table weights map
  local weight_map = {}
  for _, item in ipairs(table_weights) do
    if item.id then
      weight_map[item.id] = item.w or 1.0
    end
  end
  
  local input_count = #candidates
  
  -- Filter and reweight
  local filtered = {}
  for _, candidate in ipairs(candidates) do
    local id = candidate.id
    
    -- Create new weighted item (don't mutate input)
    local new_item = {
      id = id,
      w = candidate.w or 1.0
    }
    
    -- Apply table weight multiplier if present
    if weight_map[id] then
      new_item.w = new_item.w * weight_map[id]
      log.debug("RegionDirector.filter_loot_pool: applied weight for table", id, "->", new_item.w)
    end
    
    -- Apply rarity bias structurally (Phase 1: just store it, don't compute yet)
    -- Future phases will use this to adjust rare vs common drops
    new_item.rarity_bias = rarity_bias
    
    -- Copy other fields
    for key, value in pairs(candidate) do
      if key ~= "id" and key ~= "w" then
        new_item[key] = value
      end
    end
    
    table.insert(filtered, new_item)
  end
  
  log.debug("RegionDirector.filter_loot_pool: complete (input:", input_count, "output:", #filtered, ")")
  
  return filtered
end

-- Apply region generation constraints to generation parameters
-- Returns a modified copy of gen_params with region profile constraints attached
-- @param state table - the global DCCBState singleton
-- @param gen_params table - generation parameters (engine-specific structure)
-- @return table - modified gen_params with dccb_region subtable
function RegionDirector.apply_generation_constraints(state, gen_params)
  log.debug("RegionDirector.apply_generation_constraints: starting")
  
  if not gen_params then
    log.warn("RegionDirector.apply_generation_constraints: gen_params is nil, creating empty table")
    gen_params = {}
  end
  
  local profile = RegionDirector.get_profile(state)
  
  -- Create a modified copy (don't mutate input)
  local modified = {}
  for key, value in pairs(gen_params) do
    modified[key] = value
  end
  
  -- Attach region constraints in a dccb_region subtable
  -- Integration layer will translate this to engine-specific format
  modified.dccb_region = {
    id = state.region.id,
    asset_sets = profile.asset_sets or {},
    hazard_rules = profile.hazard_rules or {},
    traversal_modifiers = profile.traversal_modifiers or {}
  }
  
  log.debug("RegionDirector.apply_generation_constraints: complete")
  log.debug("  Region:", state.region.id)
  log.debug("  Asset sets:", profile.asset_sets and "present" or "none")
  log.debug("  Hazard rules:", profile.hazard_rules and "present" or "none")
  log.debug("  Traversal modifiers:", profile.traversal_modifiers and "present" or "none")
  
  return modified
end

return RegionDirector

--[[
========================
MODULE GUARANTEES
========================

This module guarantees:
1. Deterministic region selection given the same seed + config + data
2. Region profile is always loaded and accessible via get_profile()
3. filter_* functions never mutate input candidates
4. filter_* functions return empty list for empty input
5. apply_generation_constraints returns a new table, never mutates input
6. All randomness comes from the "region" RNG stream
7. No engine-specific calls (no ToME, no Barony APIs)
8. All failures are loud (error() with clear messages)
9. REGION_SELECTED event is emitted after successful selection

========================
EXPLICITLY DEFERRED
========================

The following are NOT responsibilities of Region Director:
- Floor rule selection and activation → Floor Director
- Dungeon generation → Integration layer
- Entity spawning → Integration layer + spawn adapters
- Contestant logic → Contestant System
- Reward resolution → Meta Layer
- UI rendering → UI layer
- Mutation application (affects regions) → Meta Layer + Floor Director

Phase 1 limitations:
- Weighted region selection: placeholder that falls back to random
- Rarity bias math: attached structurally but not computed
- NPC archetype filtering: deferred (no filter_npc_pool yet)
- Conditional weighting (when clauses): not evaluated in Phase 1

========================
INTEGRATION NOTES
========================

Integration layer responsibilities:
1. Translate dccb_region.asset_sets to engine-specific tileset/prop selection
2. Translate dccb_region.hazard_rules to engine hazard spawning
3. Translate dccb_region.traversal_modifiers to generation knobs
4. Apply region-filtered enemy/loot pools during spawn interception
5. Never call Region Director filter functions in tight loops (cache results)

--]]
