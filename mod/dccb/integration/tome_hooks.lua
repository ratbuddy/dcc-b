-- /mod/dccb/integration/tome_hooks.lua
-- Integration Hooks for Tales of Maj'Eyal (ToME / T-Engine4)
-- Phase 1 Task 9A: Integration layer stub targeting ToME engine surface
--
-- This file implements the canonical Integration interface from DCC-Engineering §8.5:
-- - Hooks.install()
-- - Hooks.on_run_start(run_ctx)
-- - Hooks.on_pre_generate(gen_params)
-- - Hooks.on_spawn_request(spawn_ctx)
-- - Hooks.on_event(engine_event)
--
-- This is the thin bridge between ToME callbacks and DCCB systems.
-- NO ToME APIs are invented - actual hook registration is deferred pending API research.

local log = require("mod.dccb.core.log")
local Events = require("mod.dccb.core.events")
local Bootstrap = require("mod.dccb.core.bootstrap")
local State = require("mod.dccb.core.state")
local RNG = require("mod.dccb.core.rng")
local RegionDirector = require("mod.dccb.systems.region_director")
local FloorDirector = require("mod.dccb.systems.floor_director")
local MetaLayer = require("mod.dccb.systems.meta_layer")
local ContestantSystem = require("mod.dccb.systems.contestant_system")

local Hooks = {}

-- Private module state
local module_state = {
  installed = false,
  state = nil,
  data = nil,
  rng = nil
}

-------------------------------------------------------------------------------
-- Hooks.install()
-- Initialize the integration layer and register ToME hooks
-- Phase-1: Only logs TODO - does not invent ToME API calls
-------------------------------------------------------------------------------
function Hooks.install()
  log.info("========================================")
  log.info("DCCB ToME Integration: Installing hooks")
  log.info("========================================")
  
  if module_state.installed then
    log.warn("Hooks.install: already installed, skipping")
    return
  end
  
  -- Mark as installed
  module_state.installed = true
  
  -- Phase-1: No actual ToME hook registration
  log.warn("TODO: ToME hook registration not yet implemented")
  log.warn("  Pending research:")
  log.warn("  - ToME lifecycle hooks (on_run_start equivalent)")
  log.warn("  - ToME zone generation hooks (pre-generate equivalent)")
  log.warn("  - ToME spawn interception hooks (spawn_request equivalent)")
  log.warn("  - ToME event system integration (event forwarding)")
  log.info("Hooks.install: stub installation complete")
  log.info("  Call Hooks.on_run_start() manually to initialize DCCB systems")
end

