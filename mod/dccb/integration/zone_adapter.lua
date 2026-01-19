-- /mod/dccb/integration/zone_adapter.lua
-- ToME Zone Adapter - Phase-1 Task 9B
-- Engine translation surface between DCCB and ToME zone generation
--
-- This module defines the contract where ToME generator logic will later live.
-- Phase-1: NO ToME API calls - only contract definition and logging.

local log = require("mod.dccb.core.log")

local ZoneAdapter = {}

-------------------------------------------------------------------------------
-- ZoneAdapter.apply_region_constraints(gen_params, dccb_region, state)
-- Apply region-derived constraints to zone generation parameters
--
-- Phase-1 Behavior:
-- - Accepts gen_params and dccb_region descriptor
-- - Logs DEBUG listing region properties
-- - Returns new copy of gen_params (unchanged content in Phase-1)
--
-- @param gen_params table - zone generation parameters (will not be mutated)
-- @param dccb_region table - region descriptor from RegionDirector
-- @param state table - global DCCB state (for context)
-- @return table - new gen_params with region constraints applied
-------------------------------------------------------------------------------
function ZoneAdapter.apply_region_constraints(gen_params, dccb_region, state)
  log.debug("ZoneAdapter.apply_region_constraints: starting")
  
  -- Validate inputs
  gen_params = gen_params or {}
  dccb_region = dccb_region or {}
  state = state or {}
  
  -- Log region descriptor properties
  log.debug("  Region ID:", dccb_region.id or "(none)")
  
  -- Log asset_sets
  local asset_sets = dccb_region.asset_sets or {}
  if type(asset_sets) == "table" then
    local asset_set_count = 0
    for _ in pairs(asset_sets) do
      asset_set_count = asset_set_count + 1
    end
    log.debug("  Asset Sets:", asset_set_count, "defined")
  else
    log.debug("  Asset Sets: none")
  end
  
  -- Log hazard_rules
  local hazard_rules = dccb_region.hazard_rules or {}
  if type(hazard_rules) == "table" then
    local hazard_count = 0
    for _ in pairs(hazard_rules) do
      hazard_count = hazard_count + 1
    end
    log.debug("  Hazard Rules:", hazard_count, "defined")
  else
    log.debug("  Hazard Rules: none")
  end
  
  -- Log traversal_modifiers
  local traversal_modifiers = dccb_region.traversal_modifiers or {}
  if type(traversal_modifiers) == "table" then
    local modifier_count = 0
    for _ in pairs(traversal_modifiers) do
      modifier_count = modifier_count + 1
    end
    log.debug("  Traversal Modifiers:", modifier_count, "defined")
  else
    log.debug("  Traversal Modifiers: none")
  end
  
  -- Phase-1: Create shallow copy of gen_params (unchanged content)
  local result = {}
  for key, value in pairs(gen_params) do
    result[key] = value
  end
  
  -- Store region descriptor in result for downstream use
  result.dccb_region = dccb_region
  
  log.debug("ZoneAdapter.apply_region_constraints: complete (unchanged in Phase-1)")
  
  -- TODO: Phase-2 implementation points
  -- TODO: Tileset swapping based on asset_sets
  --       - Map dccb_region.asset_sets to ToME tileset IDs
  --       - Override gen_params.tileset or equivalent ToME parameter
  --       - Consider asset set weights and selection logic
  --
  -- TODO: Terrain weighting based on region profile
  --       - Map region terrain preferences to ToME terrain type weights
  --       - Override gen_params terrain distribution parameters
  --       - Apply region-specific floor/wall/feature ratios
  --
  -- TODO: Environmental modifiers from hazard_rules
  --       - Map hazard_rules to ToME zone effects (poison, darkness, etc.)
  --       - Set environmental intensity parameters
  --       - Configure trap density and types based on hazards
  --
  -- TODO: Traversal modifiers application
  --       - Map traversal_modifiers to ToME generator knobs
  --       - Adjust corridor width, room density, connectivity
  --       - Configure stair/ladder placement based on verticality bias
  
  return result
end

