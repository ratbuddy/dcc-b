-- /mod/dccb/systems/meta_layer.lua
-- Meta Layer system module for DCC-Barony mod
-- Implements Phase-1 Task 7: Meta Layer system
--
-- Owns:
-- - Announcer logic (logs only in Phase-1)
-- - Reward resolution pipeline (stub but deterministic)
-- - Achievement/sponsor hooks (deferred; placeholders provided)
--
-- This module is engine-agnostic and communicates via core/events.lua only

local log = require("mod.dccb.core.log")
local Events = require("mod.dccb.core.events")

local MetaLayer = {}

-- Maximum number of announcements to store in state
local MAX_ANNOUNCEMENTS = 50

-- Initialize the MetaLayer and ShowState
-- @param state table - the global DCCBState
-- @param data table - bootstrap data (may include reward_tables_by_id)
-- @param rng table - RNG instance from core/rng.lua
function MetaLayer.init(state, data, rng)
  if not state then
    log.error("MetaLayer.init: state is nil")
    error("MetaLayer.init requires valid state")
  end
  
  -- Ensure state.show.state exists and initialize minimal ShowState
  if not state.show then
    state.show = {}
  end
  
  state.show.state = {
    active_modifiers = {},
    sponsor_bias = {},
    achievement_flags = {},
    run_mutations = {},
    announcer_log = {}  -- Bounded list of recent announcements
  }
  
  log.info("MetaLayer initialized")
end

-- Handle events dispatched through the event bus
-- @param state table - the global DCCBState
-- @param event table - the event payload
function MetaLayer.on_event(state, event)
  if not state then
    log.error("MetaLayer.on_event: state is nil")
    return
  end
  
  if not event or not event.event_id then
    log.debug("MetaLayer.on_event: event missing event_id - ignoring")
    return
  end
  
  local event_id = event.event_id
  
  if event_id == "REWARD_OPEN" then
    -- Handle reward open event
    log.debug("MetaLayer.on_event: handling REWARD_OPEN event")
    
    -- Get RNG from state - it should have been initialized during bootstrap
    if not state.run.rng then
      log.error("MetaLayer.on_event: state.run.rng is nil - cannot resolve reward")
      return
    end
    
    local rng = state.run.rng
    local rng_stream = rng:stream("rewards")
    
    -- Resolve the reward
    local reward_result = MetaLayer.resolve_reward(state, event, rng_stream)
    
    -- Emit announcement
    local msg = string.format("Reward resolved: %s (rarity: %s)", 
                              reward_result.id or "unknown", 
                              reward_result.rarity or "unknown")
    MetaLayer.emit_announcement(state, msg, "INFO")
    
    -- Emit REWARD_RESOLVED event via event bus
    Events.emit("REWARD_RESOLVED", {
      event_id = "REWARD_RESOLVED",
      reward_result = reward_result,
      floor_number = event.floor_number,
      region_id = event.region_id,
      seed_context = "rewards"
    })
  else
    -- Phase-1: ignore all other events
    log.debug("MetaLayer.on_event: ignoring event", event_id)
  end
end

-- Deterministically resolve a reward
-- @param state table - the global DCCBState
-- @param reward_context table - context for reward resolution (event payload)
-- @param rng table - RNG stream from rng:stream("rewards")
-- @return table - reward result with kind, id, rarity, and metadata
function MetaLayer.resolve_reward(state, reward_context, rng)
  if not state then
    log.error("MetaLayer.resolve_reward: state is nil")
    error("MetaLayer.resolve_reward requires valid state")
  end
  
  if not rng then
    log.error("MetaLayer.resolve_reward: rng is nil")
    error("MetaLayer.resolve_reward requires valid rng stream")
  end
  
  -- Get bootstrap data from state if available
  local data = state.run.bootstrap_data or {}
  local reward_tables_by_id = data.reward_tables_by_id
  
  local reward_result = {
    floor_number = reward_context.floor_number,
    region_id = reward_context.region_id,
    seed_context = "rewards"
  }
  
  -- Check if we have reward tables
  if reward_tables_by_id and next(reward_tables_by_id) then
    -- Determine which table to use
    local table_id = nil
    
    if reward_context.table_id and reward_tables_by_id[reward_context.table_id] then
      -- Use specified table if it exists
      table_id = reward_context.table_id
    else
      -- Phase-1: pick first table in sorted order for determinism
      local sorted_table_ids = {}
      for id, _ in pairs(reward_tables_by_id) do
        table.insert(sorted_table_ids, id)
      end
      table.sort(sorted_table_ids)
      
      if #sorted_table_ids > 0 then
        table_id = sorted_table_ids[1]
      end
    end
    
    if table_id then
      local reward_table = reward_tables_by_id[table_id]
      reward_result.table_id = table_id
      
      -- Roll one entry deterministically using RNG
      local entries = reward_table.entries
      if entries and #entries > 0 then
        -- Calculate total weight
        local total_weight = 0
        for _, entry in ipairs(entries) do
          total_weight = total_weight + (entry.w or 1)
        end
        
        -- Roll a random value
        local roll = rng:next() * total_weight
        
        -- Select entry based on roll
        local accumulated_weight = 0
        for _, entry in ipairs(entries) do
          accumulated_weight = accumulated_weight + (entry.w or 1)
          if roll <= accumulated_weight then
            -- This entry is selected
            reward_result.kind = entry.type or "item"
            reward_result.id = entry.id
            reward_result.rarity = entry.rarity or "common"
            reward_result.payload = entry.payload
            
            log.info("Reward resolved: table=" .. table_id .. 
                    " id=" .. entry.id .. 
                    " rarity=" .. (entry.rarity or "common"))
            break
          end
        end
      else
        -- Table exists but has no entries
        log.warn("MetaLayer.resolve_reward: table", table_id, "has no entries - using placeholder")
        reward_result.kind = "placeholder"
        reward_result.id = "reward_placeholder"
        reward_result.rarity = "common"
        reward_result.table_id = table_id
      end
    else
      -- No valid table found
      log.warn("MetaLayer.resolve_reward: no valid reward table found - using placeholder")
      reward_result.kind = "placeholder"
      reward_result.id = "reward_placeholder"
      reward_result.rarity = "common"
    end
  else
    -- No reward tables available - use placeholder
    log.info("Reward resolved: placeholder (no reward tables available)")
    reward_result.kind = "placeholder"
    reward_result.id = "reward_placeholder"
    reward_result.rarity = "common"
  end
  
  return reward_result
