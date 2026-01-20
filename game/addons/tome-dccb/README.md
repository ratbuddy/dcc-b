# DCCB Zone Entry Timing Detection

**Version:** 1.0.0  
**Status:** Observation-only addon  
**Task:** Identify and log worldmap/zone entry timing  

## Purpose

This minimal ToME addon observes the first zone entered after bootstrap and logs its information. It helps determine the exact lifecycle point where DCCB must intercept the flow.

Note: This addon does not assume all characters start on the worldmap. It observes whatever zone is first encountered after bootstrap.

## What It Does

- Detects when the first zone is observed (player movement or actor turns)
- Logs the zone name and short_name for comparison across starts
- Identifies whether the zone is worldmap/wilderness or dungeon/location
- Logs only once per run (idempotent)

## Installation

Copy this directory to your ToME installation:

```bash
cp -r game/addons/tome-dccb <ToME_Install>/game/addons/
```

Enable the addon in ToME's addon manager.

## Expected Log Output

After starting a new character and taking the first action (move or wait):

```
[DCCB] ========================================
[DCCB] FIRED: ToME:load
[DCCB] ========================================
[DCCB] DCCB Zone Entry Timing Detection addon loaded
[DCCB] Binding gameplay detection hooks...
[DCCB] Gameplay detection hooks registered:
[DCCB]   - Actor:move
[DCCB]   - Actor:actBase:Effects
[DCCB] ========================================

[DCCB] ========================================
[DCCB] FIRED: ToME:run
[DCCB] ========================================
[DCCB] ToME bootstrap complete
[DCCB] Waiting for gameplay to become active...
[DCCB] ========================================

[DCCB] ========================================
[DCCB] first zone observed after bootstrap
[DCCB] ========================================
[DCCB] triggered by hook: Actor:move
[DCCB] current zone: <zone name>
[DCCB] current zone short_name: <short name>
[DCCB] zone type hint: worldmap/wilderness
[DCCB] ========================================
```

## Hooks Used

- **ToME:load** - Addon initialization (verified hook)
- **ToME:run** - Bootstrap before gameplay starts (verified hook)
- **Actor:move** - Detects player/actor movement (gameplay indicator)
- **Actor:actBase:Effects** - Detects actor turn/effects (gameplay indicator)

All hooks are from the official ToME hooks system: https://te4.org/wiki/Hooks

## Observations Collected

1. **Gameplay Active**: When the first actor action occurs
2. **Zone Identity**: Zone name and short_name from `game.zone`
3. **Zone Type Hint**: Whether it appears to be worldmap/wilderness or dungeon/location

## Non-Goals

This addon does NOT:
- Modify gameplay
- Redirect zone flow
- Replace worldmap
- Add DCCB systems
- Create new zones
- Change spawns or generation

## Validation

1. Launch ToME
2. Start a new character
3. Enter the world and move or wait one turn
4. Quit
5. Check te4_log.txt for expected output

## Known Limitations

- Zone detection relies on ToME's `game.zone` API
- Hook names are based on te4.org/wiki/Hooks documentation
- No persistence across saves (logs once per addon load)

## Authoritative References

- https://te4.org/wiki/Hooks (ToME hook documentation)
- /docs/ToME-Integration-Notes.md (DCCB integration goals)
- /docs/DCC-Engineering.md (DCCB architecture)
- /docs/TASK_TEMPLATE.md v0.2 (task definition format)

## Files

- `init.lua` - ToME addon descriptor
- `hooks/load.lua` - Hook registration and gameplay detection logic
- `README.md` - This file