-------------------------------------------------------------------------------
-- ZoneAdapter.apply_floor_mutations(gen_params, dccb_floor, state)
-- Apply floor-derived mutations to zone generation parameters
--
-- Phase-1 Behavior:
-- - Accepts gen_params and dccb_floor descriptor
-- - Logs DEBUG listing floor properties
-- - Returns new copy of gen_params (unchanged content in Phase-1)
--
-- @param gen_params table - zone generation parameters (will not be mutated)
-- @param dccb_floor table - floor descriptor from FloorDirector
-- @param state table - global DCCB state (for context)
-- @return table - new gen_params with floor mutations applied
-------------------------------------------------------------------------------
function ZoneAdapter.apply_floor_mutations(gen_params, dccb_floor, state)
  log.debug("ZoneAdapter.apply_floor_mutations: starting")
  
  -- Validate inputs
  gen_params = gen_params or {}
  dccb_floor = dccb_floor or {}
  state = state or {}
  
  -- Log floor descriptor properties
  log.debug("  Floor Number:", dccb_floor.floor_number or "(none)")
  log.debug("  Rule Set ID:", dccb_floor.rule_set_id or "(none)")
  
  -- Log active_rules
  local active_rules = dccb_floor.active_rules or {}
  if type(active_rules) == "table" then
    if #active_rules > 0 then
      log.debug("  Active Rules:", table.concat(active_rules, ", "))
    else
      log.debug("  Active Rules: none")
    end
  else
    log.debug("  Active Rules: invalid format")
  end
  
  -- Log active_mutations
  local active_mutations = dccb_floor.active_mutations or {}
  if type(active_mutations) == "table" then
    if #active_mutations > 0 then
      log.debug("  Active Mutations:", #active_mutations, "defined")
    else
      log.debug("  Active Mutations: none")
    end
  else
    log.debug("  Active Mutations: invalid format")
  end
  
  -- Phase-1: Create shallow copy of gen_params (unchanged content)
  local result = {}
  for key, value in pairs(gen_params) do
    result[key] = value
  end
  
  -- Store floor descriptor in result for downstream use
  result.dccb_floor = dccb_floor
  
  log.debug("ZoneAdapter.apply_floor_mutations: complete (unchanged in Phase-1)")
  
  -- TODO: Phase-2 implementation points
  -- TODO: Zone difficulty shaping based on floor number and rules
  --       - Map floor_number to ToME zone difficulty multiplier
  --       - Apply active_rules difficulty modifiers
  --       - Adjust enemy level ranges and elite spawn rates
  --
  -- TODO: Spawn tables modification based on active_rules
  --       - Filter enemy pools based on floor rules
  --       - Adjust spawn weights for different enemy types
  --       - Apply faction restrictions from floor rules
  --
  -- TODO: Loot density adjustment based on floor state
  --       - Modify loot drop rates based on floor_number
  --       - Apply active_rules loot multipliers
  --       - Adjust treasure room frequency
  --
  -- TODO: Event injectors from active_mutations
  --       - Inject special events/encounters based on mutations
  --       - Configure scripted sequences triggered by floor rules
  --       - Set up environmental events (collapses, floods, etc.)
  
  return result
end

-------------------------------------------------------------------------------
-- ZoneAdapter.prepare_zone(gen_params, state)
-- Final pre-generation step that applies all DCCB constraints
-- Orchestrates apply_region_constraints and apply_floor_mutations
--
-- Phase-1 Behavior:
-- - Retrieves region and floor descriptors from state
-- - Calls apply_region_constraints
-- - Calls apply_floor_mutations
-- - Logs INFO confirmation
-- - Returns final gen_params
--
-- @param gen_params table - initial zone generation parameters
-- @param state table - global DCCB state containing region and floor info
-- @return table - final gen_params ready for ToME zone generation
-------------------------------------------------------------------------------
function ZoneAdapter.prepare_zone(gen_params, state)
  log.debug("ZoneAdapter.prepare_zone: starting")
  
  -- Validate inputs
  gen_params = gen_params or {}
  state = state or {}
  
  -- Extract region and floor descriptors from state
  local dccb_region = {}
  if state.region and state.region.profile then
    dccb_region = state.region.profile
    dccb_region.id = state.region.id
  end
  
  local dccb_floor = {}
  if state.floor and state.floor.state then
    dccb_floor = state.floor.state
    dccb_floor.floor_number = state.floor.number
  end
  
  log.debug("ZoneAdapter.prepare_zone: applying region constraints")
  local modified = ZoneAdapter.apply_region_constraints(gen_params, dccb_region, state)
  
  log.debug("ZoneAdapter.prepare_zone: applying floor mutations")
  modified = ZoneAdapter.apply_floor_mutations(modified, dccb_floor, state)
  
  -- Log high-level confirmation
  log.info("Zone prepared by DCCB ZoneAdapter (Phase-1 stub)")
  log.debug("  Region:", dccb_region.id or "(none)")
  log.debug("  Floor:", dccb_floor.floor_number or "(none)")
  
  return modified
end

return ZoneAdapter

--[[
===============================================================================
PHASE-1 GUARANTEES
===============================================================================

What this adapter guarantees in Phase-1:
-----------------------------------------
1. Contract Stability:
   - All three public functions (apply_region_constraints, apply_floor_mutations, 
     prepare_zone) are defined and callable
   - Function signatures match DCC-Engineering specifications
   - Return types are consistent (always return new table, never mutate input)

2. Logging Visibility:
   - DEBUG logs show all region properties (id, asset_sets, hazard_rules, 
     traversal_modifiers)
   - DEBUG logs show all floor properties (floor_number, rule_set_id, 
     active_rules, active_mutations)
   - INFO log confirms zone preparation lifecycle
   - No table dumps - only structured property listings

3. Data Pass-Through:
   - gen_params are copied, not mutated
   - dccb_region and dccb_floor descriptors are attached to result
   - Downstream systems can access region/floor metadata via gen_params
   - No actual ToME parameter modifications in Phase-1

4. Integration Points Documented:
   - TODO comments clearly mark all deferred ToME work
   - Each TODO explains what must be implemented for Phase-2
   - Clear separation between Phase-1 stubs and Phase-2 implementation

===============================================================================
FUTURE ToME WORK (Phase-2+)
===============================================================================

What future ToME work must implement here:
-------------------------------------------
1. Tileset Translation (apply_region_constraints):
   - Research ToME's tileset system and zone definition format
   - Map DCCB asset_sets to ToME tileset IDs/parameters
   - Implement tileset selection logic based on region weights
   - Handle fallback tilesets if DCCB asset_sets reference missing ToME assets

2. Terrain Parameter Mapping (apply_region_constraints):
   - Research ToME generator terrain configuration options
   - Map region terrain preferences to ToME terrain type weights
   - Implement terrain distribution parameter overrides
   - Handle region-specific floor/wall/feature ratio adjustments

3. Environmental Effects (apply_region_constraints):
   - Research ToME zone effect system (darkness, poison, etc.)
   - Map DCCB hazard_rules to ToME environmental effect parameters
   - Implement trap density and type configuration
   - Handle intensity scaling based on hazard severity

4. Traversal Modifier Application (apply_region_constraints):
   - Research ToME generator layout parameters (corridor width, room density)
   - Map DCCB traversal_modifiers to ToME generator knobs
   - Implement connectivity and verticality parameter overrides
   - Handle stair/ladder placement based on region verticality bias

5. Difficulty Scaling (apply_floor_mutations):
   - Research ToME zone difficulty system
   - Implement floor_number to ToME difficulty multiplier mapping
   - Apply active_rules difficulty modifiers
   - Adjust enemy level ranges and elite spawn rates

6. Spawn Table Configuration (apply_floor_mutations):
   - Research ToME actor spawning and pool system
   - Implement enemy pool filtering based on floor rules
   - Adjust spawn weights for different enemy types
   - Apply faction restrictions from floor rules

7. Loot System Integration (apply_floor_mutations):
   - Research ToME loot generation and drop rate systems
   - Implement floor-based loot density adjustments
   - Apply active_rules loot multipliers
   - Configure treasure room frequency

8. Event Injection System (apply_floor_mutations):
   - Research ToME scripted event and encounter systems
   - Implement mutation-based event injection
   - Configure scripted sequences triggered by floor rules
   - Set up environmental events (collapses, floods, etc.)

===============================================================================
RELATIONSHIP TO Hooks.on_pre_generate
===============================================================================

How this adapter relates to Hooks.on_pre_generate:
---------------------------------------------------

Hooks.on_pre_generate (tome_hooks.lua):
  - Entry point called by ToME engine before zone generation
  - Orchestrates high-level integration flow
  - Calls RegionDirector.apply_generation_constraints()
  - Calls FloorDirector.apply_generation_mutations()
  - Both of those calls will eventually delegate to ZoneAdapter functions

ZoneAdapter (this module):
  - Translation surface between DCCB data and ToME APIs
  - Called indirectly via RegionDirector and FloorDirector
  - Focused solely on parameter translation, not business logic
  - prepare_zone() provides convenience orchestration for manual testing

Call chain (Phase-2):
  ToME engine
    → Hooks.on_pre_generate(gen_params)
      → RegionDirector.apply_generation_constraints(state, gen_params)
        → ZoneAdapter.apply_region_constraints(gen_params, region, state)
      → FloorDirector.apply_generation_mutations(state, gen_params)
        → ZoneAdapter.apply_floor_mutations(gen_params, floor, state)
    ← returns modified gen_params
  ToME engine uses modified params to generate zone

Key architectural points:
-------------------------
1. ZoneAdapter is engine-specific (ToME) - lives in /integration/
2. RegionDirector and FloorDirector are engine-agnostic - live in /systems/
3. ZoneAdapter translates DCCB concepts → ToME APIs
4. Business logic (what regions/floors mean) stays in systems/
5. Integration glue (how to express it in ToME) stays in ZoneAdapter

This separation ensures:
- Core systems remain portable across engines
- ToME-specific details isolated to integration layer
- Clear contract between business logic and engine adaptation
- Easy to test systems independently of engine

===============================================================================
]]
