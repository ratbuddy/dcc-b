-- /mod/dccb/systems/contestant_system.lua
-- Contestant System module
-- Phase 1 Task 8: Contestant roster generation (engine-agnostic)
--
-- Responsibilities:
-- - Generate initial contestant roster deterministically
-- - Store roster in state.contestants
-- - Emit CONTESTANT_SPAWNED events
-- - Handle CONTESTANT_DIED events
-- - Provide party policy stub
--
-- This module is engine-agnostic and must not call ToME or any engine APIs.

local log = require("mod.dccb.core.log")
local Events = require("mod.dccb.core.events")

local ContestantSystem = {}

-- Private module state
local module_state = {
  initialized = false,
  state_ref = nil,
  data_ref = nil,
  rng_stream = nil
}

-- Initialize the Contestant System
-- @param state table - the global DCCBState singleton
-- @param data table - bootstrap data including npc_archetypes_by_id
-- @param rng table - RNG object with stream() method
function ContestantSystem.init(state, data, rng)
  log.debug("ContestantSystem.init: initializing")
  
  -- Validate inputs
  if not state then
    log.error("ContestantSystem.init: state is nil")
    error("ContestantSystem.init: state is required")
  end
  
  if not data then
    log.error("ContestantSystem.init: data is nil")
    error("ContestantSystem.init: data is required")
  end
  
  if not rng then
    log.error("ContestantSystem.init: rng is nil")
    error("ContestantSystem.init: rng is required")
  end
  
  -- Ensure state.contestants structure exists
  if not state.contestants then
    state.contestants = {}
  end
  
  if not state.contestants.roster then
    state.contestants.roster = {}
  end
  
  if not state.contestants.player_party then
    state.contestants.player_party = {}
  end
  
  -- Store references
  module_state.state_ref = state
  module_state.data_ref = data
  module_state.rng_stream = rng:stream("contestants")
  module_state.initialized = true
  
  log.info("ContestantSystem initialized")
end

