# ToME Addon Manifest Notes

**Status:** VERIFIED - Implementation Complete  
**Phase:** Phase-2 Tasks 2.1-2.2.2  
**Last Updated:** 2026-01-22  

## Purpose

This document tracks **ToME addon descriptor and manifest requirements** that have been researched and implemented for the DCCB ToME Addon Harness.

The DCCB ToME Addon Harness now uses **verified ToME addon patterns** based on direct research of ToME/T-Engine4 source code and modding conventions.

---

## Known Information (from ToME-Integration-Notes.md)

From `/docs/ToME-Integration-Notes.md` §5.1 (Addon Structure and Lifecycle):

### Research Questions (VERIFIED - All Resolved)

- [x] **VERIFIED:** ToME addon directory structure
  - **Answer:** `/mod/<name>/` (follows Lua module convention)
  - Addon is placed in ToME's addon directory as `/mod/tome_addon_harness/`
  
- [x] **VERIFIED:** Addon metadata file format
  - **Answer:** `init.lua` using global-variable style descriptor
  - **Required fields:** `long_name`, `short_name`, `for_module`, `version`, `addon_version`
  - **Optional fields:** `author`, `homepage`, `description`, `tags`, capability flags
  
- [x] **VERIFIED:** Entry point pattern
  - **Answer:** Two-stage pattern:
    1. `init.lua` - Pure descriptor metadata (global variables, no execution)
    2. `hooks/load.lua` - Runtime entry point (executed when addon loads)
  
- [x] **VERIFIED:** When the entry point executes
  - **Answer:** `hooks/load.lua` executes during ToME addon initialization
  - This is before the game module starts, during addon loading phase
  
- [x] **VERIFIED:** Game state access
  - **Answer:** Cannot access `game` object during `hooks/load.lua` execution
  - Must register hooks via `class:bindHook()` and wait for engine to fire them
  - `ToME:load`, `ToME:run`, `Actor:move`, etc. hooks provide game state access

### Where to Research

Per ToME-Integration-Notes.md §5.1:
- ToME official addon examples (if available)
- ToME source code: `src/loader/` (if accessible)
- T-Engine4 modding docs: https://te4.org/wiki/

---

## Current Harness Implementation

The harness (`/mod/tome_addon_harness/`) uses the following verified structure:

### 1. Directory Structure

```
/mod/tome_addon_harness/
├── init.lua                          # Addon descriptor (global variables)
├── hooks/
│   └── load.lua                      # Runtime entry point, hook registration
├── data/
│   └── zones/
│       └── dccb-start/               # Custom zone definition
│           ├── zone.lua              # Zone configuration
│           ├── grids.lua             # Terrain definitions (partial)
│           ├── npcs.lua              # NPC definitions (stub)
│           ├── objects.lua           # Object definitions (stub)
│           └── traps.lua             # Trap definitions (stub)
├── overload/
│   └── data/
│       └── zones/
│           └── dccb-start/           # Resource overloads for custom zone
│               ├── grids.lua         # Complete terrain definitions
│               ├── npcs.lua          # NPC overloads (stub)
│               ├── objects.lua       # Object overloads (stub)
│               └── traps.lua         # Trap overloads (stub)
└── superload/
    └── mod/
        └── class/
            └── Game.lua              # Game:changeLevelReal superload for early redirect
```

### 2. Addon Descriptor (`init.lua`)

Uses **global-variable style** (ToME convention):

```lua
long_name = "Dungeon Crawler Challenge Broadcast - ToME Integration"
short_name = "dccb"
for_module = "tome"
version = {1, 0, 0}
addon_version = {0, 2, 2}
weight = 100
author = {"DCCB Project"}
homepage = "https://github.com/ratbuddy/dcc-b"
description = [[...]]
tags = {"dungeon", "procedural", "integration"}

-- Addon capabilities
overload = true
superload = true
hooks = true
data = true
```

**Key Points:**
- Pure metadata, no requires or function calls
- Global variables are read by ToME's addon loader
- `hooks = true` enables `hooks/load.lua` execution
- `data = true` enables custom zone/resource loading
- `overload = true` and `superload = true` enable addon modification patterns

### 3. Runtime Entry Point (`hooks/load.lua`)

Executed by ToME during addon load. Registers hooks via `class:bindHook()`:

```lua
class:bindHook("ToME:load", function(self, data)
    -- Register additional hooks
    class:bindHook("ToME:run", function(self, data)
        -- Bootstrap logic
    end)
    
    class:bindHook("Actor:move", function(self, data)
        -- First zone observation
    end)
    
    -- ... other hooks
end)
```

**Verified Hooks:**
- `ToME:load` - Addon initialization (earliest hook point)
- `ToME:run` - Pre-flow bootstrap (before module starts)
- `Actor:move` - First gameplay action (zone observation)
- `Actor:actBase:Effects` - Actor turn/effects (alternative zone observation)

