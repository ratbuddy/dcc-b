-- /mod/tome_addon_harness/data/zones/dccb-start/zone.lua
-- FORWARDING SHIM: This file delegates to the overload version
-- The real zone definition is in overload/data/zones/dccb-start/zone.lua
-- This shim ensures ToME loads the correct implementation when it resolves /data-dccb path first

print("[DCCB] zone.lua shim: forwarding to /data/zones/dccb-start/zone.lua")

-- Load and return the zone table from the overload path
-- ToME's overload system places files at /data/zones/... in the global namespace
return loadfile("/data/zones/dccb-start/zone.lua")()