-------------------------------------------------------------------------------
-- Hooks.on_run_start(run_ctx)
-- Initialize DCCB systems and state at run start
-- Implements DCC-Engineering §6.1 lifecycle
-------------------------------------------------------------------------------
function Hooks.on_run_start(run_ctx)
  log.info("========================================")
  log.info("DCCB: Run Start")
  log.info("========================================")
  
  -- Extract run context parameters
  run_ctx = run_ctx or {}
  local seed = run_ctx.seed or os.time()
  local config_overrides = run_ctx.config or {}
  
  log.info("Run seed:", seed)
  
  -- Step 1: Load config + data
  log.info("Step 1/7: Loading configuration and data")
  local data = Bootstrap.load_all_data()
  
  -- Merge config overrides
  local config = data.config
  for key, value in pairs(config_overrides) do
    config[key] = value
    log.debug("Config override:", key, "=", value)
  end
  
  -- Step 2: Initialize state + RNG
  log.info("Step 2/7: Initializing state and RNG")
  local state = State.new(config, seed)
  local rng = RNG.new(seed)
  
  -- Store RNG in state for later use
  state.run.rng = rng
  state.run.bootstrap_data = data
  
  -- Store in module state
  module_state.state = state
  module_state.data = data
  module_state.rng = rng
  
  -- Step 3: Initialize RNG streams (per Engineering §5.2)
  log.info("Step 3/7: Initializing deterministic RNG streams")
  log.debug("  Streams: region, floor, spawns, rewards, contestants")
  -- Streams are created lazily via rng:stream(name)
  
  -- Step 4: Region Director selects region
  log.info("Step 4/7: Region selection")
  RegionDirector.init(state, data, rng)
  local region_id = RegionDirector.select_region(state, rng)
  
  -- Step 5: Meta Layer initializes show state
  log.info("Step 5/7: Meta Layer initialization")
  MetaLayer.init(state, data, rng)
  
  -- Step 6: Contestant System generates roster
  log.info("Step 6/7: Contestant roster generation")
  ContestantSystem.init(state, data, rng)
  local roster = ContestantSystem.generate_roster(state, rng)
  
  -- Step 7: Floor Director sets floor=1 and activates rules
  log.info("Step 7/7: Floor Director initialization")
  FloorDirector.init(state, data, rng)
  FloorDirector.set_floor(state, 1)
  local floor_state = FloorDirector.activate_rules(state, rng)
  
  -- Emit RUN_START event
  Events.emit("RUN_START", {
    seed = seed,
    region_id = region_id,
    floor_number = 1,
    contestant_count = #roster
  })
  
  -- Log required startup info summary (Engineering §10.3)
  log.info("========================================")
  log.info("DCCB Run Started - Summary")
  log.info("========================================")
  log.info("Seed:", seed)
  log.info("Region:", region_id)
  local region_profile = RegionDirector.get_profile(state)
  log.info("Region Name:", region_profile.name or "(unnamed)")
  log.info("Floor 1 Rules:", table.concat(floor_state.active_rules, ", "))
  log.info("Active Mutations:", #floor_state.active_mutations)
  log.info("Contestants:", #roster)
  log.info("========================================")
  
  return state
end

-------------------------------------------------------------------------------
-- Hooks.on_pre_generate(gen_params)
-- Apply region and floor constraints to zone generation parameters
-- Implements DCC-Engineering §6.2
-- Returns new gen_params with dccb_region and dccb_floor subtables
-------------------------------------------------------------------------------
function Hooks.on_pre_generate(gen_params)
  log.debug("Hooks.on_pre_generate: starting")
  
  if not module_state.state then
    log.error("Hooks.on_pre_generate: DCCB not initialized - call on_run_start first")
    error("Hooks.on_pre_generate: DCCB state not initialized")
  end
  
  local state = module_state.state
  
  -- Ensure gen_params is a table
  gen_params = gen_params or {}
  
  -- Step 1: Apply region constraints
  local modified = RegionDirector.apply_generation_constraints(state, gen_params)
  
  -- Step 2: Apply floor mutations
  modified = FloorDirector.apply_generation_mutations(state, modified)
  
  -- Verify required subtables exist
  if not modified.dccb_region then
    log.warn("Hooks.on_pre_generate: dccb_region subtable missing after RegionDirector")
  end
  
  if not modified.dccb_floor then
    log.warn("Hooks.on_pre_generate: dccb_floor subtable missing after FloorDirector")
  end
  
  -- Log summary (don't dump entire table)
  log.debug("Hooks.on_pre_generate: gen_params augmented")
  log.debug("  Region:", modified.dccb_region and modified.dccb_region.id or "none")
  log.debug("  Floor:", modified.dccb_floor and modified.dccb_floor.floor_number or "none")
  
  return modified
end

-------------------------------------------------------------------------------
-- Hooks.on_spawn_request(spawn_ctx)
-- Filter and reweight spawn candidates based on region/floor/meta rules
-- Implements DCC-Engineering §6.3
-- Returns updated spawn_ctx with new candidates
-------------------------------------------------------------------------------
function Hooks.on_spawn_request(spawn_ctx)
  log.debug("Hooks.on_spawn_request: starting")
  
  if not module_state.state then
    log.error("Hooks.on_spawn_request: DCCB not initialized - call on_run_start first")
    error("Hooks.on_spawn_request: DCCB state not initialized")
  end
  
  local state = module_state.state
  
  -- Validate spawn_ctx structure
  spawn_ctx = spawn_ctx or {}
  local spawn_type = spawn_ctx.spawn_type or "unknown"
  local candidates = spawn_ctx.candidates or {}
  local context = spawn_ctx.context or {}
  
  local input_count = #candidates
  log.debug("Hooks.on_spawn_request: spawn_type =", spawn_type, ", candidates =", input_count)
  
  local modified_candidates = candidates
  local floor_state = state.floor.state
  
  -- Branch based on spawn_type
  if spawn_type == "enemy" then
    -- Enemy spawn pipeline
    log.debug("Hooks.on_spawn_request: processing enemy spawn")
    
    -- Step 1: RegionDirector filters enemy pool
    modified_candidates = RegionDirector.filter_enemy_pool(
      state,
      floor_state,
      context,
      modified_candidates
    )
    
    -- Step 2: FloorDirector adjusts spawn weights
    modified_candidates = FloorDirector.adjust_spawn_weights(
      state,
      spawn_type,
      modified_candidates,
      context
    )
    
  elseif spawn_type == "loot" then
    -- Loot spawn pipeline
    log.debug("Hooks.on_spawn_request: processing loot spawn")
    
    -- Step 1: RegionDirector filters loot pool
    modified_candidates = RegionDirector.filter_loot_pool(
      state,
      floor_state,
      context,
      modified_candidates
    )
    
    -- Step 2: MetaLayer applies loot bias (sponsor/achievement)
    modified_candidates = MetaLayer.apply_loot_bias(
      state,
      modified_candidates,
      context
    )
    
    -- Step 3: FloorDirector adjusts spawn weights
    modified_candidates = FloorDirector.adjust_spawn_weights(
      state,
      spawn_type,
      modified_candidates,
      context
    )
    
  else
    -- Unknown spawn type - pass through unchanged
    log.debug("Hooks.on_spawn_request: unknown spawn_type, passing through unchanged")
  end
  
  local output_count = #modified_candidates
  log.debug("Hooks.on_spawn_request: complete (input:", input_count, "output:", output_count, ")")
  
  -- Return updated spawn_ctx (don't mutate input)
  local updated_ctx = {
    spawn_type = spawn_type,
    candidates = modified_candidates,
    context = context
  }
  
  return updated_ctx
end

-------------------------------------------------------------------------------
-- Hooks.on_event(engine_event)
-- Normalize engine events to DCCB format and dispatch to systems
-- Implements DCC-Engineering §6.4 and §7
-------------------------------------------------------------------------------
function Hooks.on_event(engine_event)
  log.debug("Hooks.on_event: received engine event")
  
  if not module_state.state then
    log.debug("Hooks.on_event: DCCB not initialized, ignoring event")
    return
  end
  
  local state = module_state.state
  
  -- Normalize to DCCB event payload
  engine_event = engine_event or {}
  
  local payload = {
    event_id = engine_event.event_id or engine_event.type or "UNKNOWN_EVENT",
    ts = engine_event.ts or os.time(),
    floor_number = state.floor.number,
    region_id = state.region.id
  }
  
  -- Copy all other fields from engine_event
  for key, value in pairs(engine_event) do
    if key ~= "event_id" and key ~= "ts" and key ~= "type" then
      payload[key] = value
    end
  end
  
  local event_id = payload.event_id
  
  log.debug("Hooks.on_event: normalized event_id =", event_id)
  
  -- Emit via event bus (this will also record to telemetry)
  Events.emit(event_id, payload)
  
  -- Phase-1: Forward to MetaLayer and ContestantSystem
  -- Keep this minimal and deterministic
  
  -- MetaLayer handles reward events and announcements
  MetaLayer.on_event(state, payload)
  
  -- ContestantSystem handles contestant lifecycle events
  ContestantSystem.on_event(state, payload)
end

return Hooks

--[[
===============================================================================
PHASE-1 IMPLEMENTATION STATUS
===============================================================================

IMPLEMENTED NOW (Phase-1):
--------------------------
1. Hooks.install():
   - Logs INFO/WARN messages explaining ToME hook binding is TODO
   - No invented ToME API calls
   - Sets installed flag to prevent double-installation
   - Clear guidance for manual invocation during Phase-1

2. Hooks.on_run_start(run_ctx):
   - Full lifecycle implementation per DCC-Engineering §6.1:
     * Loads config + data via Bootstrap
     * Initializes State singleton with seed
     * Creates RNG with deterministic streams (region/floor/spawns/rewards/contestants)
     * Calls RegionDirector.init() and select_region()
     * Calls MetaLayer.init()
     * Calls ContestantSystem.init() and generate_roster()
     * Calls FloorDirector.init(), set_floor(1), activate_rules()
   - Emits RUN_START event via Events.emit() using string literal
   - Logs required startup info summary (seed, region, floor rules list) per §10.3
   - All events use string literals - no constants file edits

3. Hooks.on_pre_generate(gen_params):
   - Calls RegionDirector.apply_generation_constraints()
   - Calls FloorDirector.apply_generation_mutations()
   - Returns new gen_params with dccb_region and dccb_floor subtables
   - Does not mutate input
   - Logs DEBUG summary without dumping entire table
   - Deterministic modifications based on state

4. Hooks.on_spawn_request(spawn_ctx):
   - Branches on spawn_type ("enemy" | "loot" | other)
   - Enemy pipeline: RegionDirector.filter_enemy_pool → FloorDirector.adjust_spawn_weights
   - Loot pipeline: RegionDirector.filter_loot_pool → MetaLayer.apply_loot_bias → FloorDirector.adjust_spawn_weights
   - Returns updated spawn_ctx with new candidates
   - Does not mutate input
   - Logs DEBUG before/after counts
   - Deterministic reweighting based on state

5. Hooks.on_event(engine_event):
   - Normalizes engine event to DCCB payload format
   - Ensures event_id exists (from event_id or type field)
   - Ensures ts exists (uses os.time() if missing)
   - Includes floor_number and region_id from state
   - Emits via Events.emit() using normalized event_id
   - Forwards to MetaLayer.on_event(state, payload)
   - Forwards to ContestantSystem.on_event(state, payload)
   - Minimal and deterministic forwarding logic

6. Event Names:
   - All event emissions use string literal names:
     * "RUN_START" in on_run_start()
     * String literals passed to Events.emit()
   - No modifications to core/events.lua constants
   - Systems emit their own events (REGION_SELECTED, FLOOR_SET, FLOOR_START, CONTESTANT_SPAWNED)

7. Determinism:
   - All randomness via RNG streams from core/rng.lua
   - Named streams: region, floor, spawns, rewards, contestants
   - Seed stored in state for reproducibility
   - No direct math.random() calls

8. Documentation:
   - End-of-file comment block documenting Phase-1 vs deferred work
   - Clear separation of concerns
   - Integration point explanations

DEFERRED PENDING ToME API RESEARCH:
-----------------------------------
1. Hook Registration:
   - Actual ToME lifecycle hook binding (on_run_start equivalent)
   - ToME zone generation hook registration (pre-generate equivalent)
   - ToME spawn interception hook registration (spawn_request equivalent)
   - ToME event system integration (event listener registration)
   - Hook callback signatures and parameter formats

2. Generator Parameter Translation:
   - Translating dccb_region subtable to ToME zone generator parameters
   - Translating dccb_floor subtable to ToME zone generator parameters
   - Mapping asset_sets to ToME tileset/prop selection
   - Mapping hazard_rules to ToME hazard spawning
   - Mapping traversal_modifiers to ToME generation knobs

3. Actor Creation and Tagging:
   - Creating ToME Actor objects for contestants
   - Applying archetype stats/equipment/talents to actors
   - Positioning actors in the game world
   - Tagging spawned entities with DCCB metadata (dccb.region_id, dccb.floor_number, etc.)
   - Actor AI behavior integration with party policies

4. Zone Tagging:
   - Tagging generated zones with region/floor metadata
   - Zone section indexing
   - Special zone flags (sponsor zones, arena pockets, etc.)

5. Event Translation:
   - Mapping ToME engine events to DCCB event names
   - Extracting relevant data from ToME event payloads
   - Determining which ToME events need DCCB handling

6. Integration Testing:
   - Validating hook callbacks fire at correct times
   - Testing that gen_params modifications affect generation
   - Testing that spawn_request modifications affect spawns
   - End-to-end run testing in actual ToME environment

ALL ToME API RESEARCH MUST BE DOCUMENTED IN:
/docs/ToME-Integration-Notes.md (to be created)

===============================================================================
]]
