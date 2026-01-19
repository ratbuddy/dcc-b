-- /mod/dccb/systems/floor_director.lua
-- Floor Director system module
-- Phase 1 Task 6: Floor progression, rule sets, and mutation activation
-- 
-- Responsibilities:
-- - Floor progression state management
-- - FloorRuleSet selection based on floor number
-- - Rule and mutation activation into FloorState
-- - Generation parameter mutation (attaching floor descriptors)
-- - Spawn weight adjustment helpers (Phase-1 structured but stubbed)
--
-- This module is engine-agnostic and must not call ToME or any engine APIs.

local log = require("mod.dccb.core.log")
local Events = require("mod.dccb.core.events")

local FloorDirector = {}

-- Private module state
local module_state = {
  initialized = false,
  state_ref = nil,
  data_ref = nil,
  rng_stream = nil
}

-- Private helper: Create a deep copy of a table (one level deep for arrays/objects)
-- @param tbl table - the table to copy
-- @return table - a new table with copied values
local function deep_copy_table(tbl)
  if type(tbl) ~= "table" then
    return tbl
  end
  
  local copy = {}
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      -- Copy nested table (one level)
      copy[key] = deep_copy_table(value)
    else
      copy[key] = value
    end
  end
  return copy
end

-- Private helper: Create a defensive copy of a weighted list
-- Used to ensure no input mutation in adjust_spawn_weights
-- @param weights table - array of weighted items {id, w, ...}
-- @return table - new array with copied items
local function copy_weighted_list(weights)
  local copy = {}
  for _, item in ipairs(weights) do
    local new_item = {id = item.id, w = item.w}
    for key, value in pairs(item) do
      if key ~= "id" and key ~= "w" then
        new_item[key] = value
      end
    end
    table.insert(copy, new_item)
  end
  return copy
end

-- Initialize the Floor Director
-- @param state table - the global DCCBState singleton
-- @param data table - bootstrap data including floor_rules_by_id and mutations_by_id
-- @param rng table - RNG object with stream() method
function FloorDirector.init(state, data, rng)
  log.debug("FloorDirector.init: initializing")
  
  -- Validate inputs
  if not state then
    log.error("FloorDirector.init: state is nil")
    error("FloorDirector.init: state is required")
  end
  
  if not data then
    log.error("FloorDirector.init: data is nil")
    error("FloorDirector.init: data is required")
  end
  
  if not data.floor_rules_by_id then
    log.error("FloorDirector.init: data.floor_rules_by_id is missing")
    error("FloorDirector.init: data.floor_rules_by_id is required")
  end
  
  if not rng then
    log.error("FloorDirector.init: rng is nil")
    error("FloorDirector.init: rng is required")
  end
  
  -- Validate that at least one floor rule exists (Phase-1 expects floor 1)
  local floor_rule_count = 0
  local has_floor_1 = false
  for _, rule_set in pairs(data.floor_rules_by_id) do
    floor_rule_count = floor_rule_count + 1
    if rule_set.floor_number == 1 then
      has_floor_1 = true
    end
  end
  
  if floor_rule_count == 0 then
    log.warn("FloorDirector.init: no floor rules found in data.floor_rules_by_id")
  elseif not has_floor_1 then
    log.warn("FloorDirector.init: no floor rule set defined for floor 1")
  end
  
  -- Store references
  module_state.state_ref = state
  module_state.data_ref = data
  module_state.rng_stream = rng:stream("floor")
  module_state.initialized = true
  
  log.info("FloorDirector initialized with", floor_rule_count, "floor rule(s)")
end

-- Set the current floor number
-- Clears/replaces the floor state, emits FLOOR_SET event
-- @param state table - the global DCCBState singleton
-- @param n number - the floor number to set
function FloorDirector.set_floor(state, n)
  log.debug("FloorDirector.set_floor: setting floor to", n)
  
  if not module_state.initialized then
    log.error("FloorDirector.set_floor: module not initialized")
    error("FloorDirector.set_floor: call init() first")
  end
  
  if type(n) ~= "number" or n < 1 then
    log.error("FloorDirector.set_floor: floor number must be a positive number, got:", n)
    error("FloorDirector.set_floor: invalid floor number")
  end
  
  -- Set floor number and clear state
  state.floor.number = n
  state.floor.state = nil
  
  log.info("FloorDirector: floor set to", n)
  
  -- Emit FLOOR_SET event
  Events.emit("FLOOR_SET", {
    floor_number = n
  })