**Deprecated Hooks:**
- `Player:birth` - Did not fire in ToME addon context
- `Game:loaded` - Did not fire in ToME addon context

### 4. Custom Zone Pattern (`data/zones/dccb-start/`)

ToME addons can define custom zones in `data/zones/<zone-name>/`:

- **Virtual path:** `/data-<addon_short_name>/zones/<zone-name>/zone.lua`
- **Reference format:** `"<addon_short_name>+<zone-name>"` (e.g., `"dccb+dccb-start"`)
- **Resources:** Load from `overload/data/zones/<zone-name>/` for full definitions

The harness includes a stub start zone with:
- Empty surface generator (no spawns, no stairs)
- Post-process fill with grass/trees
- Two entrance markers (visual only, not functional)

### 5. Early Redirect Pattern (`superload/mod/class/Game.lua`)

The harness uses ToME's **superload** mechanism to intercept zone transitions:

```lua
local _M = loadPrevious(...)
local base_changeLevelReal = _M.changeLevelReal

function _M:changeLevelReal(lev, zone, ...)
    if not dccb_start_redirect_done and zone ~= "dccb+dccb-start" then
        dccb_start_redirect_done = true
        return base_changeLevelReal(self, 1, "dccb+dccb-start", ...)
    end
    return base_changeLevelReal(self, lev, zone, ...)
end
```

This redirects the first zone transition to the DCCB start zone before the default module zone loads.

---

## Integration Status

### Completed Implementation (Phase-2 Tasks 2.1-2.2.2)

**✅ Task 2.1: Addon Structure**
- Addon descriptor (`init.lua`) using global-variable style
- Directory structure verified as `/mod/<name>/`
- Entry point pattern verified: descriptor → `hooks/load.lua`

**✅ Task 2.2.1: Hook Registration**
- Hook API verified: `class:bindHook(hookName, callback)`
- First real engine hook verified: `ToME:load`
- Hook callback signature verified: `function(self, data)`

**✅ Task 2.2.2: Lifecycle Anchors**
- Bootstrap hook verified: `ToME:run` (pre-flow, single execution)
- First-zone observation verified: `Actor:move`, `Actor:actBase:Effects`
- Deprecated hooks identified: `Player:birth`, `Game:loaded` (never fired)

**✅ Task 2.2.3: Custom Zone and Redirect**
- Custom zone pattern verified: `data/zones/<zone-name>/zone.lua`
- Zone reference format verified: `"<addon_short_name>+<zone-name>"`
- Resource overload pattern verified: `overload/data/zones/<zone-name>/`
- Early redirect pattern verified: `superload/mod/class/Game.lua`

**✅ Task 2.2.4: Zone Transition API**
- Primary API documented: `game:changeLevel(lev, zone, params)`
- Safety checks documented: `changeLevelCheck()` preconditions
- Zone transition timing documented (§2.4 of ToME-Integration-Notes.md)

### Current Acceptance Criteria

All Phase-2 minimal binding goals are met:

- ✅ Addon loads without errors
- ✅ `ToME:load` hook fires and logs
- ✅ `ToME:run` bootstrap hook fires once
- ✅ First zone observation hooks fire (`Actor:move`)
- ✅ Custom zone (`dccb+dccb-start`) loads successfully
- ✅ Early redirect to custom zone works (before Trollmire loads)
- ✅ Zone post-process generates stable surface with entrance markers

---

## Next Steps

The minimal binding is complete. Future Phase-2 tasks (TBD):

1. **Zone Generation Hooks (§5.3):**
   - Research zone generator hook points
   - Identify what can be modified during generation
   - Map to `Hooks.on_pre_generate()`

2. **Actor Spawn Interception (§5.4):**
   - Research actor creation API
   - Identify spawn hook points
   - Map to `Hooks.on_spawn_request()` (via actor_adapter)

3. **Event Forwarding (§5.2):**
   - Identify additional event hooks (death, levelup, etc.)
   - Map to `Hooks.on_event()`
   - Forward to DCCB systems

4. **Run-Start Binding:**
   - Map appropriate hook to `Hooks.on_run_start()`
   - Initialize DCCB state on new game or save load

---

## Verified ToME Addon Descriptor Fields

Based on current implementation and research:

### Required Fields

```lua
long_name = "Full Addon Name"        -- Display name
short_name = "shortname"             -- Addon ID (used in paths, references)
for_module = "tome"                  -- Target module
version = {1, 0, 0}                  -- Module version compatibility
addon_version = {0, 1, 0}            -- Addon version
```

### Optional Fields

```lua
weight = 100                         -- Load order (higher = later)
author = {"Author Name"}             -- Author list
homepage = "https://..."             -- Project URL
description = [[Multi-line text]]   -- Addon description
tags = {"tag1", "tag2"}              -- Category tags
```