-- Generate the initial contestant roster
-- @param state table - the global DCCBState singleton
-- @param rng table - RNG object (for consistency, though we use cached stream)
-- @return table - the generated roster array
function ContestantSystem.generate_roster(state, rng)
  log.debug("ContestantSystem.generate_roster: starting roster generation")
  
  if not module_state.initialized then
    log.error("ContestantSystem.generate_roster: module not initialized")
    error("ContestantSystem.generate_roster: call init() first")
  end
  
  local config = state.run.config
  local data = module_state.data_ref
  local rng_stream = module_state.rng_stream
  
  -- Determine roster size from config or use default
  local roster_size = config.npc_roster_size or 3
  log.debug("ContestantSystem.generate_roster: roster_size =", roster_size)
  
  -- Check if we have archetype data
  local archetypes_by_id = data.npc_archetypes_by_id
  local has_archetypes = false
  local archetype_ids = {}
  
  if archetypes_by_id then
    -- Build list of available archetype IDs
    for id, _ in pairs(archetypes_by_id) do
      table.insert(archetype_ids, id)
      has_archetypes = true
    end
  end
  
  log.debug("ContestantSystem.generate_roster: has_archetypes =", has_archetypes)
  
  -- Generate roster
  local roster = {}
  local contestant_ids = {}
  
  for i = 1, roster_size do
    local archetype_id = nil
    
    if has_archetypes then
      -- Pick archetype deterministically (uniform random with replacement)
      local archetype_index = rng_stream:next_int(1, #archetype_ids)
      archetype_id = archetype_ids[archetype_index]
      log.debug("ContestantSystem.generate_roster: picked archetype", archetype_id, "for contestant", i)
    else
      -- Create placeholder archetype
      archetype_id = "placeholder-archetype-" .. i
      log.debug("ContestantSystem.generate_roster: using placeholder archetype for contestant", i)
    end
    
    -- Create contestant object
    local contestant_id = "contestant-" .. string.format("%02d", i)
    local contestant = {
      id = contestant_id,
      name = "Contestant-" .. string.format("%02d", i),
      archetype_id = archetype_id,
      personality_profile = {
        risk = 0.5,
        teamplay = 0.5,
        greed = 0.5,
        aggression = 0.5
      },
      build_path = {}, -- Stub: will be populated in later phases
      utility_role = "generic", -- Stub: will be refined in later phases
      meta = {
        alive = true,
        level = 1,
        spawn_floor = nil -- Will be set when spawned
      }
    }
    
    table.insert(roster, contestant)
    table.insert(contestant_ids, contestant_id)
    
    -- Emit CONTESTANT_SPAWNED event
    Events.emit("CONTESTANT_SPAWNED", {
      contestant_id = contestant_id,
      archetype_id = archetype_id,
      floor_number = state.floor.number,
      region_id = state.region.id
    })
  end
  
  -- Store roster in state
  state.contestants.roster = roster
  
  log.info("ContestantSystem generated", #roster, "contestant(s)")
  log.debug("ContestantSystem contestant IDs:", table.concat(contestant_ids, ", "))
  
  return roster
end

-- Spawn contestants if needed (Phase-1: deferred to integration)
-- @param state table - the global DCCBState singleton
-- @param engine_context table - engine-specific context (unused in Phase-1)
function ContestantSystem.spawn_contestants_if_needed(state, engine_context)
  log.debug("ContestantSystem.spawn_contestants_if_needed: spawning deferred to integration phase")
  
  if not module_state.initialized then
    log.error("ContestantSystem.spawn_contestants_if_needed: module not initialized")
    error("ContestantSystem.spawn_contestants_if_needed: call init() first")
  end
  
  -- Phase-1: No engine calls, just log
  local roster = state.contestants.roster
  log.debug("ContestantSystem.spawn_contestants_if_needed: roster has", #roster, "contestant(s)")
end

-- Handle events related to contestants
-- @param state table - the global DCCBState singleton
-- @param event table - event payload
function ContestantSystem.on_event(state, event)
  if not module_state.initialized then
    log.error("ContestantSystem.on_event: module not initialized")
    error("ContestantSystem.on_event: call init() first")
  end
  
  local event_name = event.event_id or "UNKNOWN"
  
  if event_name == "CONTESTANT_DIED" then
    -- Handle contestant death
    local contestant_id = event.contestant_id
    log.info("ContestantSystem: contestant died:", contestant_id)
    
    -- Mark contestant as dead in roster
    if contestant_id then
      local roster = state.contestants.roster
      for i, contestant in ipairs(roster) do
        if contestant.id == contestant_id then
          contestant.meta.alive = false
          log.debug("ContestantSystem: marked contestant", contestant_id, "as dead")
          return
        end
      end
      log.warn("ContestantSystem: contestant", contestant_id, "not found in roster")
    else
      log.warn("ContestantSystem: CONTESTANT_DIED event missing contestant_id")
    end
  else
    -- Ignore other events with debug log
    log.debug("ContestantSystem: ignoring event", event_name)
  end
end

-- Get party policy (Phase-1: stub implementation)
-- @param state table - the global DCCBState singleton
-- @return table - party policy configuration
function ContestantSystem.get_party_policy(state)
  if not module_state.initialized then
    log.error("ContestantSystem.get_party_policy: module not initialized")
    error("ContestantSystem.get_party_policy: call init() first")
  end
  
  -- Phase-1: Return simple stub policy
  -- This will be expanded in later phases with more sophisticated behavior
  local policy = {
    mode = "follow_player",
    risk_level = "conservative",
    loot_sharing = "fair",
    aggro_strategy = "defensive"
  }
  
  log.debug("ContestantSystem.get_party_policy: returning stub policy")
  
  return policy
end

return ContestantSystem

--[[
==========================================================================
PHASE-1 vs DEFERRED IMPLEMENTATION NOTES
==========================================================================

PHASE-1 COMPLETE (implemented above):
--------------------------------------
- init(): Creates empty roster/party arrays in state
- generate_roster(): Deterministically generates contestants with stable IDs
  - Picks archetypes from data or creates placeholders
  - Emits CONTESTANT_SPAWNED events
  - Stores roster in state
- spawn_contestants_if_needed(): Logs that spawning is deferred
- on_event(): Handles CONTESTANT_DIED by marking meta.alive flag
- get_party_policy(): Returns simple stub policy

DEFERRED TO INTEGRATION/LATER PHASES:
--------------------------------------
1. ToME Actor Creation:
   - spawn_contestants_if_needed() will need to create actual ToME Actor objects
   - Apply archetype stats, equipment, talents to actors
   - Position actors near player spawn point
   
2. AI Behavior Implementation:
   - Party policy needs to drive actual AI decision-making
   - Risk profiles should affect combat behavior
   - Utility roles should affect party composition strategy
   
3. Build Path Implementation:
   - Currently build_path is empty stub
   - Will need talent tree selection logic
   - Class/race selection based on archetype preferences
   
4. Personality Implementation:
   - Personality profile currently just stored values
   - Needs to influence actual behavior/dialogue/barks
   
5. Advanced Archetype Features:
   - Stat bias application to ToME stats
   - Loadout bias for equipment generation
   - Region affinity for spawn weighting
   
6. Contestant Progression:
   - Level-up logic
   - Skill/talent progression
   - Equipment upgrades
   
7. Party Management:
   - Adding/removing contestants from player_party
   - Party size limits
   - Permadeath handling
   
8. Social Behaviors:
   - Contestant interactions with each other
   - Dialogue/bark systems
   - Morale/relationship systems

All of the above features require ToME-specific APIs and game logic
that are intentionally deferred to keep Phase-1 engine-agnostic.
==========================================================================
--]]
