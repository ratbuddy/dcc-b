-- /mod/tome_addon_harness/hooks/load.lua
-- ToME Addon Hooks - Real Engine Hook Binding
-- This file is executed by ToME when the addon loads

print("[DCCB] hooks/load.lua executed - minimal safe load")

-- Bind the real ToME:load engine hook
-- This proves that real ToME engine hooks can be registered and fired
class:bindHook("ToME:load", function(self, data)
    print("[DCCB] FIRED: ToME:load")
    print("[DCCB] Real ToME engine hook verified - class:bindHook is working")
end)
