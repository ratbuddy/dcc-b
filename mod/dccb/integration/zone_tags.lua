-- /mod/dccb/integration/zone_tags.lua
-- Zone Tags Integration Vocabulary Module - Phase-1 Task 9D
-- Single source of truth for symbolic zone/environment tags used between DCCB and ToME
--
-- This module defines standard DCCB tag names, helper functions to normalize,
-- merge, and inspect tags, and provides the future mapping surface to ToME zone flags.
--
-- Phase-1: No ToME APIs, no real mapping logic - contract definition only.

local log = require("mod.dccb.core.log")

local ZoneTags = {}

-------------------------------------------------------------------------------
-- Local helper: normalize a single tag string
-- @param tag string - tag to normalize
-- @return string - normalized tag (lowercase, trimmed), or nil if empty
-------------------------------------------------------------------------------
local function normalize_tag_string(tag)
  if type(tag) ~= "string" then
    return nil
  end
  local trimmed = tag:match("^%s*(.-)%s*$")  -- trim whitespace
  local normalized = trimmed:lower()
  if normalized == "" then
    return nil
  end
  return normalized
end

-------------------------------------------------------------------------------
-- Local helper: check if table is an array (sequential integer keys from 1)
-- @param t table - table to check
-- @return boolean - true if array, false if map
-------------------------------------------------------------------------------
local function is_array(t)
  if type(t) ~= "table" then
    return false
  end
  
  -- Empty tables are treated as arrays
  local has_any_key = false
  for _ in pairs(t) do
    has_any_key = true
    break
  end
  if not has_any_key then
    return true
  end
  
  -- Count using ipairs (only sequential integer keys from 1)
  local array_count = 0
  for _ in ipairs(t) do
    array_count = array_count + 1
  end
  
  -- Count all keys
  local total_count = 0
  for _ in pairs(t) do
    total_count = total_count + 1
  end
  
  -- If counts match, it's an array (all keys are sequential integers)
  return array_count == total_count
end

-------------------------------------------------------------------------------
-- ZoneTags.normalize(tags) -> tag_set
-- Normalize tags from array or map form into canonical {[string]=true} table
--
-- Phase-1 Behavior:
-- - Accepts array form: {"dark", "wet"} -> {dark=true, wet=true}
-- - Accepts map form: {dark=true, wet=false} -> {dark=true} (false values excluded)
-- - Accepts string form: "dark" -> {dark=true}
-- - Lowercase all tag names
-- - Trim whitespace from tag names
-- - Returns new canonical table, never mutates input
--
-- @param tags any - tags in array, map, string, or nil form
-- @return table - canonical {[string]=true} tag set
-------------------------------------------------------------------------------
function ZoneTags.normalize(tags)
  log.debug("ZoneTags.normalize: starting")
  
  local result = {}
  
  -- Handle nil input
  if tags == nil then
    log.debug("ZoneTags.normalize: nil input, returning empty set")
    return result
  end
  
  -- Handle string input (single tag)
  if type(tags) == "string" then
    local normalized = normalize_tag_string(tags)
    if normalized then
      result[normalized] = true
      log.debug("ZoneTags.normalize: normalized string tag:", normalized)
    end
    return result
  end
  
  -- Handle table input
  if type(tags) == "table" then
    if is_array(tags) then
      -- Array form: {"dark", "wet"}
      for _, tag in ipairs(tags) do
        local normalized = normalize_tag_string(tag)
        if normalized then
          result[normalized] = true
        end
      end
    else
      -- Map form: {dark=true, wet=false}
      for tag, enabled in pairs(tags) do
        if enabled then
          local normalized = normalize_tag_string(tag)
          if normalized then
            result[normalized] = true
          end
        end
      end
    end
    
    -- Count tags for logging
    local count = 0
    for _ in pairs(result) do
      count = count + 1
    end
    log.debug("ZoneTags.normalize: normalized", count, "tags")
    
    return result
  end
  
  -- Handle unexpected input type
  log.debug("ZoneTags.normalize: unexpected type", type(tags), "returning empty set")
  return result
end

