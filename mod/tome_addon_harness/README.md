# DCCB ToME Addon Harness

**Version:** 0.2.2  
**Phase:** Phase-2 Tasks 2.1-2.2.4  
**Status:** Minimal binding complete - custom zone redirect verified

## Purpose

This is a **ToME addon harness** that serves as the bridge between Tales of Maj'Eyal (ToME / T-Engine4) and the DCCB (Dungeon Crawler Challenge Broadcast) game systems.

The harness provides:
- Verified ToME addon structure (descriptor + hooks pattern)
- Lifecycle anchor hooks (`ToME:load`, `ToME:run`, first-zone observation)
- Custom zone definition and loading (`dccb+dccb-start`)
- Early redirect to DCCB start zone (before default module zone loads)
- Safe error handling (print-based logging)

## Installation

### For ToME Addon Testing

1. **Copy this directory** to ToME's addon folder:
   ```bash
   # Typical ToME addon location (platform-dependent):
   # Linux: ~/.t-engine/4.0/game/addons/
   # Windows: %APPDATA%/T-Engine/4.0/game/addons/
   # macOS: ~/Library/Application Support/T-Engine/4.0/game/addons/
   
   cp -r mod/tome_addon_harness <ToME_Addons_Path>/
   ```

2. **Verify directory structure** looks like:
   ```
   <ToME_Addons_Path>/tome_addon_harness/
   ├── init.lua                     # Addon descriptor
   ├── hooks/
   │   └── load.lua                 # Runtime entry point
   ├── data/
   │   └── zones/
   │       └── dccb-start/          # Custom zone definition
   ├── overload/
   │   └── data/zones/dccb-start/   # Zone resources
   ├── superload/
   │   └── mod/class/
   │       └── Game.lua             # Early redirect
   ├── README.md
   └── manifest_notes.md
   ```

3. **Enable the addon** in ToME:
   - Launch ToME
   - Main menu → Addons
   - Enable "Dungeon Crawler Challenge Broadcast - ToME Integration"
   - Start a new game (addon redirects to DCCB start zone)

### For Development Testing (Outside ToME)

The harness can be tested standalone for structure verification:

```bash
cd /path/to/dcc-b

# Verify descriptor loads without errors
lua -e 'dofile("mod/tome_addon_harness/init.lua"); print("Descriptor fields:", long_name, short_name, for_module)'

# Verify hooks/load.lua syntax
lua -c mod/tome_addon_harness/hooks/load.lua && echo "Syntax OK"

# Verify zone definition syntax
lua -c mod/tome_addon_harness/data/zones/dccb-start/zone.lua && echo "Zone syntax OK"
```

Note: Full functionality requires ToME runtime (hook system, zone loading, etc.).

## Expected Log Output

When the harness loads successfully in ToME, you should see:

```
[DCCB] hooks/load.lua executed
[DCCB] FIRED: ToME:load
[DCCB] Zone files located at: data/zones/dccb-start/
[DCCB] Virtual path: /data-dccb/zones/dccb-start/zone.lua
[DCCB] binding run-start hooks now
[DCCB] Zone entry timing detection hooks registered:
[DCCB]   - Actor:move
[DCCB]   - Actor:actBase:Effects
[DCCB] FIRED: ToME:run
[DCCB] bootstrap accepted (ToME:run)
```

When starting a new game, you should see the early redirect:

```
[DCCB] early redirect: changeLevelReal from wilderness to dccb+dccb-start
[DCCB] FIRED: Actor:move
[DCCB] ========================================
[DCCB] first zone observed after bootstrap
[DCCB] ========================================
[DCCB] triggered by hook: Actor:move
[DCCB] current zone: DCCB Start
[DCCB] current zone short_name: dccb+dccb-start
[DCCB] zone type hint: dungeon/location
[DCCB] entered DCCB stub zone: dccb+dccb-start
[DCCB-Zone] Entered zone 'dccb+dccb-start' level 1
[DCCB-Surface] Stable surface generated with 2 entrance markers
```

## Validation Checklist

After installing the harness, verify:

