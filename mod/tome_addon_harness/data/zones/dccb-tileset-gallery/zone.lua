-- /data/zones/dccb-tileset-gallery/zone.lua
-- DCCB Tileset Gallery Zone - Dense Visual Catalog and Validation Tool
-- Virtual path: /data-dccb/zones/dccb-tileset-gallery/zone.lua
-- Resources (grids/npcs/objects/traps) load from /data/zones/dccb-tileset-gallery/ (overload)

-- This is a debug/reference zone to validate terrain tilesets
-- It displays a dense "palette map" of terrain samples with runtime probing
-- Missing IDs are skipped safely, dangerous terrains (with change_level/on_stand) are filtered
-- Always uses the canonical manifest (384 terrains) and generates probe reports

-- Dense layout configuration
local CELL_W = 3              -- Cell width (3x3 per terrain)
local CELL_H = 3              -- Cell height (3x3 per terrain)
local CELL_GAP = 1            -- Gap between cells
local START_X = 2             -- Palette start X
local START_Y = 2             -- Palette start Y
local SPAWN_PAD_SIZE = 8      -- Walkable spawn pad size

return {
  name = "DCCB Tileset Gallery",
  short_name = "dccb-tileset-gallery",
  level_range = {1, 2},
  max_level = 2,  -- Calculated: ceil(384 terrains / 196 per level) = 2 levels
  width = 64,  -- Safe, proven size (bounds-aware placement)
  height = 64, -- Small, predictable (prevents out-of-bounds)
  persistent = "zone",
  all_remembered = true,
  all_lited = true,
  no_level_connectivity = false,  -- Enable stairs between levels
  
  -- Explicit zone entity loads (ensures grids/npcs/objects/traps are registered)
  load = {
    "/data/zones/dccb-tileset-gallery/grids.lua",
    "/data/zones/dccb-tileset-gallery/npcs.lua",
    "/data/zones/dccb-tileset-gallery/objects.lua",
    "/data/zones/dccb-tileset-gallery/traps.lua",
  },
  
  -- Generator: Empty (blank canvas for manual palette placement)
  -- MUST be 64×64 for safe, bounds-aware placement
  generator = {
    map = {
      class = "engine.generator.map.Empty",
      width = 64,
      height = 64,
    },
    actor = {
      nb_npc = {0, 0},
    },
    object = {
      nb_object = {0, 0},
    },
    trap = {
      nb_trap = {0, 0},
    },
  },
  
  -- Debug logging on zone entry
  on_enter = function(a,b,...)
    local zone, lev
    if type(a)=="table" then zone=a; lev=b else zone=nil; lev=a end
    local zname = (zone and zone.short_name) or "unknown"
    print(string.format("[DCCB-Gallery] Entered zone '%s' level %d", zname, tonumber(lev) or 0))
  end,
  
  -- Post-process: Place dense terrain palette with safe filtering
  post_process = function(a, b, c, ...)
    local Map = require "engine.Map"
    
    -- Load canonical terrain manifest (384 terrains)
    local manifest_path = "/data-dccb/dccb/tileset/gallery_manifest.lua"
    print("[DCCB-Gallery] Loading canonical manifest (384 terrains): " .. manifest_path)
    local manifest_ok, manifest = pcall(loadfile, manifest_path)
    if not manifest_ok or not manifest then
      print("[DCCB-Gallery] ERROR: Cannot load gallery manifest")
      print("[DCCB-Gallery] Error: " .. tostring(manifest))
      return
    end
    manifest = manifest()
    
    -- Debug: Log manifest info
    if manifest and manifest.TERRAIN_CANDIDATES then
      local count = #manifest.TERRAIN_CANDIDATES
      print(string.format("[DCCB-Gallery] Manifest loaded: %d terrain candidates", count))
      if count > 0 then
        local first_few = {}
        for i = 1, math.min(5, count) do
          table.insert(first_few, manifest.TERRAIN_CANDIDATES[i].id)
        end
        print("[DCCB-Gallery] First 5 IDs: " .. table.concat(first_few, ", "))
      end
    else
      print("[DCCB-Gallery] ERROR: Manifest loaded but has no TERRAIN_CANDIDATES")
      return
    end
    
    -- Capability-based detection: find level and zone by their methods
    local level, zone
    
    -- Find level: whichever arg is a table with .map
    for _, arg in ipairs({a, b, c}) do
      if type(arg) == "table" and arg.map then
        level = arg
        break
      end
    end
    
    -- Find zone: whichever arg is a table with .makeEntityByName or .makeEntity
    for _, arg in ipairs({a, b, c}) do
      if type(arg) == "table" and (arg.makeEntityByName or arg.makeEntity) then
        zone = arg
        break
      end
    end
    
    -- Validate we have both level and zone
    if not level or not level.map then
      print("[DCCB-Gallery] ERROR: Cannot detect level object (no .map found)")
      return
    end
    
    if not zone or not (zone.makeEntityByName or zone.makeEntity) then
      print("[DCCB-Gallery] ERROR: Cannot detect zone object (no .makeEntityByName/.makeEntity found)")
      return
    end
    
    -- Helper function to compute visual signature
    local function compute_visual_signature(terrain)
      if not terrain then return nil end
      
      local image = terrain.image or ""
      local add_mos_str = ""
      
      if terrain.add_mos then
        local mos_list = {}
        for _, mos in ipairs(terrain.add_mos) do
          if type(mos) == "table" and mos.image then
            table.insert(mos_list, mos.image)
          end
        end
        table.sort(mos_list)  -- Consistent ordering
        add_mos_str = table.concat(mos_list, ",")
      end
      
      local display = tostring(terrain.display or "")
      return image .. "|" .. add_mos_str .. "|" .. display
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Generating Dense Tileset Palette")
    print("[DCCB-Gallery] ========================================")
    
    -- Read actual map bounds at runtime (NEVER assume size)
    local map = level.map
    local W, H = map.w, map.h
    
    -- Detect current level (multi-level support)
    local current_level = level.level or 1
    local MAX_LEVEL = 2  -- Calculated: ceil(384 terrains / 196 per level)
    local TERRAINS_PER_LEVEL = 196  -- Approximate capacity per 64×64 level
    
    print(string.format("[DCCB-Gallery] Level %d of %d", current_level, MAX_LEVEL))
    print(string.format("[DCCB-Gallery] Map bounds: %d x %d", W, H))
    
    -- Calculate terrain range for this level
    local total_terrains = #manifest.TERRAIN_CANDIDATES
    local start_idx = (current_level - 1) * TERRAINS_PER_LEVEL + 1
    local end_idx = math.min(current_level * TERRAINS_PER_LEVEL, total_terrains)
    
    print(string.format("[DCCB-Gallery] Terrain range for this level: %d-%d (of %d total)", 
      start_idx, end_idx, total_terrains))
    
    -- Step 1: Fill background to prevent black map
    print("[DCCB-Gallery] Step 1: Filling background...")
    local background_grid = zone:makeEntityByName(level, "terrain", "GRASS") or 
                           zone:makeEntityByName(level, "terrain", "FLOOR")
    
    if background_grid then
      if background_grid.resolve then background_grid:resolve() end
      for x = 0, W - 1 do
        for y = 0, H - 1 do
          level.map(x, y, Map.TERRAIN, background_grid)
        end
      end
      print("[DCCB-Gallery] Background filled with: " .. (background_grid.name or "unknown"))
    else
      print("[DCCB-Gallery] WARNING: No background grid available (GRASS/FLOOR not found)")
    end
    
    -- Step 2: Calculate dynamic layout based on actual bounds
    local stride_x = CELL_W + CELL_GAP  -- 4
    local stride_y = CELL_H + CELL_GAP  -- 4
    local margin = 2
    
    local max_cols = math.max(1, math.floor((W - START_X - margin) / stride_x))
    local max_rows = math.max(1, math.floor((H - START_Y - margin) / stride_y))
    local capacity = max_cols * max_rows
    
    print(string.format("[DCCB-Gallery] Step 2: Layout: %d cols × %d rows (max capacity: %d)", 
      max_cols, max_rows, capacity))
    print(string.format("[DCCB-Gallery]   Cell: %dx%d, Gap: %d, Stride: %dx%d", 
      CELL_W, CELL_H, CELL_GAP, stride_x, stride_y))
    
    -- Step 3: Place spawn pad AFTER knowing bounds
    print("[DCCB-Gallery] Step 3: Creating spawn pad...")
    -- Clamp spawn pad to safe location within bounds
    local pad_x = math.max(2, math.min(W - SPAWN_PAD_SIZE - 2, W - SPAWN_PAD_SIZE - margin))
    local pad_y = math.max(2, math.min(H - SPAWN_PAD_SIZE - 2, H - SPAWN_PAD_SIZE - margin))
    
    local spawn_floor = zone:makeEntityByName(level, "terrain", "GRASS") or 
                       zone:makeEntityByName(level, "terrain", "FLOOR")
    
    if spawn_floor then
      if spawn_floor.resolve then spawn_floor:resolve() end
      -- Clamp spawn pad size to never exceed bounds
      local pad_w = math.min(SPAWN_PAD_SIZE, W - pad_x)
      local pad_h = math.min(SPAWN_PAD_SIZE, H - pad_y)
      for x = pad_x, pad_x + pad_w - 1 do
        for y = pad_y, pad_y + pad_h - 1 do
          if x < W and y < H then  -- Extra safety check
            level.map(x, y, Map.TERRAIN, spawn_floor)
          end
        end
      end
      print(string.format("[DCCB-Gallery] Spawn pad: %dx%d at (%d,%d)", 
        pad_w, pad_h, pad_x, pad_y))
    end
    
    -- PHASE 1: Build visual signature map
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Phase 1: Building visual signature map...")
    print("[DCCB-Gallery] ========================================")
    
    local signature_map = {}  -- signature -> {first_id, ids[], signature}
    local id_to_signature = {}  -- id -> signature (for quick lookup)
    local phase1_resolved = 0
    local phase1_missing = 0
    local phase1_dangerous = 0
    
    -- Blacklist of known-dangerous terrains
    local KNOWN_DANGEROUS = {
      DCCB_ENTRANCE = true,  -- Has on_stand message
    }
    
    -- Track entity types
    local by_entity_kind = {
      terrain = {},
      object = {},
      trap = {},
      missing = {},
      dangerous = {},
    }
    
    -- Process all terrains in range to build signature map
    for idx = start_idx, end_idx do
      local terrain_info = manifest.TERRAIN_CANDIDATES[idx]
      if not terrain_info then break end
      
      local id = terrain_info.id
      
      -- Skip blacklisted dangerous terrains
      if KNOWN_DANGEROUS[id] then
        phase1_dangerous = phase1_dangerous + 1
        id_to_signature[id] = "DANGEROUS"
        table.insert(by_entity_kind.dangerous, id)
      else
        -- Try multiple entity types: terrain, object, trap
        local entity = nil
        local entity_kind = nil
        
        -- Try terrain first
        entity = zone:makeEntityByName(level, "terrain", id)
        if entity then
          entity_kind = "terrain"
        end
        
        -- Try object if terrain failed
        if not entity then
          entity = zone:makeEntityByName(level, "object", id)
          if entity then
            entity_kind = "object"
          end
        end
        
        -- Try trap if both terrain and object failed
        if not entity then
          entity = zone:makeEntityByName(level, "trap", id)
          if entity then
            entity_kind = "trap"
          end
        end
        
        if not entity then
          -- Entity not found in any category
          phase1_missing = phase1_missing + 1
          id_to_signature[id] = "MISSING"
          table.insert(by_entity_kind.missing, id)
        else
          -- Entity resolved - track its kind
          table.insert(by_entity_kind[entity_kind], id)
          
          -- Only process terrains for visual display (objects/traps just tracked)
          if entity_kind == "terrain" then
            -- Resolve terrain to get actual properties
            if entity.resolve then entity:resolve() end
            
            -- Compute visual signature
            local signature = compute_visual_signature(entity)
            
            if signature then
              phase1_resolved = phase1_resolved + 1
              id_to_signature[id] = signature
              
              -- Group by signature
              if not signature_map[signature] then
                signature_map[signature] = {
                  first_id = id,
                  ids = {id},
                  signature = signature
                }
              else
                table.insert(signature_map[signature].ids, id)
              end
            end
          else
            -- Non-terrain entity: mark as resolved but not displayable
            phase1_resolved = phase1_resolved + 1
            id_to_signature[id] = "NON_TERRAIN"
          end
        end
      end
    end
    
    -- Count unique signatures
    local unique_count = 0
    for _ in pairs(signature_map) do
      unique_count = unique_count + 1
    end
    
    -- Report visual signature groups
    print("[DCCB-Gallery] ")
    print("[DCCB-Gallery] Visual Signature Groups:")
    print("[DCCB-Gallery] ----------------------------------------")
    
    local group_count = 0
    for sig, group in pairs(signature_map) do
      if #group.ids > 1 then
        group_count = group_count + 1
        print(string.format("[DCCB-Gallery] Signature: %s", sig))
        print(string.format("[DCCB-Gallery]   Representative: %s", group.first_id))
        print(string.format("[DCCB-Gallery]   Visual aliases: %s", 
          table.concat(group.ids, ", ")))
        print("[DCCB-Gallery] ")
      end
    end
    
    if group_count == 0 then
      print("[DCCB-Gallery] (No visual duplicates found - all terrains have unique signatures)")
      print("[DCCB-Gallery] ")
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Phase 1 Complete")
    print("[DCCB-Gallery] ========================================")
    print(string.format("[DCCB-Gallery] Total IDs processed: %d", end_idx - start_idx + 1))
    print(string.format("[DCCB-Gallery] Resolved successfully: %d", phase1_resolved))
    print(string.format("[DCCB-Gallery] Skipped (missing): %d", phase1_missing))
    print(string.format("[DCCB-Gallery] Skipped (dangerous): %d", phase1_dangerous))
    print(string.format("[DCCB-Gallery] Unique visual signatures: %d", unique_count))
    print(string.format("[DCCB-Gallery] Visual duplicates found: %d", phase1_resolved - unique_count))
    print("[DCCB-Gallery] ")
    
    -- PROBE REPORTS: Generate structured output to te4_log.txt
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Generating Probe Reports (te4_log.txt)")
    print("[DCCB-Gallery] ========================================")
    
    -- Build classification lists
    local resolved_list = {}
    local missing_list = {}
    local dangerous_list = {}
    local duplicate_list = {}
    
    for idx = start_idx, end_idx do
      local terrain_info = manifest.TERRAIN_CANDIDATES[idx]
      if terrain_info then
        local id = terrain_info.id
        local sig = id_to_signature[id]
        
        if sig == "MISSING" then
          table.insert(missing_list, id)
        elseif sig == "DANGEROUS" then
          table.insert(dangerous_list, id)
        elseif sig then
          -- Check if this is the first ID for this signature
          if signature_map[sig] and signature_map[sig].first_id == id then
            table.insert(resolved_list, id)
          else
            table.insert(duplicate_list, id)
          end
        end
      end
    end
    
    -- Sort lists
    table.sort(resolved_list)
    table.sort(missing_list)
    table.sort(dangerous_list)
    table.sort(duplicate_list)
    
    -- Sort entity kind lists
    for kind, list in pairs(by_entity_kind) do
      table.sort(list)
    end
    
    -- Output ENTITY KIND SUMMARY
    print("[DCCB-PROBE-REPORT] ========================================")
    print("[DCCB-PROBE-REPORT] ENTITY KIND CLASSIFICATION:")
    print("[DCCB-PROBE-REPORT] ========================================")
    print(string.format("[DCCB-PROBE-REPORT]   Terrain entities: %d", #by_entity_kind.terrain))
    print(string.format("[DCCB-PROBE-REPORT]   Object entities: %d", #by_entity_kind.object))
    print(string.format("[DCCB-PROBE-REPORT]   Trap entities: %d", #by_entity_kind.trap))
    print(string.format("[DCCB-PROBE-REPORT]   Dangerous (blacklisted): %d", #by_entity_kind.dangerous))
    print(string.format("[DCCB-PROBE-REPORT]   Missing (not found): %d", #by_entity_kind.missing))
    print(string.format("[DCCB-PROBE-REPORT]   Total processed: %d", 
      #by_entity_kind.terrain + #by_entity_kind.object + #by_entity_kind.trap + 
      #by_entity_kind.dangerous + #by_entity_kind.missing))
    print("[DCCB-PROBE-REPORT] ")
    
    -- Output entity lists by kind (for reference)
    if #by_entity_kind.object > 0 then
      print("[DCCB-PROBE-REPORT] Object IDs:")
      for _, id in ipairs(by_entity_kind.object) do
        print("[DCCB-PROBE-REPORT]   " .. id)
      end
      print("[DCCB-PROBE-REPORT] ")
    end
    
    if #by_entity_kind.trap > 0 then
      print("[DCCB-PROBE-REPORT] Trap IDs:")
      for _, id in ipairs(by_entity_kind.trap) do
        print("[DCCB-PROBE-REPORT]   " .. id)
      end
      print("[DCCB-PROBE-REPORT] ")
    end
    
    -- Output RESOLVED IDs
    print("[DCCB-PROBE-REPORT] ========================================")
    print(string.format("[DCCB-PROBE-REPORT] RESOLVED IDs (%d):", #resolved_list))
    print("[DCCB-PROBE-REPORT] ========================================")
    for _, id in ipairs(resolved_list) do
      print("[DCCB-PROBE-REPORT]   " .. id)
    end
    print("[DCCB-PROBE-REPORT] ")
    
    -- Output MISSING IDs
    print("[DCCB-PROBE-REPORT] ========================================")
    print(string.format("[DCCB-PROBE-REPORT] MISSING IDs (%d):", #missing_list))
    print("[DCCB-PROBE-REPORT] ========================================")
    for _, id in ipairs(missing_list) do
      print("[DCCB-PROBE-REPORT]   " .. id)
    end
    print("[DCCB-PROBE-REPORT] ")
    
    -- Output DANGEROUS IDs
    print("[DCCB-PROBE-REPORT] ========================================")
    print(string.format("[DCCB-PROBE-REPORT] DANGEROUS IDs (%d):", #dangerous_list))
    print("[DCCB-PROBE-REPORT] ========================================")
    for _, id in ipairs(dangerous_list) do
      print("[DCCB-PROBE-REPORT]   " .. id)
    end
    print("[DCCB-PROBE-REPORT] ")
    
    -- Output DUPLICATE VISUAL IDs
    print("[DCCB-PROBE-REPORT] ========================================")
    print(string.format("[DCCB-PROBE-REPORT] DUPLICATE VISUAL IDs (%d):", #duplicate_list))
    print("[DCCB-PROBE-REPORT] ========================================")
    for _, id in ipairs(duplicate_list) do
      local sig = id_to_signature[id]
      if sig and signature_map[sig] then
        print(string.format("[DCCB-PROBE-REPORT]   %s (same as %s)", 
          id, signature_map[sig].first_id))
      end
    end
    print("[DCCB-PROBE-REPORT] ")
    
    -- Output SIGNATURE GROUPS
    print("[DCCB-PROBE-REPORT] ========================================")
    print("[DCCB-PROBE-REPORT] VISUAL SIGNATURE GROUPS:")
    print("[DCCB-PROBE-REPORT] ========================================")
    for sig, group in pairs(signature_map) do
      if #group.ids > 1 then
        print(string.format("[DCCB-PROBE-REPORT]   Signature: %s", sig))
        print(string.format("[DCCB-PROBE-REPORT]     Representative: %s", group.first_id))
        print(string.format("[DCCB-PROBE-REPORT]     Aliases: %s", 
          table.concat(group.ids, ", ")))
      end
    end
    print("[DCCB-PROBE-REPORT] ")
    print("[DCCB-PROBE-REPORT] ========================================")
    print("[DCCB-PROBE-REPORT] Probe Report Complete")
    print("[DCCB-PROBE-REPORT] ========================================")
    print("[DCCB-Gallery] ")
    
    -- PHASE 2: Place unique visuals only
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Phase 2: Placing visually unique terrains...")
    print("[DCCB-Gallery] ========================================")
    print(string.format("[DCCB-Gallery] Placing %d unique visual signatures...", unique_count))
    print("[DCCB-Gallery] ")
    
    local placed_count = 0
    local skipped_missing = 0
    local skipped_dangerous = 0
    local skipped_visual_duplicate = 0
    local stopped_reason = nil
    
    -- Track which signatures we've already placed
    local placed_signatures = {}
    
    -- Track category for logging
    local last_category = nil
    local category_start_idx = 1
    local placement_idx = 0  -- Tracks actual placement position (not terrain idx)
    
    -- Place each terrain candidate (BOUNDS-AWARE, LEVEL-AWARE, SIGNATURE-AWARE)
    -- Only place terrains in the range for this level
    for idx = start_idx, end_idx do
      local terrain_info = manifest.TERRAIN_CANDIDATES[idx]
      if not terrain_info then break end  -- Safety check
      
      local id = terrain_info.id
      local sig = id_to_signature[id]
      
      -- Log category headers (when category changes)
      if terrain_info.category ~= last_category then
        if last_category then
          print(string.format("[DCCB-Gallery]   %s: %d terrains", last_category, placement_idx - category_start_idx))
        end
        last_category = terrain_info.category
        category_start_idx = placement_idx
        print(string.format("[DCCB-Gallery] Category: %s", terrain_info.category))
      end
      
      -- Check signature status
      if sig == "MISSING" then
        skipped_missing = skipped_missing + 1
        if skipped_missing <= 5 then
          print(string.format("[DCCB-Gallery] ⊘ [skip] %-20s | MISSING", id))
        end
      elseif sig == "DANGEROUS" then
        skipped_dangerous = skipped_dangerous + 1
        print(string.format("[DCCB-Gallery] ⚠ [skip] %-20s | DANGEROUS (blacklisted)", id))
      elseif placed_signatures[sig] then
        -- This signature already placed - skip visual duplicate
        skipped_visual_duplicate = skipped_visual_duplicate + 1
        if skipped_visual_duplicate <= 10 then
          print(string.format("[DCCB-Gallery] ≈ [skip] %-20s | VISUAL DUPLICATE of %s", 
            id, signature_map[sig].first_id))
        end
      else
        -- This signature not yet placed - place it!
        -- Calculate position from placement_idx
        local row = math.floor(placement_idx / max_cols)
        local col = placement_idx % max_cols
        
        local x = START_X + (col * stride_x)
        local y = START_Y + (row * stride_y)
        
        -- BOUNDS CHECK: Stop if placement would exceed map bounds
        if x >= W or y >= H then
          print(string.format("[DCCB-Gallery] Palette full at terrain #%d, stopping placement", idx))
          stopped_reason = "Map full"
          break
        end
        
        -- Create and place terrain
        local terrain = zone:makeEntityByName(level, "terrain", id)
        if terrain then
          if terrain.resolve then terrain:resolve() end
          level.map(x, y, Map.TERRAIN, terrain)
          placed_signatures[sig] = true
          placed_count = placed_count + 1
          placement_idx = placement_idx + 1
          
          -- Only log first few placements
          if placed_count <= 10 then
            print(string.format("[DCCB-Gallery] ✓ [%2d,%2d] %-20s | %s", 
              x, y, id, terrain_info.category))
          end
        end
      end
    end
    
    -- Log final category
    if last_category then
      local final_count = placement_idx - category_start_idx
      print(string.format("[DCCB-Gallery]   %s: %d terrains", last_category, final_count))
    end
    
    -- Step 5: Place stairs for multi-level navigation
    print("[DCCB-Gallery] Step 5: Placing stairs...")
    
    -- DOWN stairs (if not last level)
    if current_level < MAX_LEVEL then
      local stair_x = W - 4  -- Bottom-right area
      local stair_y = H - 4
      
      local down_stair = zone:makeEntityByName(level, "terrain", "DOWN")
      if down_stair then
        if down_stair.resolve then down_stair:resolve() end
        level.map(stair_x, stair_y, Map.TERRAIN, down_stair)
        print(string.format("[DCCB-Gallery] DOWN stairs placed at (%d,%d) → Level %d", 
          stair_x, stair_y, current_level + 1))
      else
        print("[DCCB-Gallery] WARNING: DOWN stairs not found")
      end
    end
    
    -- UP stairs (if not first level)
    if current_level > 1 then
      local stair_x = 2  -- Bottom-left area
      local stair_y = H - 4
      
      local up_stair = zone:makeEntityByName(level, "terrain", "UP")
      if up_stair then
        if up_stair.resolve then up_stair:resolve() end
        level.map(stair_x, stair_y, Map.TERRAIN, up_stair)
        print(string.format("[DCCB-Gallery] UP stairs placed at (%d,%d) → Level %d", 
          stair_x, stair_y, current_level - 1))
      else
        print("[DCCB-Gallery] WARNING: UP stairs not found")
      end
    end
    
    print("[DCCB-Gallery] ========================================")
    print("[DCCB-Gallery] Palette generation complete")
    print("[DCCB-Gallery] ========================================")
    print(string.format("[DCCB-Gallery] Level: %d of %d", current_level, MAX_LEVEL))
    print(string.format("[DCCB-Gallery] Terrain range: %d-%d (of %d total)", start_idx, end_idx, total_terrains))
    print(string.format("[DCCB-Gallery] Map bounds: %d × %d", W, H))
    print(string.format("[DCCB-Gallery] Layout capacity: %d cols × %d rows = %d max", max_cols, max_rows, capacity))
    print(string.format("[DCCB-Gallery] ✓ Placed: %d visually unique terrains", placed_count))
    print(string.format("[DCCB-Gallery] ⊘ Skipped (missing): %d", skipped_missing))
    print(string.format("[DCCB-Gallery] ⚠ Skipped (dangerous): %d", skipped_dangerous))
    print(string.format("[DCCB-Gallery] ≈ Skipped (visual duplicates): %d", skipped_visual_duplicate))
    if stopped_reason then
      print(string.format("[DCCB-Gallery] Stopped due to: %s", stopped_reason))
    end
    print(string.format("[DCCB-Gallery] Actual layout: %d columns × %d rows", 
      max_cols, math.ceil(placed_count / max_cols)))
    print("[DCCB-Gallery] ========================================")
  end,
}
