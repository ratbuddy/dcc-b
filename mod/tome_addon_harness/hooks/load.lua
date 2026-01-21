-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hooks - Zone Entry Timing Detection
-- This file is executed by ToME when the addon loads

print("[DCCB] hooks/load.lua executed")

-- ========================================
-- Configuration: Redirect Toggle
-- ========================================
-- When false: logs "DRY RUN: would redirect" (default, safe)
-- When true: attempts actual zone redirect (requires confirmed safe API)
local DCCB_ENABLE_REDIRECT = false

-- Idempotence guards
local run_started = false
local bootstrap_done = false
local first_zone_observed = false
local redirect_attempted = false

-- Handle run-start hook with idempotence
local function handle_run_start(hook_name)
    print("[DCCB] FIRED: " .. hook_name)
    if not run_started then
        run_started = true
        print("[DCCB] run-start accepted (" .. hook_name .. ")")
    else
        print("[DCCB] run-start suppressed (" .. hook_name .. ")")
    end
end

-- Handle bootstrap hook with idempotence
local function handle_bootstrap(hook_name)
    print("[DCCB] FIRED: " .. hook_name)
    if not bootstrap_done then
        bootstrap_done = true
        print("[DCCB] bootstrap accepted (" .. hook_name .. ")")
    else
        print("[DCCB] bootstrap suppressed (" .. hook_name .. ")")
    end
end

-- ========================================
-- Helper: Safe zone name extraction
-- ========================================
local function get_zone_info()
    local zone_name = "unknown"
    local zone_short = "unknown"
    local zone_type_hint = "unknown"
    
    -- Try to access game zone (ToME API)
    if game and game.zone then
        zone_name = game.zone.name or "unnamed-zone"
        zone_short = game.zone.short_name or zone_name
        
        -- Detect worldmap hint (does not assume worldmap is first)
        if zone_name:lower():find("world") or 
           zone_name:lower():find("wilderness") or
           zone_short:lower():find("world") or
           zone_short:lower():find("wilderness") then
            zone_type_hint = "worldmap/wilderness"
        else
            zone_type_hint = "dungeon/location"
        end
    elseif game and game.level then
        zone_name = tostring(game.level)
        zone_type_hint = "level"
    end
    
    return zone_name, zone_short, zone_type_hint
end

