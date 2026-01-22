-- /mod/tome_addon_harness/init.lua
-- ToME Addon Harness for DCCB Integration
-- Phase-2 Task 2.2.2: Pure descriptor-only metadata (no requires, no logging, no side effects)
--
-- This file is a pure ToME addon descriptor using global-variable style.
-- All runtime behavior occurs in hooks/load.lua when ToME fires the hooks.

-- ToME addon descriptor (global-variable style)
long_name = "Dungeon Crawler Challenge Broadcast - ToME Integration"
short_name = "dccb"
for_module = "tome"
version = {1, 0, 0}
addon_version = {0, 2, 2}
weight = 100
author = {"DCCB Project"}
homepage = "https://github.com/ratbuddy/dcc-b"

description = [[Dungeon Crawler Challenge Broadcast integration for Tales of Maj'Eyal.
This addon integrates the DCCB procedural generation and meta-layer systems
with ToME's dungeon generation and gameplay mechanics.]]
tags = {"dungeon", "procedural", "integration"}

-- Addon capabilities
overload = true
superload = false
hooks = true
data = true