-------------------------------------------------------------------------------
-- ZoneTags.merge(a, b) -> tag_set
-- Merge two tag sets into a new normalized union
--
-- Phase-1 Behavior:
-- - Accepts two tag sets in any form (will be normalized)
-- - Returns new tag set containing all tags from both inputs
-- - Never mutates inputs
-- - Result is always normalized
--
-- @param a any - first tag set (any normalizable form)
-- @param b any - second tag set (any normalizable form)
-- @return table - canonical {[string]=true} union of both sets
-------------------------------------------------------------------------------
function ZoneTags.merge(a, b)
  log.debug("ZoneTags.merge: starting")
  
  -- Normalize both inputs
  local norm_a = ZoneTags.normalize(a)
  local norm_b = ZoneTags.normalize(b)
  
  -- Create new result with union of both
  local result = {}
  
  for tag, _ in pairs(norm_a) do
    result[tag] = true
  end
  
  for tag, _ in pairs(norm_b) do
    result[tag] = true
  end
  
  -- Count tags for logging
  local count = 0
  for _ in pairs(result) do
    count = count + 1
  end
  log.debug("ZoneTags.merge: merged to", count, "tags")
  
  return result
end

-------------------------------------------------------------------------------
-- ZoneTags.has(tag_set, tag) -> boolean
-- Check if a tag set contains a specific tag (case-insensitive)
--
-- Phase-1 Behavior:
-- - Normalizes tag_set if needed
-- - Normalizes search tag (lowercase, trim)
-- - Returns true if tag is present, false otherwise
--
-- @param tag_set any - tag set to search (any normalizable form)
-- @param tag string - tag to search for
-- @return boolean - true if tag is present, false otherwise
-------------------------------------------------------------------------------
function ZoneTags.has(tag_set, tag)
  log.debug("ZoneTags.has: checking for tag:", tag)
  
  -- Normalize the tag set
  local normalized_set = ZoneTags.normalize(tag_set)
  
  -- Normalize the search tag using helper
  local normalized_tag = normalize_tag_string(tag)
  if not normalized_tag then
    log.debug("ZoneTags.has: invalid tag, returning false")
    return false
  end
  
  local found = normalized_set[normalized_tag] == true
  log.debug("ZoneTags.has: tag", normalized_tag, "found:", found)
  
  return found
end

-------------------------------------------------------------------------------
-- ZoneTags.describe(tag_set) -> string
-- Return a stable, sorted, comma-separated string representation of tags
--
-- Phase-1 Behavior:
-- - Normalizes tag_set
-- - Sorts tags alphabetically for deterministic output
-- - Returns comma-separated string (e.g., "dark, toxic, wet")
-- - Returns empty string if tag_set is empty
--
-- @param tag_set any - tag set to describe (any normalizable form)
-- @return string - sorted comma-separated tag names, or "" if empty
-------------------------------------------------------------------------------
function ZoneTags.describe(tag_set)
  log.debug("ZoneTags.describe: generating description")
  
  -- Normalize the tag set
  local normalized_set = ZoneTags.normalize(tag_set)
  
  -- Collect tags into array for sorting
  local tags_array = {}
  for tag, _ in pairs(normalized_set) do
    table.insert(tags_array, tag)
  end
  
  -- Sort alphabetically for stable output
  table.sort(tags_array)
  
  -- Join with ", "
  local result = table.concat(tags_array, ", ")
  
  log.debug("ZoneTags.describe: generated description:", result)
  
  return result
end