- [ ] Addon appears in ToME's Addons menu
- [ ] Enabling addon does not cause errors
- [ ] Starting new game shows `ToME:load` hook message in log
- [ ] Bootstrap hook (`ToME:run`) fires once
- [ ] Early redirect to `dccb+dccb-start` zone occurs
- [ ] Player spawns in DCCB Start zone (grass surface with trees)
- [ ] Two yellow `>` entrance markers visible
- [ ] No Lua errors or stack traces in ToME console/log
- [ ] Standing on entrance marker shows "[DCCB] Dungeon entrance not implemented yet."

## Known Limitations

This is a **Phase-2 minimal harness**. It does NOT yet:
- Initialize DCCB systems (ContestantSystem, MetaLayer, etc.)
- Register actual DCCB event handlers
- Integrate with ToME's zone generation system (beyond custom zone)
- Spawn contestants as ToME actors
- Persist DCCB state across saves
- Provide UI overlays or HUD elements
- Make dungeon entrance markers functional (they are visual placeholders)

See `/docs/ToME-Integration-Notes.md` for full Phase-2 scope and next steps.

## Troubleshooting

### Addon does not appear in ToME Addons menu
- Verify addon is in correct location (`<ToME_Addons_Path>/tome_addon_harness/`)
- Verify `init.lua` exists and has valid descriptor fields
- Check ToME log for addon loading errors

### Error: "Failed to load addon"
- Check `init.lua` syntax with `lua -c mod/tome_addon_harness/init.lua`
- Verify all descriptor fields are present (see `manifest_notes.md`)
- Check ToME version compatibility (addon targets ToME 1.0+)

### Error: "hooks/load.lua not found"
- Verify `hooks/` directory exists in addon root
- Verify `hooks/load.lua` file exists
- Ensure `hooks = true` in `init.lua` descriptor

### No log output visible
- Check ToME's console (if accessible - varies by build)
- Check ToME's log file (platform-dependent location)
- ToME may suppress addon logs depending on build configuration

### Redirect does not occur / player spawns in Trollmire
- Verify `superload = true` in `init.lua` descriptor
- Verify `superload/mod/class/Game.lua` exists
- Check ToME log for "[DCCB] early redirect" message
- Possible superload conflict with other addons (check load order via `weight`)

### DCCB Start zone does not load
- Verify `data = true` in `init.lua` descriptor
- Verify `data/zones/dccb-start/zone.lua` exists
- Check ToME log for zone loading errors
- Verify `overload/data/zones/dccb-start/grids.lua` exists (defines terrains)

## Next Steps

After this harness is validated:
1. **Zone Generation Hooks**: Research ToME zone generator API (§5.3)
2. **Actor Spawn Interception**: Research actor creation hooks (§5.4)
3. **Event Forwarding**: Register additional event hooks (§5.2)
4. **Run-Start Binding**: Map appropriate hook to `Hooks.on_run_start()`
5. **Contestant Materialization**: Create ToME actors from DCCB contestant roster

See `/docs/ToME-Integration-Notes.md` §6 for full Phase-2+ task breakdown.

## File Overview

| File/Directory | Purpose |
|----------------|---------|
| `init.lua` | Addon descriptor (global variables, metadata) |
| `hooks/load.lua` | Runtime entry point, hook registration |
| `data/zones/dccb-start/zone.lua` | Custom zone configuration |
| `data/zones/dccb-start/grids.lua` | Partial terrain definitions (loaded by zone) |
| `data/zones/dccb-start/npcs.lua` | NPC definitions stub (empty) |
| `data/zones/dccb-start/objects.lua` | Object definitions stub (empty) |
| `data/zones/dccb-start/traps.lua` | Trap definitions stub (empty) |
| `overload/data/zones/dccb-start/grids.lua` | Complete terrain definitions (GRASS, TREE, DCCB_ENTRANCE, etc.) |
| `overload/data/zones/dccb-start/*.lua` | Resource overload stubs |
| `superload/mod/class/Game.lua` | Game:changeLevelReal superload (early redirect) |
| `README.md` | This file - installation and usage guide |
| `manifest_notes.md` | Verified addon structure documentation |

## License

See repository root for license information.
