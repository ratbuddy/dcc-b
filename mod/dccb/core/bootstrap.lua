-- /mod/dccb/core/bootstrap.lua
-- Data loading and initialization for DCC-Barony mod
-- Loads data from /mod/dccb/data/* in required order
-- Validates data and fails fast with readable error messages

local log = require("mod.dccb.core.log")
local Validate = require("mod.dccb.core.validate")

local Bootstrap = {}

-- JSON parsing adapter
-- TODO(barony): Determine if Barony provides a built-in JSON parser
-- TODO(lua): Check if a JSON library is available (dkjson, cjson, etc.)
-- For now, this is a placeholder that will error if JSON parsing is needed
function Bootstrap.parse_json(path, text)
  -- Attempt to find a JSON library
  local json_lib = nil
  local json_lib_name = nil
  
  -- Try common Lua JSON libraries
  local ok, result = pcall(require, "dkjson")
  if ok then
    json_lib = result
    json_lib_name = "dkjson"
  else
    ok, result = pcall(require, "cjson")
    if ok then
      json_lib = result
      json_lib_name = "cjson"
    else
      ok, result = pcall(require, "json")
      if ok then
        json_lib = result
        json_lib_name = "json"
      end
    end
  end
  
  if json_lib then
    log.debug("Using JSON library: " .. json_lib_name)
    local success, decoded = pcall(json_lib.decode or json_lib.parse, text)
    if success then
      return decoded
    else
      log.error("Failed to parse JSON from " .. path .. ": " .. tostring(decoded))
      error("Failed to parse JSON from " .. path)
    end
  else
    log.error("No JSON parsing library available. Cannot parse " .. path)
    log.error("TODO: Install a Lua JSON library (dkjson, cjson, or json)")
    error("JSON parsing not available - cannot load data")
  end
end

-- Read file contents using Lua io.open
-- TODO(barony): Determine if Barony provides a mod-specific file API
-- This uses standard Lua io.open which may not work in all Barony contexts
function Bootstrap.read_file(path)
  log.debug("Attempting to read file: " .. path)
  
  local file, err = io.open(path, "r")
  if not file then
    return nil, err
  end
  
  local content = file:read("*all")
  file:close()
  
  return content, nil
end

-- Load a single JSON file and validate it with the given validator
function Bootstrap.load_json_file(path, validator_func, validator_name)
  log.debug("Loading " .. validator_name .. " from: " .. path)
  
  local content, err = Bootstrap.read_file(path)
  if not content then
    log.error("Failed to read file " .. path .. ": " .. tostring(err))
    error("Failed to read file " .. path)
  end
  
  local obj = Bootstrap.parse_json(path, content)
  
  if validator_func then
    validator_func(obj)
  end
  
  return obj
end

-- List files in a directory
-- TODO(barony): Barony may not provide directory listing capabilities
-- This uses standard Lua which may not be available
-- Returns: array of filenames, or nil + error message
function Bootstrap.list_directory(dir_path)
  log.debug("Attempting to list directory: " .. dir_path)
  
  -- Try using lfs (LuaFileSystem) if available
  local ok, lfs = pcall(require, "lfs")
  if ok then
    local files = {}
    for file in lfs.dir(dir_path) do
      if file ~= "." and file ~= ".." then
        local full_path = dir_path .. "/" .. file
        local attr = lfs.attributes(full_path)
        if attr and attr.mode == "file" and file:match("%.json$") then
          table.insert(files, file)
        end
      end
    end
    return files, nil
  end
  
  -- If lfs is not available, we cannot list directories
  -- Return nil to indicate this limitation
  return nil, "Directory listing not available (lfs module not found)"
end

-- Load all JSON files from a directory into a table indexed by id
-- If directory listing is not available, returns empty table with warning
function Bootstrap.load_directory(dir_path, validator_func, validator_name)
  local data_by_id = {}
  
  local files, err = Bootstrap.list_directory(dir_path)
  
  if not files then
    log.warn("Cannot list directory " .. dir_path .. ": " .. tostring(err))
    log.warn("TODO(barony): Implement file listing or use static file manifest")
    log.warn("Proceeding with empty " .. validator_name .. " collection")
    return data_by_id
  end
  
  log.info("Loading " .. validator_name .. " from " .. dir_path)
  
  for _, filename in ipairs(files) do
    local full_path = dir_path .. "/" .. filename
    local obj = Bootstrap.load_json_file(full_path, validator_func, validator_name)
    
    if obj.id then
      if data_by_id[obj.id] then
        log.warn("Duplicate ID '" .. obj.id .. "' in " .. validator_name .. " (file: " .. filename .. ")")
      end
      data_by_id[obj.id] = obj
    else
      log.warn("Object in " .. filename .. " has no 'id' field, skipping")
    end
  end
  
  local count = 0
  local sample_ids = {}
  for id, _ in pairs(data_by_id) do
    count = count + 1
    if count <= 3 then
      table.insert(sample_ids, id)
    end
  end
  
  log.info("Loaded " .. count .. " " .. validator_name .. (count == 1 and "" or "s"))
  if #sample_ids > 0 then
    log.debug("Sample " .. validator_name .. " IDs: " .. table.concat(sample_ids, ", "))
  end
  
  return data_by_id
end

-- Main data loading function
-- Returns a data table with all loaded content indexed by ID
-- Structure:
--   data.config
--   data.regions_by_id
--   data.floor_rules_by_id
--   data.npc_archetypes_by_id
--   data.reward_tables_by_id
--   data.mutations_by_id
function Bootstrap.load_all_data(base_path_override)
  log.info("========================================")
  log.info("DCC-Barony Bootstrap: Loading all data")
  log.info("========================================")
  
  local data = {}
  
  -- Determine base path for data files
  -- Allow override for testing, otherwise use relative path
  -- TODO(barony): Confirm correct path resolution in Barony mod context
  local base_path = base_path_override or "mod/dccb/data"
  log.debug("Base data path: " .. base_path)
  
  -- Step 1: Load config (required)
  log.info("Step 1/6: Loading config")
  local config_path = base_path .. "/defaults/config.json"
  data.config = Bootstrap.load_json_file(config_path, Validate.config, "config")
  
  -- Apply logging level from config
  log.set_level(data.config.logging_level)
  log.info("Logging level set to: " .. data.config.logging_level)
  
  -- Step 2: Load regions
  log.info("Step 2/6: Loading regions")
  local regions_path = base_path .. "/regions"
  data.regions_by_id = Bootstrap.load_directory(regions_path, Validate.region_profile, "region")
  
  -- Step 3: Load floor rules
  log.info("Step 3/6: Loading floor rules")
  local floor_rules_path = base_path .. "/floor_rules"
  data.floor_rules_by_id = Bootstrap.load_directory(floor_rules_path, Validate.floor_rule_set, "floor_rule")
  
  -- Step 4: Load NPC archetypes
  log.info("Step 4/6: Loading NPC archetypes")
  local npc_archetypes_path = base_path .. "/npc_archetypes"
  data.npc_archetypes_by_id = Bootstrap.load_directory(npc_archetypes_path, nil, "npc_archetype")
  
  -- Step 5: Load reward tables
  log.info("Step 5/6: Loading reward tables")
  local reward_tables_path = base_path .. "/reward_tables"
  data.reward_tables_by_id = Bootstrap.load_directory(reward_tables_path, nil, "reward_table")
  
  -- Step 6: Load mutations
  log.info("Step 6/6: Loading mutations")
  local mutations_path = base_path .. "/mutations"
  data.mutations_by_id = Bootstrap.load_directory(mutations_path, nil, "mutation")
  
  -- Validate referential integrity
  log.info("Validating referential integrity")
  Validate.referential_integrity(data)
  
  log.info("========================================")
  log.info("Bootstrap complete - all data loaded")
  log.info("========================================")
  
  return data
end

--[[
KNOWN LIMITATIONS & TODOs:

1. JSON Parsing:
   - Currently attempts to find dkjson, cjson, or json libraries
   - If no library is available, will error with clear message
   - TODO: Determine if Barony provides built-in JSON support
   - TODO: Bundle a JSON library if needed

2. File I/O:
   - Uses standard Lua io.open() for file reading
   - TODO: Confirm this works in Barony's Lua environment
   - TODO: Investigate if Barony provides mod-specific file APIs

3. Directory Listing:
   - Requires LuaFileSystem (lfs) module for directory listing
   - If unavailable, returns empty collections with WARN logs
   - TODO: Implement static file manifest as fallback
   - TODO: Investigate if Barony provides directory listing capabilities
   
4. Path Resolution:
   - Uses relative path "mod/dccb/data"
   - TODO: Confirm correct path resolution in Barony runtime context
   - May need to use absolute paths or Barony-specific path APIs

5. Error Recovery:
   - Currently fails fast on missing required files/parsing errors
   - This is intentional per Phase 1 requirements
   - Future: Consider graceful degradation for optional content
--]]

return Bootstrap
