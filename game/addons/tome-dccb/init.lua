-- ToME addon descriptor for DCCB Zone Entry Timing Detection
-- Minimal addon to observe worldmap/zone entry timing

long_name = "DCCB Zone Entry Timing Detection"
short_name = "tome-dccb"
for_module = "tome"
version = {1,0,0}
addon_version = "1.0.0"
weight = 100
author = { "DCCB Team" }
homepage = "https://github.com/ratbuddy/dcc-b"
description = [[
Minimal ToME addon to detect and log zone entry timing.

This addon observes when the player enters the worldmap or first zone
to determine the exact lifecycle point for DCCB integration.

Log-only, no gameplay changes.
]]
tags = { "dccb", "debug", "zone-timing" }
hooks = true