-------------------------------------------------------------------------------
-- ZoneTags.to_engine_flags(tag_set) -> engine_descriptor
-- Convert DCCB tag set to ToME engine flags (Phase-1 stub)
--
-- Phase-1 Behavior:
-- - Normalizes tag_set
-- - Returns stub table: {tags=normalized, deferred=true}
-- - Logs DEBUG that ToME mapping is deferred
-- - No actual ToME API calls or flag translations
--
-- @param tag_set any - tag set to convert (any normalizable form)
-- @return table - engine descriptor {tags=table, deferred=boolean}
-------------------------------------------------------------------------------
function ZoneTags.to_engine_flags(tag_set)
  log.debug("ZoneTags.to_engine_flags: starting (Phase-1 stub)")
  
  -- Normalize the tag set
  local normalized_set = ZoneTags.normalize(tag_set)
  
  -- Create Phase-1 stub descriptor
  local descriptor = {
    tags = normalized_set,
    deferred = true
  }
  
  -- Log that ToME mapping is deferred
  log.debug("ZoneTags.to_engine_flags: ToME mapping deferred to Phase-2")
  
  -- Count tags for logging
  local count = 0
  for _ in pairs(normalized_set) do
    count = count + 1
  end
  log.debug("ZoneTags.to_engine_flags: returning stub descriptor with", count, "tags")
  
  return descriptor
end

return ZoneTags

