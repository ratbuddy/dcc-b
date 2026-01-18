-- /mod/dccb/core/validate.lua
-- Runtime validation for DCC-Barony data schemas
-- Validates required fields, types, and referential integrity
-- Fails fast with clear error messages via log.lua

local log = require("mod.dccb.core.log")

local Validate = {}

-- Helper: check if a value exists and is not nil
local function required(obj, field, context)
  if obj[field] == nil then
    log.error(context .. ": missing required field '" .. field .. "'")
    error(context .. ": missing required field '" .. field .. "'")
  end
end

-- Helper: check if a value is a specific type
local function check_type(obj, field, expected_type, context)
  if obj[field] ~= nil and type(obj[field]) ~= expected_type then
    log.error(context .. ": field '" .. field .. "' expected " .. expected_type .. ", got " .. type(obj[field]))
    error(context .. ": field '" .. field .. "' expected " .. expected_type .. ", got " .. type(obj[field]))
  end
end

-- Helper: warn about optional missing fields
local function optional_warn(obj, field, context)
  if obj[field] == nil then
    log.warn(context .. ": optional field '" .. field .. "' is missing")
  end
end

-- Validate config schema (defaults/config.json)
-- Required per DataSchemas section 1:
--   version, seed_mode, region_mode, npc_roster_size, logging_level, enable_ui_overlay, difficulty_curve
--   fixed_seed (if seed_mode == "fixed")
--   pinned_region_id (if region_mode == "pinned")
function Validate.config(cfg)
  local context = "config"
  
  if not cfg then
    log.error(context .. ": config object is nil")
    error(context .. ": config object is nil")
  end
  
  -- Required fields
  required(cfg, "version", context)
  check_type(cfg, "version", "string", context)
  
  required(cfg, "seed_mode", context)
  check_type(cfg, "seed_mode", "string", context)
  local valid_seed_modes = {engine = true, fixed = true, time = true}
  if not valid_seed_modes[cfg.seed_mode] then
    log.error(context .. ": seed_mode must be 'engine', 'fixed', or 'time', got '" .. tostring(cfg.seed_mode) .. "'")
    error(context .. ": seed_mode must be 'engine', 'fixed', or 'time'")
  end
  
  -- fixed_seed required if seed_mode == "fixed"
  if cfg.seed_mode == "fixed" then
    required(cfg, "fixed_seed", context)
    check_type(cfg, "fixed_seed", "number", context)
  end
  
  required(cfg, "region_mode", context)
  check_type(cfg, "region_mode", "string", context)
  local valid_region_modes = {random = true, pinned = true, weighted = true}
  if not valid_region_modes[cfg.region_mode] then
    log.error(context .. ": region_mode must be 'random', 'pinned', or 'weighted', got '" .. tostring(cfg.region_mode) .. "'")
    error(context .. ": region_mode must be 'random', 'pinned', or 'weighted'")
  end
  
  -- pinned_region_id required if region_mode == "pinned"
  if cfg.region_mode == "pinned" then
    required(cfg, "pinned_region_id", context)
    check_type(cfg, "pinned_region_id", "string", context)
  end
  
  required(cfg, "npc_roster_size", context)
  check_type(cfg, "npc_roster_size", "number", context)
  
  required(cfg, "logging_level", context)
  check_type(cfg, "logging_level", "string", context)
  local valid_log_levels = {ERROR = true, WARN = true, INFO = true, DEBUG = true}
  if not valid_log_levels[cfg.logging_level] then
    log.error(context .. ": logging_level must be 'ERROR', 'WARN', 'INFO', or 'DEBUG', got '" .. tostring(cfg.logging_level) .. "'")
    error(context .. ": logging_level must be 'ERROR', 'WARN', 'INFO', or 'DEBUG'")
  end
  
  required(cfg, "enable_ui_overlay", context)
  check_type(cfg, "enable_ui_overlay", "boolean", context)
  
  required(cfg, "difficulty_curve", context)
  check_type(cfg, "difficulty_curve", "string", context)
  
  -- Optional fields
  optional_warn(cfg, "data_packs", context)
  optional_warn(cfg, "enable_validation_strict", context)
  optional_warn(cfg, "debug_print_active_tables", context)
  
  log.debug("config validation passed")
end

