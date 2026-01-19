-- /mod/dccb/integration/actor_adapter.lua
-- ToME Actor Adapter - Phase-1 Task 9C
-- Engine translation surface between DCCB actor/item concepts and ToME's Actor/Item system
--
-- This module defines the contract where ToME actor/item creation logic will later live.
-- Phase-1: NO ToME API calls - only contract definition, normalization, and logging.
--
-- Public Interface:
-- - ActorAdapter.ensure_contestants_spawned(state, engine_ctx)
-- - ActorAdapter.spawn_one_contestant(state, contestant, engine_ctx)
-- - ActorAdapter.translate_spawn_candidate(candidate, spawn_type, state)
-- - ActorAdapter.materialize_reward(reward_result, state, engine_ctx)

local log = require("mod.dccb.core.log")

local ActorAdapter = {}

-------------------------------------------------------------------------------
-- ActorAdapter.ensure_contestants_spawned(state, engine_ctx)
-- Ensure all contestants from state.contestants.roster are spawned
--
-- Phase-1 Behavior:
-- - Iterates state.contestants.roster
-- - Calls spawn_one_contestant for each contestant
-- - Logs INFO with counts and DEBUG with contestant ids
-- - Returns summary table {requested=n, deferred=true}
-- - Does NOT perform actual ToME spawning
--
-- @param state table - the global DCCBState singleton
-- @param engine_ctx table - engine-specific context (unused in Phase-1)
-- @return table - spawn summary {requested=n, deferred=true}
-------------------------------------------------------------------------------
function ActorAdapter.ensure_contestants_spawned(state, engine_ctx)
  log.debug("ActorAdapter.ensure_contestants_spawned: starting")
  
  -- Validate inputs
  if not state then
    log.error("ActorAdapter.ensure_contestants_spawned: state is nil")
    error("ActorAdapter.ensure_contestants_spawned: state is required")
  end
  
  if not state.contestants then
    log.error("ActorAdapter.ensure_contestants_spawned: state.contestants is nil")
    error("ActorAdapter.ensure_contestants_spawned: state.contestants is required")
  end
  
  if not state.contestants.roster then
    log.error("ActorAdapter.ensure_contestants_spawned: state.contestants.roster is nil")
    error("ActorAdapter.ensure_contestants_spawned: state.contestants.roster is required")
  end
  
  local roster = state.contestants.roster
  local requested_count = #roster
  
  log.info("ActorAdapter would spawn", requested_count, "contestant(s) (deferred)")
  
  -- Collect contestant IDs for DEBUG logging
  local contestant_ids = {}
  
  -- Iterate roster and spawn each contestant
  for i, contestant in ipairs(roster) do
    -- Call spawn_one_contestant for each
    local descriptor = ActorAdapter.spawn_one_contestant(state, contestant, engine_ctx)
    
    -- Track contestant ID
    if contestant.id then
      table.insert(contestant_ids, contestant.id)
    end
  end
  
  -- Log DEBUG with contestant IDs
  if #contestant_ids > 0 then
    log.debug("ActorAdapter contestant IDs:", table.concat(contestant_ids, ", "))
  else
    log.debug("ActorAdapter: no contestant IDs found in roster")
  end
  
  -- Return summary
  local summary = {
    requested = requested_count,
    deferred = true
  }
  
  log.debug("ActorAdapter.ensure_contestants_spawned: complete")
  
  return summary
end