--[[
===============================================================================
WHY THIS FILE EXISTS
===============================================================================

Purpose:
--------
Zone Tags are the symbolic vocabulary used to describe environmental and
spatial properties of dungeon zones. They provide a bridge between:

1. High-level DCCB concepts (region profiles, floor rules, mutations)
2. Low-level ToME zone generation flags and environmental effects

This module serves as:
- Single source of truth for tag names and semantics
- Normalization layer for tag data from different sources
- Future translation surface to ToME zone flags
- Deterministic inspection and debugging interface

Example tags:
- Environmental: "dark", "wet", "toxic", "cold", "hot", "radioactive"
- Structural: "open", "cramped", "vertical", "maze-like", "linear"
- Thematic: "industrial", "organic", "ancient", "high-tech", "ruined"
- Hazards: "flooded", "collapsing", "burning", "trapped"
- Meta: "arena", "safe-zone", "boss-chamber", "treasure-room"

Why tags instead of direct flags:
----------------------------------
1. Engine-agnostic: Tags are DCCB concepts, not ToME implementation details
2. Composable: Multiple systems can contribute tags (region, floor, mutations)
3. Inspectable: Tags can be logged, saved, and debugged as strings
4. Extensible: New tags don't require code changes in systems
5. Portable: If we switch engines, tags remain; only mapping changes

===============================================================================
HOW REGION/FLOOR DESCRIPTORS FEED INTO ZONE TAGS
===============================================================================

Integration Flow:
-----------------
1. Region Director selects region profile
   - Region profile defines environmental tags (e.g., "dark", "wet")
   - These become base zone tags for all floors in that region

2. Floor Director determines floor rules
   - Floor rules can add tags (e.g., "toxic" mutation on floor 5)
   - Floor rules can override tags (e.g., "bright" negates "dark")

3. Zone Adapter receives merged tags
   - ZoneAdapter.apply_region_constraints() uses region-derived tags
   - ZoneAdapter.apply_floor_mutations() applies floor-specific tag changes
   - ZoneAdapter calls ZoneTags.merge() to combine tag sets

4. Zone Tags convert to ToME flags (Phase-2)
   - ZoneTags.to_engine_flags() will translate tags → ToME zone properties
   - Example: "dark" → reduce zone light level
   - Example: "toxic" → add poison effect to zone
   - Example: "vertical" → adjust stair density parameters

Example Call Chain (Phase-2):
------------------------------
  Hooks.on_pre_generate(gen_params)
    → state.region.profile.tags = {"dark", "industrial"}
    → state.floor.tags = {"toxic"}
    
    → ZoneAdapter.apply_region_constraints(gen_params, region, state)
      → region_tags = ZoneTags.normalize(region.tags)
      
    → ZoneAdapter.apply_floor_mutations(gen_params, floor, state)
      → floor_tags = ZoneTags.normalize(floor.tags)
      → merged_tags = ZoneTags.merge(region_tags, floor_tags)
      
      → engine_flags = ZoneTags.to_engine_flags(merged_tags)
      → apply engine_flags to gen_params (ToME-specific mapping)
      
    ← returns modified gen_params with ToME zone flags set

Data Flow:
----------
Region Profile JSON:
  {
    "id": "industrial_depths",
    "tags": ["dark", "industrial", "cramped"]
  }

Floor Rule JSON:
  {
    "id": "toxic_floor",
    "tags_add": ["toxic"],
    "tags_remove": ["dark"]
  }

Runtime:
  region_tags = {"dark", "industrial", "cramped"}
  floor_tags = {"toxic"}
  
  merged = ZoneTags.merge(region_tags, floor_tags)
  -> {"cramped", "industrial", "toxic"}  (dark removed by floor rule)
  
  engine_flags = ZoneTags.to_engine_flags(merged)
  -> Phase-1: {tags={cramped=true, industrial=true, toxic=true}, deferred=true}
  -> Phase-2: {light_level=-2, poison_intensity=3, corridor_width=1, ...}

===============================================================================
WHAT PHASE-2 ToME WORK BELONGS HERE
===============================================================================

Phase-2 Implementation Tasks:
------------------------------

1. Tag → ToME Zone Flag Mapping:
   ----------------------------------
   Implement ZoneTags.to_engine_flags() to translate DCCB tags into ToME
   zone generation parameters and environmental effects.
   
   Research Required:
   - ToME zone property system (zone.lua structure)
   - ToME environmental effect APIs (lighting, poison, temperature)
   - ToME generator parameter names and valid value ranges
   
   Example Mappings:
   - "dark" → zone.light_level = -2 or similar ToME lighting parameter
   - "wet" → zone.water_coverage = 0.3, slippery terrain multiplier
   - "toxic" → zone.poison_intensity = 3, periodic damage effect
   - "cold" → zone.temperature = -20, frost effect on actors
   - "vertical" → generator corridor_width -= 1, stair_density *= 1.5
   - "cramped" → generator room_size_max *= 0.7, corridor_count *= 1.5
   - "open" → generator room_size_min *= 1.5, corridor_count *= 0.5
   - "arena" → generator special_room = true, spawn_boss_if_appropriate
   
   Implementation Steps:
   a. Create tag→flag mapping table (tag_to_tome_flags)
   b. Iterate over normalized tag_set
   c. For each tag, look up corresponding ToME parameters
   d. Build engine_flags table with ToME-specific structure
   e. Handle conflicting tags (e.g., "dark" + "bright" → precedence rules)
   f. Return engine_flags suitable for ToME zone generation

2. Standard DCCB Tag Vocabulary:
   ----------------------------------
   Define canonical tag names and their semantic meanings in documentation
   or as constants in this module.
   
   Categories to define:
   - Environmental conditions (dark, wet, hot, cold, toxic, radioactive)
   - Structural properties (open, cramped, vertical, maze-like, linear)
   - Thematic flavors (industrial, organic, ancient, high-tech, ruined)
   - Hazard types (flooded, collapsing, burning, trapped, unstable)
   - Special zones (arena, safe-zone, boss-chamber, treasure-room)
   
   Consider adding:
   - ZoneTags.STANDARD_TAGS table with descriptions
   - ZoneTags.is_valid(tag) validation helper
   - ZoneTags.get_category(tag) categorization helper

3. Conflict Resolution:
   ----------------------------------
   Implement logic to handle contradictory tags (e.g., "dark" + "bright").
   
   Options:
   - Priority system (floor tags override region tags)
   - Explicit negation tags (e.g., "!dark" removes dark)
   - Conflict detection with warnings
   - Blend rules (e.g., "hot" + "cold" → neutral temperature)
   
   Add to ZoneTags.merge() or create ZoneTags.resolve_conflicts().

4. Intensity Modifiers:
   ----------------------------------
   Support tag intensity levels (e.g., "dark:2", "toxic:high").
   
   Extend normalize() to parse intensity syntax:
   - "dark:2" → {tag="dark", intensity=2}
   - "toxic:high" → {tag="toxic", intensity="high"}
   
   Extend to_engine_flags() to scale ToME parameters by intensity:
   - "dark:1" → light_level = -1
   - "dark:3" → light_level = -3
   - "toxic:low" → poison_intensity = 1
   - "toxic:high" → poison_intensity = 5

5. Tag Inheritance and Overrides:
   ----------------------------------
   Implement tag modification operators for floor rules:
   - tags_add: list of tags to add to region baseline
   - tags_remove: list of tags to remove from region baseline
   - tags_set: complete override of region tags
   
   Extend ZoneTags.merge() to respect removal operations:
   - Current: simple union of both sets
   - Phase-2: handle {add: [...], remove: [...]} syntax

6. Logging and Debugging:
   ----------------------------------
   Enhance logging to show tag→flag translation decisions:
   - Log each tag and resulting ToME parameter changes
   - Log conflicts and resolution choices
   - Log unrecognized tags (typos, unsupported tags)
   - Add ZoneTags.explain(tag_set) for verbose debugging output

7. Performance Optimization:
   ----------------------------------
   If tag operations become a bottleneck:
   - Cache normalized tag sets
   - Memoize to_engine_flags() results
   - Pre-compute common tag combinations
   
   Only optimize if profiling shows this is necessary.

8. ToME API Research and Documentation:
   ----------------------------------
   Document all ToME zone APIs discovered during implementation:
   - Zone property names and types
   - Generator parameter names and valid ranges
   - Environmental effect APIs
   - Lighting and visibility systems
   - Terrain and tile modification APIs
   
   Add findings to /docs/ToME-Integration-Notes.md

===============================================================================
PHASE-1 GUARANTEES
===============================================================================

What this module guarantees in Phase-1:
----------------------------------------
1. Contract Stability:
   - All five public functions defined and callable
   - Function signatures match problem statement specifications
   - Return types are consistent and documented
   
2. Deterministic Behavior:
   - normalize() always produces same output for same input
   - merge() never mutates inputs, always returns new table
   - has() performs case-insensitive search
   - describe() produces stable, sorted output
   - to_engine_flags() returns predictable stub structure
   
3. Input Flexibility:
   - normalize() handles array, map, string, and nil inputs
   - All functions validate inputs and handle edge cases
   - Never crashes on malformed input
   
4. Logging Visibility:
   - DEBUG logs show tag operations
   - No noisy logs (only DEBUG level)
   - Clear indication that ToME mapping is deferred
   
5. No Side Effects:
   - Pure functions (except logging)
   - No global state modification
   - No ToME API calls
   - No file I/O
   
6. Phase-2 Ready:
   - Clear TODO blocks for future ToME work
   - Documented integration points
   - Stable interface that won't change
   - Easy to extend without breaking existing code

===============================================================================
RELATIONSHIP TO OTHER DCCB MODULES
===============================================================================

Zone Tags in the DCCB Architecture:
------------------------------------

Core Systems (engine-agnostic):
- /systems/region_director.lua
  - Defines region profiles with tag lists
  - Provides region baseline tags for zones
  
- /systems/floor_director.lua
  - Defines floor rules with tag modifications
  - Provides floor-specific tag additions/overrides

Integration Layer (ToME-specific):
- /integration/zone_adapter.lua
  - Calls ZoneTags.normalize() on region and floor tags
  - Calls ZoneTags.merge() to combine tag sets
  - Calls ZoneTags.to_engine_flags() to get ToME parameters
  - Applies engine flags to gen_params
  
- /integration/zone_tags.lua (this module)
  - Provides tag vocabulary and normalization
  - Future: translates tags → ToME zone flags

Data Layer:
- /data/regions/*.json
  - Includes "tags" arrays in region profiles
  - Example: {"tags": ["dark", "industrial"]}
  
- /data/floor_rules/*.json
  - Includes "tags_add" and "tags_remove" in floor rules
  - Example: {"tags_add": ["toxic"], "tags_remove": ["dark"]}

Key Architectural Points:
--------------------------
1. ZoneTags is engine-specific (ToME) - lives in /integration/
2. Tag vocabulary is defined here, not in core systems
3. Core systems use generic tag strings, not ToME specifics
4. This module is the only place that knows ToME zone flag structure
5. Clean separation: systems compose tags, ZoneTags translates them

Benefits:
---------
- Core systems remain engine-agnostic
- ToME-specific knowledge isolated to integration layer
- Easy to add new tags without changing systems
- Clear contract between data, systems, and engine
- Testing systems without ToME engine is possible

===============================================================================
]]