-- Validate region profile schema (regions/*.json)
-- Required per DataSchemas section 2.2:
--   id, name, description, tags, asset_sets, enemy_factions, hazard_rules, npc_archetypes, loot_bias, traversal_modifiers
function Validate.region_profile(obj)
  local context = "region_profile"
  
  if not obj then
    log.error(context .. ": region profile object is nil")
    error(context .. ": region profile object is nil")
  end
  
  -- Required fields
  required(obj, "id", context)
  check_type(obj, "id", "string", context)
  context = "region_profile[" .. obj.id .. "]"
  
  required(obj, "name", context)
  check_type(obj, "name", "string", context)
  
  required(obj, "description", context)
  check_type(obj, "description", "string", context)
  
  required(obj, "tags", context)
  check_type(obj, "tags", "table", context)
  
  required(obj, "asset_sets", context)
  check_type(obj, "asset_sets", "table", context)
  
  required(obj, "enemy_factions", context)
  check_type(obj, "enemy_factions", "table", context)
  
  required(obj, "hazard_rules", context)
  check_type(obj, "hazard_rules", "table", context)
  
  required(obj, "npc_archetypes", context)
  check_type(obj, "npc_archetypes", "table", context)
  
  required(obj, "loot_bias", context)
  check_type(obj, "loot_bias", "table", context)
  -- loot_bias.table_weights is required
  if obj.loot_bias then
    required(obj.loot_bias, "table_weights", context .. ".loot_bias")
    check_type(obj.loot_bias, "table_weights", "table", context .. ".loot_bias")
  end
  
  required(obj, "traversal_modifiers", context)
  check_type(obj, "traversal_modifiers", "table", context)
  
  log.debug("region_profile[" .. obj.id .. "] validation passed")
end

-- Validate floor rule set schema (floor_rules/*.json)
-- Required per DataSchemas section 3.2:
--   id, name, description, floor_number, rules, mutations, spawn_modifiers, loot_modifiers, event_injections
function Validate.floor_rule_set(obj)
  local context = "floor_rule_set"
  
  if not obj then
    log.error(context .. ": floor rule set object is nil")
    error(context .. ": floor rule set object is nil")
  end
  
  -- Required fields
  required(obj, "id", context)
  check_type(obj, "id", "string", context)
  context = "floor_rule_set[" .. obj.id .. "]"
  
  required(obj, "name", context)
  check_type(obj, "name", "string", context)
  
  required(obj, "description", context)
  check_type(obj, "description", "string", context)
  
  required(obj, "floor_number", context)
  check_type(obj, "floor_number", "number", context)
  
  required(obj, "rules", context)
  check_type(obj, "rules", "table", context)
  
  required(obj, "mutations", context)
  check_type(obj, "mutations", "table", context)
  
  required(obj, "spawn_modifiers", context)
  check_type(obj, "spawn_modifiers", "table", context)
  
  required(obj, "loot_modifiers", context)
  check_type(obj, "loot_modifiers", "table", context)
  
  required(obj, "event_injections", context)
  check_type(obj, "event_injections", "table", context)
  
  log.debug("floor_rule_set[" .. obj.id .. "] validation passed")
end

-- Validate referential integrity across loaded data
-- Checks that IDs referenced in one data type exist in another
-- Per problem statement:
--   - region npc_archetypes IDs exist
--   - region loot_bias table_weights IDs exist
--   - floor mutations IDs exist
function Validate.referential_integrity(data)
  local context = "referential_integrity"
  
  if not data then
    log.error(context .. ": data object is nil")
    error(context .. ": data object is nil")
  end
  
  -- Warn if categories are empty (acceptable in Phase 1)
  if not data.npc_archetypes_by_id or not next(data.npc_archetypes_by_id) then
    log.warn(context .. ": npc_archetypes_by_id is empty (acceptable in Phase 1)")
  end
  
  if not data.reward_tables_by_id or not next(data.reward_tables_by_id) then
    log.warn(context .. ": reward_tables_by_id is empty (acceptable in Phase 1)")
  end
  
  if not data.mutations_by_id or not next(data.mutations_by_id) then
    log.warn(context .. ": mutations_by_id is empty (acceptable in Phase 1)")
  end
  
  -- Check region npc_archetypes references
  if data.regions_by_id then
    for region_id, region in pairs(data.regions_by_id) do
      if region.npc_archetypes then
        for _, archetype_ref in ipairs(region.npc_archetypes) do
          if archetype_ref.id then
            if data.npc_archetypes_by_id and not data.npc_archetypes_by_id[archetype_ref.id] then
              log.warn(context .. ": region[" .. region_id .. "] references unknown npc_archetype '" .. archetype_ref.id .. "'")
            end
          end
        end
      end
    end
  end
  
  -- Check region loot_bias table_weights references
  if data.regions_by_id then
    for region_id, region in pairs(data.regions_by_id) do
      if region.loot_bias and region.loot_bias.table_weights then
        for _, table_ref in ipairs(region.loot_bias.table_weights) do
          if table_ref.id then
            if data.reward_tables_by_id and not data.reward_tables_by_id[table_ref.id] then
              log.warn(context .. ": region[" .. region_id .. "] references unknown reward_table '" .. table_ref.id .. "'")
            end
          end
        end
      end
    end
  end
  
  -- Check floor rule mutations references
  if data.floor_rules_by_id then
    for floor_id, floor_rule in pairs(data.floor_rules_by_id) do
      if floor_rule.mutations then
        for _, mutation_ref in ipairs(floor_rule.mutations) do
          if mutation_ref.id then
            if data.mutations_by_id and not data.mutations_by_id[mutation_ref.id] then
              log.warn(context .. ": floor_rule[" .. floor_id .. "] references unknown mutation '" .. mutation_ref.id .. "'")
            end
          end
        end
      end
    end
  end
  
  log.debug("referential_integrity validation passed")
end

return Validate