### Capability Flags

```lua
hooks = true                         -- Enable hooks/load.lua
data = true                          -- Enable data/ resources
overload = true                      -- Enable overload/ modifications
superload = true                     -- Enable superload/ modifications
```

---

## Discovered ToME API Surfaces

As ToME research progresses, verified API surfaces are documented here:

### Addon Loading (VERIFIED)

- **Entry point:** `hooks/load.lua` executes during addon initialization
- **Hook registration:** `class:bindHook(hookName, callback)`
- **Earliest hook:** `ToME:load` fires during addon load, before game state exists
- **Load order:** Determined by `weight` field (higher = later)

### Hook System (VERIFIED)

- **Hook registration API:** `class:bindHook(hookName, function(self, data) ... end)`
- **Callback signature:** `function(self, data)` where:
  - `self` = context object (addon class, actor, etc. depending on hook)
  - `data` = hook payload (table with hook-specific fields)
- **Verified hooks:**
  - `ToME:load` - Addon initialization
  - `ToME:run` - Bootstrap anchor (pre-flow, single execution)
  - `Actor:move` - Actor movement (can detect first zone)
  - `Actor:actBase:Effects` - Actor turn/effects (alternative first-zone detection)

### Zone System (VERIFIED)

- **Custom zone pattern:** `data/zones/<zone-name>/zone.lua`
- **Zone reference:** `"<addon_short_name>+<zone-name>"` (e.g., `"dccb+dccb-start"`)
- **Resource loading:** Resources load from `overload/data/zones/<zone-name>/`
- **Zone configuration:** See `data/zones/dccb-start/zone.lua` for example
- **Zone access:** `game.zone` provides current zone object (after bootstrap)
  - `game.zone.name` - Full zone name
  - `game.zone.short_name` - Zone ID (e.g., `"dccb+dccb-start"`)
  - `game.zone.width`, `game.zone.height` - Zone dimensions

### Zone Transition API (VERIFIED)

- **Primary API:** `game:changeLevel(lev, zone, params)`
  - `lev` (number or nil) - Target level index (1-based)
  - `zone` (string, Zone object, or nil) - Target zone identifier
  - `params` (table or nil) - Optional configuration (x, y, force, etc.)
- **Superload pattern:** Override `Game:changeLevelReal` to intercept transitions
- **Safety checks:** See `changeLevelCheck()` in ToME source
- **Timing:** Safe after `ToME:run` completes, or inside actor hook callbacks

### Logger Access (VERIFIED)

- **Basic logging:** `print(message)` works and outputs to ToME console/log
- **Game logging:** `game.log(message)` (ToME's built-in logger, if `game` exists)
- **Log prefix:** Use `"[DCCB]"` or similar prefix for filtering
- **Console access:** Check ToME keybindings for console toggle (varies by build)

### Hook Registration (TBD)

- **TBD:** Available lifecycle hooks beyond those verified
- **TBD:** Event registration API (if separate from hook system)
- **TBD:** Custom event creation/dispatch

### Actor System (TBD)

- **TBD:** Actor creation API (`Actor.new()` or factory)
- **TBD:** Actor spawn hooks
- **TBD:** Actor data structure and available fields
- **TBD:** Custom metadata attachment

### Item System (TBD)

- **TBD:** Item generation hooks
- **TBD:** Item structure and modification API
- **TBD:** Loot drop mechanism

---

## References

### DCC-B Project Docs
- `/docs/ToME-Integration-Notes.md` - Full Phase-2 research and findings (§2.2, §2.4, §5.1-5.2)
- `/docs/AGENT_GUIDE.md` - Development rules and invariants
- `/mod/dccb/integration/tome_hooks.lua` - Integration interface (stub)

### ToME Resources
- ToME Website: https://te4.org/
- T-Engine4 Wiki: https://te4.org/wiki/
- ToME GitHub: https://github.com/tome4/tome4
- T-Engine4 GitHub: https://github.com/CliffsDover/t-engine4 (verified source)

### Verified Source References
- `game/modules/tome/class/Game.lua` - Zone transition implementation
- `game/modules/tome/data/zones/*/zone.lua` - Zone configuration examples
- `dialogs/debug/ChangeZone.lua` - Debug menu zone transition patterns

---

## Maintenance

This document is now **VERIFIED** for all core addon structure questions. Updates should focus on:

1. New API surfaces discovered during implementation
2. Hook payload field documentation (as hooks are used)
3. Advanced patterns (actor spawning, item generation, etc.)
4. Cross-references to ToME-Integration-Notes.md sections

When new information is verified:
1. Add to "Discovered ToME API Surfaces" section
2. Update `/docs/ToME-Integration-Notes.md` corresponding section
3. Update this document's "Last Updated" timestamp

---

End of manifest_notes.md