end

-- Apply loot bias to weights (sponsor/achievement modifiers)
-- @param state table - the global DCCBState
-- @param weights table - array of weights to modify
-- @param context table - context for bias application
-- @return table - modified weights (Phase-1: unchanged)
function MetaLayer.apply_loot_bias(state, weights, context)
  -- Phase-1: return weights unchanged, but log if called
  log.debug("MetaLayer.apply_loot_bias: called (Phase-1 stub - no modifications)")
  return weights
end

-- Emit an announcement message
-- @param state table - the global DCCBState
-- @param msg string - the announcement message
-- @param severity string - severity level ("INFO", "WARN", "ERROR")
function MetaLayer.emit_announcement(state, msg, severity)
  if not state then
    log.error("MetaLayer.emit_announcement: state is nil")
    return
  end
  
  if not msg then
    log.error("MetaLayer.emit_announcement: msg is nil")
    return
  end
  
  severity = severity or "INFO"
  
  -- Log the announcement based on severity
  if severity == "ERROR" then
    log.error("[ANNOUNCER]", msg)
  elseif severity == "WARN" then
    log.warn("[ANNOUNCER]", msg)
  else
    log.info("[ANNOUNCER]", msg)
  end
  
  -- Store in state.show.state.announcer_log (bounded to MAX_ANNOUNCEMENTS)
  if state.show and state.show.state and state.show.state.announcer_log then
    local announcer_log = state.show.state.announcer_log
    
    -- Use run timestamp for deterministic testing if available, otherwise os.time()
    local timestamp = (state.run and state.run.started_at) or os.time()
    
    table.insert(announcer_log, {
      msg = msg,
      severity = severity,
      ts = timestamp
    })
    
    -- Keep log bounded
    while #announcer_log > MAX_ANNOUNCEMENTS do
      table.remove(announcer_log, 1)
    end
  end
end

return MetaLayer

--[[
=============================================================================
PHASE-1 vs DEFERRED BEHAVIOR
=============================================================================

PHASE-1 (IMPLEMENTED):
- MetaLayer.init(): Initializes minimal ShowState with required fields:
  * active_modifiers = {}
  * sponsor_bias = {}
  * achievement_flags = {}
  * run_mutations = {}
  * announcer_log = {} (bounded to 50 entries)
  
- MetaLayer.on_event(): Handles REWARD_OPEN events only:
  * Calls resolve_reward() to get reward_result
  * Emits announcement via emit_announcement()
  * Emits REWARD_RESOLVED event on event bus
  * All other events are logged as DEBUG and ignored
  
- MetaLayer.resolve_reward(): Deterministic reward resolution:
  * Uses reward_tables_by_id from bootstrap data if available
  * Chooses table by reward_context.table_id or first sorted table
  * Rolls one entry using RNG stream ("rewards")
  * Returns placeholder if no tables exist
  * Includes floor_number, region_id, seed_context in result
  
- MetaLayer.apply_loot_bias(): Phase-1 stub:
  * Returns weights unchanged
  * Logs DEBUG message if called
  * Keeps function signature for future implementation
  
- MetaLayer.emit_announcement(): Logs and stores announcements:
  * Logs via core/log.lua based on severity (INFO/WARN/ERROR)
  * Stores last N announcements in state.show.state.announcer_log
  * Log is bounded to 50 entries
  
DEFERRED TO FUTURE PHASES:
- Real sponsor bias logic (currently stub)
- Achievement detection and tracking
- Run mutations that affect future floors
- Advanced reward table selection (multi-roll, gating, conditions)
- Announcer UI overlay (Phase-1 only logs)
- Event handlers for:
  * ACHIEVEMENT_TRIGGERED
  * CONTESTANT_DIED
  * PLAYER_LEVEL_UP
  * Floor rule modifications
  * Dynamic difficulty adjustments
- Metadata enrichment for rewards (sponsor tags, achievement unlocks)
- Persistent announcer history beyond current run

=============================================================================
]]