-------------------------------------------------------------------------------
-- ActorAdapter.spawn_one_contestant(state, contestant, engine_ctx)
-- Generate engine descriptor for spawning a single contestant
--
-- Phase-1 Behavior:
-- - Constructs an engine_descriptor with contestant metadata
-- - Logs DEBUG showing descriptor fields (not huge tables)
-- - Returns descriptor but does NOT perform actual ToME spawning
--
-- @param state table - the global DCCBState singleton
-- @param contestant table - contestant data from state.contestants.roster
-- @param engine_ctx table - engine-specific context (unused in Phase-1)
-- @return table - engine_descriptor describing what ToME entity would be created
-------------------------------------------------------------------------------
function ActorAdapter.spawn_one_contestant(state, contestant, engine_ctx)
  log.debug("ActorAdapter.spawn_one_contestant: processing contestant")
  
  -- Validate inputs
  if not state then
    log.error("ActorAdapter.spawn_one_contestant: state is nil")
    error("ActorAdapter.spawn_one_contestant: state is required")
  end
  
  if not contestant then
    log.error("ActorAdapter.spawn_one_contestant: contestant is nil")
    error("ActorAdapter.spawn_one_contestant: contestant is required")
  end
  
  -- Extract contestant fields
  local contestant_id = contestant.id or "unknown"
  local archetype_id = contestant.archetype_id or "generic"
  local name = contestant.name or "Unnamed Contestant"
  
  -- Extract personality profile if available
  local intended_build_hint = "generic"
  if contestant.personality_profile then
    local personality = contestant.personality_profile
    -- Simple build hint based on personality traits
    if personality.aggression and personality.aggression > 0.6 then
      intended_build_hint = "aggressive"
    elseif personality.risk_tolerance and personality.risk_tolerance < 0.4 then
      intended_build_hint = "defensive"
    else
      intended_build_hint = "balanced"
    end
  end
  
  -- Construct engine_descriptor
  local engine_descriptor = {
    kind = "actor",
    role = "contestant",
    contestant_id = contestant_id,
    archetype_id = archetype_id,
    name = name,
    intended_build_hint = intended_build_hint,
    tome_mapping = {
      -- TODO: Phase-2 ToME integration
      -- Determine race based on archetype or contestant background
      race = nil,  -- TODO: map archetype_id to ToME race ID
      
      -- TODO: Phase-2 ToME integration
      -- Determine class based on build_path or personality
      class = nil,  -- TODO: map intended_build_hint to ToME class ID
      
      -- TODO: Phase-2 ToME integration
      -- Select starting talents based on build path
      talents = nil  -- TODO: select initial talent unlocks
    }
  }
  
  -- Log DEBUG summary (avoid dumping full tables)
  log.debug("  Contestant:", contestant_id)
  log.debug("  Archetype:", archetype_id)
  log.debug("  Name:", name)
  log.debug("  Build Hint:", intended_build_hint)
  log.debug("  ToME mapping: TODO (race/class/talents)")
  
  return engine_descriptor
end

-------------------------------------------------------------------------------
-- ActorAdapter.translate_spawn_candidate(candidate, spawn_type, state)
-- Translate spawn candidate objects to engine descriptors
--
-- Phase-1 Behavior:
-- - Accepts candidate objects from spawn lists (enemy/loot)
-- - Returns engine_descriptor with kind="actor" or kind="item"
-- - Pass-through mapping: preserves id, weight, faction if present
-- - Attaches dccb_context with floor/region ids
-- - Logs DEBUG one-line summary
--
-- @param candidate table - spawn candidate from region/floor pools
-- @param spawn_type string - "enemy" or "loot" or other spawn type
-- @param state table - the global DCCBState singleton
-- @return table - engine_descriptor describing what ToME entity would be created
-------------------------------------------------------------------------------
function ActorAdapter.translate_spawn_candidate(candidate, spawn_type, state)
  log.debug("ActorAdapter.translate_spawn_candidate: spawn_type =", spawn_type)
  
  -- Validate inputs
  if not candidate then
    log.error("ActorAdapter.translate_spawn_candidate: candidate is nil")
    error("ActorAdapter.translate_spawn_candidate: candidate is required")
  end
  
  if not spawn_type then
    log.error("ActorAdapter.translate_spawn_candidate: spawn_type is nil")
    error("ActorAdapter.translate_spawn_candidate: spawn_type is required")
  end
  
  if not state then
    log.error("ActorAdapter.translate_spawn_candidate: state is nil")
    error("ActorAdapter.translate_spawn_candidate: state is required")
  end
  
  -- Determine kind based on spawn_type
  local kind = "unknown"
  if spawn_type == "enemy" then
    kind = "actor"
  elseif spawn_type == "loot" then
    kind = "item"
  else
    -- Default to actor for unknown types
    kind = "actor"
    log.debug("  Unknown spawn_type, defaulting to kind=actor")
  end
  
  -- Extract candidate fields (pass-through)
  local id = candidate.id or "unknown"
  local weight = candidate.weight or 1.0
  local faction = candidate.faction or nil
  
  -- Construct dccb_context
  local dccb_context = {
    floor_number = state.floor and state.floor.number or 0,
    region_id = state.region and state.region.id or "unknown"
  }
  
  -- Construct engine_descriptor
  local engine_descriptor = {
    kind = kind,
    id = id,
    weight = weight,
    faction = faction,
    dccb_context = dccb_context
  }
  
  -- Log DEBUG one-line summary
  log.debug("  Candidate:", id, "kind:", kind, "weight:", weight, "region:", dccb_context.region_id, "floor:", dccb_context.floor_number)
  
  return engine_descriptor