end

-- Get the current floor state
-- @param state table - the global DCCBState singleton
-- @return table - the FloorState, or nil if not yet activated
function FloorDirector.get_state(state)
  if not state.floor.state then
    log.debug("FloorDirector.get_state: floor state not yet activated")
    return nil
  end
  
  return state.floor.state
end

-- Activate rules for the current floor
-- Selects FloorRuleSet, builds FloorState, resolves mutations
-- @param state table - the global DCCBState singleton
-- @param rng table - RNG object (for consistency, though we use cached stream)
-- @return table - the created FloorState
function FloorDirector.activate_rules(state, rng)
  log.debug("FloorDirector.activate_rules: starting rule activation")
  
  if not module_state.initialized then
    log.error("FloorDirector.activate_rules: module not initialized")
    error("FloorDirector.activate_rules: call init() first")
  end
  
  local floor_number = state.floor.number
  if not floor_number then
    log.error("FloorDirector.activate_rules: floor number not set")
    error("FloorDirector.activate_rules: call set_floor() first")
  end
  
  local data = module_state.data_ref
  
  -- Phase-1 rule: find rule set where floor_number == n
  -- If multiple match: deterministic pick (sort by id, pick first, log WARN)
  -- If none: ERROR and fail fast
  local matching_rule_sets = {}
  for id, rule_set in pairs(data.floor_rules_by_id) do
    if rule_set.floor_number == floor_number then
      table.insert(matching_rule_sets, {id = id, rule_set = rule_set})
    end
  end
  
  if #matching_rule_sets == 0 then
    log.error("FloorDirector.activate_rules: no rule set found for floor", floor_number)
    error("FloorDirector.activate_rules: no rule set defined for floor " .. floor_number)
  end
  
  -- Sort for determinism
  table.sort(matching_rule_sets, function(a, b) return a.id < b.id end)
  
  if #matching_rule_sets > 1 then
    local ids = {}
    for _, item in ipairs(matching_rule_sets) do
      table.insert(ids, item.id)
    end
    log.warn("FloorDirector.activate_rules: multiple rule sets match floor", floor_number, ":", table.concat(ids, ", "))
    log.warn("FloorDirector.activate_rules: using first match (deterministic):", matching_rule_sets[1].id)
  end
  
  local selected = matching_rule_sets[1]
  local rule_set = selected.rule_set
  local rule_set_id = selected.id
  
  log.debug("FloorDirector.activate_rules: selected rule set:", rule_set_id)
  
  -- Build FloorState
  local floor_state = {
    floor_number = floor_number,
    rule_set_id = rule_set_id,
    active_rules = {},
    active_mutations = {},
    spawn_modifiers = {},
    loot_modifiers = {},
    event_injections = {}
  }
  
  -- Copy active_rules (array of rule IDs)
  if rule_set.rules then
    for _, rule_id in ipairs(rule_set.rules) do
      table.insert(floor_state.active_rules, rule_id)
    end
  end
  
  -- Resolve mutations
  if rule_set.mutations then
    for _, activation in ipairs(rule_set.mutations) do
      local mutation_id = activation.id
      local params = activation.params or {}
      
      -- Confirm mutation id exists in data.mutations_by_id (if mutations loaded)
      if data.mutations_by_id then
        if not data.mutations_by_id[mutation_id] then
          -- WARN in Phase-1 (or ERROR if strict flag exists in config)
          local strict = state.run and state.run.config and state.run.config.enable_validation_strict
          if strict then
            log.error("FloorDirector.activate_rules: mutation '" .. mutation_id .. "' not found in mutations_by_id (strict mode)")
            error("FloorDirector.activate_rules: mutation '" .. mutation_id .. "' not found")
          else
            log.warn("FloorDirector.activate_rules: mutation '" .. mutation_id .. "' not found in mutations_by_id")
          end
        else
          log.debug("FloorDirector.activate_rules: resolved mutation:", mutation_id)
        end
      end
      
      -- Store {id=..., params=...} into active_mutations
      table.insert(floor_state.active_mutations, {
        id = mutation_id,
        params = params
      })
    end
  end
  
  -- Copy spawn_modifiers (from rule set)
  if rule_set.spawn_modifiers then
    for key, value in pairs(rule_set.spawn_modifiers) do
      floor_state.spawn_modifiers[key] = value
    end
  end
  
  -- Copy loot_modifiers (from rule set)
  if rule_set.loot_modifiers then
    for key, value in pairs(rule_set.loot_modifiers) do
      floor_state.loot_modifiers[key] = value
    end
  end
  
  -- Copy event_injections (from rule set)
  if rule_set.event_injections then
    for _, injection in ipairs(rule_set.event_injections) do
      table.insert(floor_state.event_injections, injection)
    end
  end
  
  -- Set state.floor.state
  state.floor.state = floor_state
  
  -- Log at INFO: floor number, rule set id, active rules list
  log.info("FloorDirector: rules activated for floor", floor_number)
  log.info("  Rule Set ID:", rule_set_id)
  log.info("  Active Rules:", table.concat(floor_state.active_rules, ", "))
  log.info("  Active Mutations:", #floor_state.active_mutations)
  
  -- Emit FLOOR_START event with snapshot payload
  local mutation_ids = {}
  for _, mut in ipairs(floor_state.active_mutations) do
    table.insert(mutation_ids, mut.id)
  end
  
  Events.emit("FLOOR_START", {
    floor_number = floor_number,
    rule_set_id = rule_set_id,
    active_rules = floor_state.active_rules,
    active_mutation_ids = mutation_ids
  })
  
  return floor_state
end

-- Apply generation mutations to generation parameters
-- Attaches a dccb_floor subtable with floor state descriptors
-- @param state table - the global DCCBState singleton
-- @param gen_params table - generation parameters (engine-specific structure)
-- @return table - modified gen_params with dccb_floor attached (new table, input not mutated)
function FloorDirector.apply_generation_mutations(state, gen_params)
  log.debug("FloorDirector.apply_generation_mutations: starting")
  
  if not gen_params then
    log.warn("FloorDirector.apply_generation_mutations: gen_params is nil, creating empty table")
    gen_params = {}
  end
  
  local floor_state = state.floor.state
  if not floor_state then
    log.warn("FloorDirector.apply_generation_mutations: floor state not activated, returning gen_params unchanged")
    return gen_params
  end
  
  -- Create a modified copy (don't mutate input)
  local modified = {}
  for key, value in pairs(gen_params) do
    modified[key] = value
  end
  
  -- Attach dccb_floor subtable (deep copy to prevent mutation of floor_state)
  modified.dccb_floor = {
    floor_number = floor_state.floor_number,
    rule_set_id = floor_state.rule_set_id,
    active_rules = deep_copy_table(floor_state.active_rules),
    active_mutations = deep_copy_table(floor_state.active_mutations),
    spawn_modifiers = deep_copy_table(floor_state.spawn_modifiers),
    loot_modifiers = deep_copy_table(floor_state.loot_modifiers)
  }
  
  log.debug("FloorDirector.apply_generation_mutations: complete")
  log.debug("  Floor:", floor_state.floor_number)
  log.debug("  Rule Set:", floor_state.rule_set_id)
  log.debug("  Mutations:", #floor_state.active_mutations)
  
  return modified
end

-- Adjust spawn weights based on floor modifiers
-- Phase-1: implement structure only (apply faction_weight_overrides if provided)
-- @param state table - the global DCCBState singleton
-- @param spawn_type string - type of spawn (e.g., "enemy", "item")
-- @param weights table - array of weighted spawn candidates { id, w, ... }
-- @param context table - spawn context (for future use)
-- @return table - adjusted weights (new table, input not mutated)
function FloorDirector.adjust_spawn_weights(state, spawn_type, weights, context)
  log.debug("FloorDirector.adjust_spawn_weights: starting for spawn_type:", spawn_type)
  
  if not weights or #weights == 0 then
    log.debug("FloorDirector.adjust_spawn_weights: weights empty, returning empty list")
    return {}
  end
  
  local floor_state = state.floor.state
  if not floor_state then
    log.debug("FloorDirector.adjust_spawn_weights: floor state not activated, returning copy of weights")
    return copy_weighted_list(weights)
  end
  
  -- Phase-1: apply spawn_modifiers.faction_weight_overrides if provided
  local spawn_modifiers = floor_state.spawn_modifiers or {}
  local faction_weight_overrides = spawn_modifiers.faction_weight_overrides
  
  if not faction_weight_overrides or #faction_weight_overrides == 0 then
    log.debug("FloorDirector.adjust_spawn_weights: no faction_weight_overrides, returning copy of weights")
    return copy_weighted_list(weights)
  end
  
  -- Build override map
  local override_map = {}
  for _, override in ipairs(faction_weight_overrides) do
    if override.id then
      override_map[override.id] = override.w or 1.0
    end
  end
  
  local input_count = #weights
  
  -- Apply overrides
  local adjusted = {}
  for _, item in ipairs(weights) do
    local id = item.id
    
    -- Create new weighted item (don't mutate input)
    local new_item = {
      id = id,
      w = item.w or 1.0
    }
    
    -- Apply override if present
    if override_map[id] then
      local old_weight = new_item.w
      new_item.w = override_map[id]
      log.debug("FloorDirector.adjust_spawn_weights: override faction", id, "weight:", old_weight, "->", new_item.w)
    end
    
    -- Copy other fields
    for key, value in pairs(item) do
      if key ~= "id" and key ~= "w" then
        new_item[key] = value
      end
    end
    
    table.insert(adjusted, new_item)
  end
  
  log.debug("FloorDirector.adjust_spawn_weights: complete (input:", input_count, "output:", #adjusted, ")")
  
  return adjusted
end

return FloorDirector

--[[
========================
MODULE GUARANTEES
========================

This module guarantees:
1. Deterministic rule set selection given the same seed + data
2. Floor state is always complete after activate_rules() succeeds
3. All public functions never mutate input parameters
4. All public functions return new tables/copies when modifying data
5. All randomness comes from the "floor" RNG stream (though Phase-1 doesn't use it)
6. No engine-specific calls (no ToME, no Barony APIs)
7. All failures are loud (error() with clear messages)
8. FLOOR_SET event is emitted on set_floor()
9. FLOOR_START event is emitted on activate_rules()
10. Logging at INFO for rule activation, DEBUG for mutations/gen/spawn, ERROR for missing rules

========================
EXPLICITLY DEFERRED
========================

The following are NOT responsibilities of Floor Director in Phase-1:
- Region logic → Region Director
- Contestant logic → Contestant System
- Meta layer logic → Meta Layer
- Dungeon generation → Integration layer
- Entity spawning → Integration layer
- UI rendering → UI layer
- Actual mutation "effect" math beyond attaching descriptors

Phase 1 limitations:
- adjust_spawn_weights: implements structure only (faction_weight_overrides)
- No actual mutation effect computation (just stores descriptors)
- No conditional mutation activation (when clauses not evaluated)
- No mutation stacking logic (stored but not applied)
- No dynamic rule selection (only by floor_number)

========================
INTEGRATION NOTES
========================

Integration layer responsibilities:
1. Call set_floor() before each floor transition
2. Call activate_rules() after set_floor() to build floor state
3. Call apply_generation_mutations() to attach floor descriptors to generation params
4. Call adjust_spawn_weights() during spawn interception to apply floor modifiers
5. Never mutate returned FloorState directly - it's authoritative
6. Translate dccb_floor subtable to engine-specific generation knobs
7. Implement actual mutation effect math based on active_mutations descriptors

Event listeners should:
- Subscribe to FLOOR_SET to track floor progression
- Subscribe to FLOOR_START to react to rule activation
- Never modify state.floor directly - always use FloorDirector functions
--]]
