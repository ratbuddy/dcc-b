-- /game/addons/tome-dccb/hooks/load.lua
-- Zone Entry Timing Detection
--
-- Observes when gameplay becomes active and logs the current zone.
-- This helps determine the exact lifecycle point where DCCB must intercept.
--
-- Hook reference: https://te4.org/wiki/Hooks
-- Log output: te4_log.txt

-- ========================================
-- Idempotence Guards
-- ========================================
local gameplay_detected = false
local run_started = false

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
        
        -- Detect worldmap hint
        if zone_name:lower():find("world") or 
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
-- Gameplay Detection Callback
-- ========================================
local function on_gameplay_active(hook_name)
    if gameplay_detected then
        return -- Already logged, suppress
    end
    
    gameplay_detected = true
    
    print("[DCCB] ========================================")
    print("[DCCB] gameplay active detected")
    print("[DCCB] ========================================")
    print("[DCCB] triggered by hook: " .. hook_name)
    
    local zone_name, zone_short, zone_type_hint = get_zone_info()
    
    print("[DCCB] current zone: " .. zone_name)
    if zone_short ~= zone_name then
        print("[DCCB] current zone short_name: " .. zone_short)
    end
    print("[DCCB] zone type hint: " .. zone_type_hint)
    print("[DCCB] ========================================")
end

-- ========================================
-- ToME:load - Addon Initialization
-- ========================================
class:bindHook("ToME:load", function(self, data)
    print("[DCCB] ========================================")
    print("[DCCB] FIRED: ToME:load")
    print("[DCCB] ========================================")
    print("[DCCB] DCCB Zone Entry Timing Detection addon loaded")
    print("[DCCB] Binding gameplay detection hooks...")
    
    -- ========================================
    -- ToME:run - Bootstrap (before gameplay)
    -- ========================================
    class:bindHook("ToME:run", function(self, data)
        if run_started then
            return
        end
        run_started = true
        
        print("[DCCB] ========================================")
        print("[DCCB] FIRED: ToME:run")
        print("[DCCB] ========================================")
        print("[DCCB] ToME bootstrap complete")
        print("[DCCB] Waiting for gameplay to become active...")
        print("[DCCB] ========================================")
    end)
    
    -- ========================================
    -- Actor:move - Detects player/actor movement
    -- ========================================
    class:bindHook("Actor:move", function(self, data)
        -- Only trigger on first actor move
        if not gameplay_detected then
            on_gameplay_active("Actor:move")
        end
    end)
    
    -- ========================================
    -- Actor:actBase:Effects - Detects actor turn/effects
    -- ========================================
    class:bindHook("Actor:actBase:Effects", function(self, data)
        -- Only trigger on first actor action
        if not gameplay_detected then
            on_gameplay_active("Actor:actBase:Effects")
        end
    end)
    
    print("[DCCB] Gameplay detection hooks registered:")
    print("[DCCB]   - Actor:move")
    print("[DCCB]   - Actor:actBase:Effects")
    print("[DCCB] ========================================")
end)