end

-------------------------------------------------------------------------------
-- ActorAdapter.materialize_reward(reward_result, state, engine_ctx)
-- Translate reward resolution result to engine descriptor for item creation
--
-- Phase-1 Behavior:
-- - Accepts reward_result from MetaLayer
-- - Returns engine_descriptor with kind="item"
-- - Logs INFO about reward materialization being deferred
-- - Does NOT perform actual ToME item creation
--
-- @param reward_result table - reward data from MetaLayer.resolve_reward
-- @param state table - the global DCCBState singleton
-- @param engine_ctx table - engine-specific context (unused in Phase-1)
-- @return table - engine_descriptor describing what ToME item would be created
-------------------------------------------------------------------------------
function ActorAdapter.materialize_reward(reward_result, state, engine_ctx)
  log.debug("ActorAdapter.materialize_reward: processing reward")
  
  -- Validate inputs
  if not reward_result then
    log.error("ActorAdapter.materialize_reward: reward_result is nil")
    error("ActorAdapter.materialize_reward: reward_result is required")
  end
  
  if not state then
    log.error("ActorAdapter.materialize_reward: state is nil")
    error("ActorAdapter.materialize_reward: state is required")
  end
  
  -- Extract reward fields
  local reward_id = reward_result.id or "unknown"
  local rarity = reward_result.rarity or "common"
  local table_id = reward_result.table_id or "default"
  
  -- Construct engine_descriptor
  local engine_descriptor = {
    kind = "item",
    reward_id = reward_id,
    rarity = rarity,
    table_id = table_id
  }
  
  -- Log INFO about deferred materialization
  log.info("ActorAdapter would materialize reward:", reward_id, "rarity:", rarity, "(deferred)")
  
  log.debug("ActorAdapter.materialize_reward: complete")
  
  return engine_descriptor
end

-------------------------------------------------------------------------------
-- End of actor_adapter.lua
--
-- Phase-1 Guarantees:
-- ✓ All functions return deterministic descriptors/summaries
-- ✓ No ToME API calls (all integration deferred to Phase-2)
-- ✓ Clear TODO markers for ToME mapping decisions
-- ✓ Proper input validation with ERROR logging
-- ✓ Consistent logging (INFO for high-level, DEBUG for details)
--
-- Deferred ToME Work (Phase-2):
-- - ActorAdapter.spawn_one_contestant:
--   * Map archetype_id to ToME race definitions
--   * Map intended_build_hint to ToME class definitions
--   * Select initial talent unlocks based on build_path
--   * Call ToME Actor:create() or equivalent API
--   * Set Actor position in zone
--   * Apply contestant metadata to Actor instance
--
-- - ActorAdapter.translate_spawn_candidate:
--   * For kind="actor": Map id to ToME NPC actor definitions
--   * For kind="item": Map id to ToME Object definitions
--   * Apply faction to Actor if applicable
--   * Leverage dccb_context for spawn location hints
--
-- - ActorAdapter.materialize_reward:
--   * Map reward_id to ToME Object definitions
--   * Apply rarity to item quality/affixes
--   * Consider table_id for themed rewards (sponsor items, etc.)
--   * Call ToME Object:create() or equivalent API
--   * Handle reward delivery to player
--
-- Integration with Other Systems:
-- - Hooks.on_spawn_request: Will call translate_spawn_candidate to convert
--   filtered spawn candidates to engine descriptors before ToME spawning
--
-- - ContestantSystem.spawn_contestants_if_needed: Will call
--   ensure_contestants_spawned to spawn NPC contestants at appropriate times
--
-- - MetaLayer reward resolution: Will call materialize_reward when REWARD_OPEN
--   event is processed and reward needs to be created in the game world
--
-- All integration points are designed to maintain the thin adapter layer
-- principle: ActorAdapter translates DCCB concepts to ToME-specific
-- descriptors but does not contain business logic or game rules.
-------------------------------------------------------------------------------

return ActorAdapter
