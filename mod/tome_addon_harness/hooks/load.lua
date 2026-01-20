-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hooks - Minimal Run-Start Anchor Hook
-- This file is executed by ToME when the addon loads

print("[DCCB] hooks/load.lua executed")

-- Idempotence guard: track if run has started
local run_started = false

-- Bind the ToME:load engine hook (fires when addon loads)
class:bindHook("ToME:load", function(self, data)
    print("[DCCB] FIRED: ToME:load")
end)

-- Bind run-start hooks to detect when gameplay begins
-- Try Player:birth (fires when new character is created)
class:bindHook("Player:birth", function(self, data)
    print("[DCCB] FIRED: Player:birth")
    
    if not run_started then
        run_started = true
        print("[DCCB] run-start accepted")
    else
        print("[DCCB] run-start suppressed (already started)")
    end
end)

-- Try Game:loaded (fires when save is loaded)
class:bindHook("Game:loaded", function(self, data)
    print("[DCCB] FIRED: Game:loaded")
    
    if not run_started then
        run_started = true
        print("[DCCB] run-start accepted")
    else
        print("[DCCB] run-start suppressed (already started)")
    end
end)