-- ========================================
-- First Zone Detection Callback
-- ========================================
local function on_first_zone_observed(hook_name)
    if first_zone_observed then
        return -- Already logged, suppress
    end
    
    first_zone_observed = true
    
    print("[DCCB] ========================================")
    print("[DCCB] first zone observed after bootstrap")
    print("[DCCB] ========================================")
    print("[DCCB] triggered by hook: " .. hook_name)
    
    local zone_name, zone_short, zone_type_hint = get_zone_info()
    
    print("[DCCB] current zone: " .. zone_name)
    print("[DCCB] current zone short_name: " .. zone_short)
    print("[DCCB] zone type hint: " .. zone_type_hint)
    print("[DCCB] ========================================")
    
    -- ========================================
    -- Redirect Decision Point
    -- ========================================
    if not redirect_attempted then
        redirect_attempted = true
        
        -- Placeholder target zone (safe base ToME zone for testing)
        -- CONFIRMED (2026-01-21): "wilderness" is safest redirect target per §2.4.3
        -- See /docs/ToME-Integration-Notes.md §2.4.3 "Valid Zone Identifiers"
        -- Wilderness is always accessible and has safe spawn points
        local target_zone_short = "wilderness"
        
        -- Loop prevention: check if already at target zone
        if zone_short == target_zone_short then
            print("[DCCB] redirect decision: already at target zone")
            print("[DCCB] current zone: " .. zone_short .. " == target: " .. target_zone_short)
            print("[DCCB] skipping redirect (idempotent guard)")
            print("[DCCB] redirect decision complete (once per run)")
            return
        end
        
        -- Check if redirect is enabled by configuration
        if not DCCB_ENABLE_REDIRECT then
            -- DRY RUN: Redirect disabled by configuration
            print("[DCCB] redirect decision: dry-run")
            print("[DCCB] DRY RUN: would redirect from: " .. zone_short .. " to: " .. target_zone_short)
            print("[DCCB] (redirect disabled by DCCB_ENABLE_REDIRECT=false)")
        else
            -- Redirect is enabled, attempt to redirect or fallback to dry-run if API unavailable
            print("[DCCB] redirect decision: redirecting")
            print("[DCCB] redirect from: " .. zone_short .. " to: " .. target_zone_short)
            
            -- IMPLEMENTATION TODO: Replace dry-run with actual zone transition
            -- 
            -- RESEARCH STATUS: ✓ COMPLETE (2026-01-21)
            -- Authoritative T-Engine4 source code analysis documented in:
            -- → /docs/ToME-Integration-Notes.md §2.4 "Confirmed Safe Zone-Transition API"
            --
            -- This section provides the complete implementation recipe including:
            --   • Exact API functions with source file paths and line numbers
            --   • Required parameters and preconditions
            --   • Timing safety matrix (when safe to call)
            --   • Minimal implementation recipe
            --   • Validation checklist for testing
            --   • Known pitfalls and error handling
            --
            -- Primary Source References:
            --   - T-Engine4 GitHub: CliffsDover/t-engine4 repository
            --   - Primary API: game/modules/tome/class/Game.lua lines 812-848 (changeLevel)
            --   - Safety checks: game/modules/tome/class/Game.lua lines 790-811 (changeLevelCheck)
            --   - Core implementation: game/modules/tome/class/Game.lua lines 919+ (changeLevelReal)
            --
            -- RECOMMENDED IMPLEMENTATION (from §2.4.2 Minimal Safe Redirect Recipe):
            --
            --   game:changeLevel(lev, zone, params)
            --     - lev: target level index (number) or nil for zone's default entry level
            --     - zone: target zone short_name string (e.g., "wilderness") or Zone object, or nil for same zone
            --     - params: optional table with keys:
            --         x, y: spawn coordinates (optional, ToME picks safe spawn if omitted)
            --         direct_switch: skip transmo dialog (boolean)
            --         force: force transition even if restricted (boolean)
            --
            -- PRECONDITIONS (verified from changeLevelCheck source):
            --   1. game.player.can_change_level must be true or nil
            --   2. game.player.can_change_zone must be true or nil (for cross-zone transitions)
            --   3. Player must not have recently killed an enemy (10 turn cooldown, unless cheat mode)
            --   4. Player must not have EFF_PARADOX_CLONE or EFF_IMMINENT_PARADOX_CLONE effects
            --
            -- MINIMAL EXAMPLE (safest pattern):
            --   if game and game.zone and game.zone.short_name ~= "wilderness" then
            --       game:changeLevel(nil, "wilderness")  -- nil = use zone's default entry level
            --   end
            --
            -- REQUIRED VALIDATION after implementation (from §2.4.7):
            --   1. In-engine testing with actual ToME instance (no dry-run)
            --   2. Verify game.zone.short_name matches expected zone
            --   3. Verify player position is within bounds and on passable terrain
            --   4. Verify no Lua errors in te4_log.txt
            --   5. Test save/load cycles to ensure state persistence
            --   6. Confirm party/follower state preservation (if party active)
            --   7. Check quest/inventory state remains intact
            --   8. Verify no eternal loading screen (level renders correctly)
            --
            -- NOTE: Implementation timing must follow §2.4.5 timing safety matrix.
            --       Current location (Actor:move hook after first action) is SAFE for calling game:changeLevel.
            --
            -- For complete details, pitfalls, and alternative APIs, see documentation §2.4.
            --
            
            -- Fallback to dry-run (research complete, awaiting implementation task)
            print("[DCCB] redirect enabled but implementation deferred to next task")
            print("[DCCB] DRY RUN: would redirect from: " .. zone_short .. " to: " .. target_zone_short)
        end
        
        print("[DCCB] redirect decision complete (once per run)")
    end
end

-- Bind the ToME:load engine hook (fires when addon loads)
-- Note: This is NOT a run-start hook, it fires during addon initialization
class:bindHook("ToME:load", function(self, data)
    print("[DCCB] FIRED: ToME:load")
    
    -- Bind bootstrap hook (ToME:run - runs before module starts)
    class:bindHook("ToME:run", function(self, data)
        handle_bootstrap("ToME:run")
    end)
    
    -- Bind run-start hooks from inside ToME:load for verifiable order
    print("[DCCB] binding run-start hooks now")
    
    -- Try Player:birth (fires when new character is created)
    class:bindHook("Player:birth", function(self, data)
        handle_run_start("Player:birth")
    end)
    
    -- Try Game:loaded (fires when save is loaded)
    class:bindHook("Game:loaded", function(self, data)
        handle_run_start("Game:loaded")
    end)
    
    -- ========================================
    -- Actor:move - Detects player/actor movement
    -- ========================================
    class:bindHook("Actor:move", function(self, data)
        -- Only trigger on first actor move
        if not first_zone_observed then
            on_first_zone_observed("Actor:move")
        end
    end)
    
    -- ========================================
    -- Actor:actBase:Effects - Detects actor turn/effects
    -- ========================================
    class:bindHook("Actor:actBase:Effects", function(self, data)
        -- Only trigger on first actor action
        if not first_zone_observed then
            on_first_zone_observed("Actor:actBase:Effects")
        end
    end)
    
    print("[DCCB] Zone entry timing detection hooks registered:")
    print("[DCCB]   - Actor:move")
    print("[DCCB]   - Actor:actBase:Effects")
end)
