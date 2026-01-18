-- /mod/dccb/core/state.lua
-- Single authoritative state container for DCC-Barony mod
-- Manages the global DCCBState singleton that stores all run, region, floor, show, and contestant data
-- This is the only source of truth for the mod's runtime state

local log = require("mod.dccb.core.log")

local State = {}

-- Private: the singleton state instance
local state_instance = nil

-- Create and initialize a new state singleton
-- This should only be called once per run
-- @param run_config table - the configuration for this run (merged defaults + overrides)
-- @param seed number - the RNG seed for this run
-- @return table - the created state instance
function State.new(run_config, seed)
  if state_instance ~= nil then
    log.warn("State.new() called when state already exists - replacing existing state")
  end
  
  -- Create the state structure matching §3.1 of DCC-Barony-Engineering.md
  state_instance = {
    version = "0.1",
    run = {
      seed = seed,
      started_at = os.time(),
      config = run_config or {}
    },
    region = {
      id = nil,
      profile = nil
    },
    floor = {
      number = nil,
      state = nil
    },
    show = {
      state = nil
    },
    contestants = {
      roster = {},
      player_party = {}
    },
    telemetry = {
      events = {}
    }
  }
  
  log.info("DCCBState created with seed:", seed, "at:", state_instance.run.started_at)
  
  return state_instance
end

-- Get the current state singleton
-- Errors if state has not been initialized via State.new()
-- @return table - the current state instance
function State.get()
  if state_instance == nil then
    log.error("State.get() called before State.new() - state is uninitialized")
    error("DCCBState not initialized - call State.new() first")
  end
  return state_instance
end

-- Reset/clear the state singleton
-- Primarily for testing and development purposes
function State.reset()
  log.info("DCCBState reset")
  state_instance = nil
end

-- Helper: Set region information
-- @param id string - the region identifier
-- @param profile table - the region profile data
function State.set_region(id, profile)
  local state = State.get()
  state.region.id = id
  state.region.profile = profile
end

-- Helper: Set floor information
-- @param number number - the floor number
-- @param floor_state table - the floor state data
function State.set_floor(number, floor_state)
  local state = State.get()
  state.floor.number = number
  state.floor.state = floor_state
end

-- Helper: Set show state
-- @param show_state table - the show state data
function State.set_show_state(show_state)
  local state = State.get()
  state.show.state = show_state
end

-- Helper: Set contestants information
-- @param roster table - array of contestant objects
-- @param party_ids table - array of player party IDs
function State.set_contestants(roster, party_ids)
  local state = State.get()
  state.contestants.roster = roster or {}
  state.contestants.player_party = party_ids or {}
end

return State
