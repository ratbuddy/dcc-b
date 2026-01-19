# Validation Guide: Phase-2 Task 2.3

**Task:** Bind Hooks.on_run_start() to ToME Run Start Hook (Log-Only)  
**Status:** Implementation Complete - Awaiting Gameplay Verification  
**Date:** 2026-01-19

## Summary

Phase-2 Task 2.3 implements run-start hook binding to prove the lifecycle seam exists and is stable. This is a **log-only** implementation focused on verifying hook timing and callback signatures.

## What Was Implemented

### 1. Run-Start Hooks Registered

Two candidate hooks for detecting gameplay start:
- **`Player:birth`** - Should fire when a new character is created
- **`Game:loaded`** - Should fire when a save game is loaded

### 2. Idempotence Guard

- **Flag:** `module_state.run_started` prevents duplicate initialization
- **Behavior:** Only the first hook to fire invokes `Hooks.on_run_start()`
- **Suppression:** Subsequent hooks log "run_start suppressed (already started)"

### 3. Logging

Crisp, single-line markers at all key points:
- Hook binding: `DCCB: bound run-start hook: <HOOK_NAME>`
- Hook firing: `DCCB: run-start hook fired: <HOOK_NAME>`
- Acceptance: `DCCB: run_start accepted`
- Invocation: `DCCB: on_run_start invoked`
- Suppression: `DCCB: run_start suppressed (already started)`

## Validation Steps

### Prerequisites

1. ToME game with addon support installed
2. DCCB addon files in place (`mod/dccb/`, `mod/tome_addon_harness/`)
3. Addon enabled in ToME

### Test Case 1: New Character Creation

**Objective:** Verify `Player:birth` hook fires when creating a new character

**Steps:**
1. Launch ToME
2. Enable DCCB addon (if not already enabled)
3. Start a new game
4. Create a new character (select race, class, etc.)
5. Complete character creation and enter gameplay
6. Check log output

**Expected Log Output:**
```
========================================
DCCB ToME Integration: Installing hooks
========================================
Verified Engine Hook: ADDON_LOAD
  ...
========================================
DCCB: Binding run-start hooks
========================================
DCCB: bound run-start hook: Player:birth
DCCB: bound run-start hook: Game:loaded
========================================
Hooks.install: installation complete
  ...
  Waiting for run-start hooks to fire...

[... character creation happens ...]

========================================
DCCB: run-start hook fired: Player:birth
========================================
  Hook data type: table
  Hook data keys: [list of keys]
DCCB: run_start accepted
  Triggered by: Player:birth
DCCB: on_run_start invoked
  run_ctx.engine: tome
  run_ctx.hook: Player:birth
  run_ctx.timestamp: [timestamp]
========================================
DCCB: Run Start
========================================
Run seed: [seed]
Step 1/7: Loading configuration and data
Step 2/7: Initializing state and RNG
Step 3/7: Initializing deterministic RNG streams
Step 4/7: Region selection
Step 5/7: Meta Layer initialization
Step 6/7: Contestant roster generation
Step 7/7: Floor Director initialization
========================================
DCCB Run Started - Summary
========================================
Seed: [seed]
Region: [region_id]
Region Name: [region_name]
Floor 1 Rules: [rules list]
Active Mutations: [count]
Contestants: [count]
========================================
DCCB: on_run_start completed successfully
========================================
```

**Success Criteria:**
- ✅ Log shows "bound run-start hook: Player:birth"
- ✅ Log shows "run-start hook fired: Player:birth"
- ✅ Log shows "run_start accepted"
- ✅ Log shows "on_run_start invoked"
- ✅ Log shows full 7-step initialization
- ✅ Log shows "on_run_start completed successfully"
- ✅ No errors during hook firing or initialization

### Test Case 2: Load Existing Save

**Objective:** Verify `Game:loaded` hook fires when loading a save game

**Steps:**
1. Launch ToME
2. Load an existing save game
3. Check log output

**Expected Log Output (if Player:birth already fired):**
```
========================================
DCCB: run-start hook fired: Game:loaded
========================================
  Hook data type: table
  Hook data keys: [list of keys]
DCCB: run_start suppressed (already started)
  First start was via: Player:birth
```

**OR (if this is the first hook to fire):**
```
========================================
DCCB: run-start hook fired: Game:loaded
========================================
  Hook data type: table
  Hook data keys: [list of keys]
DCCB: run_start accepted
  Triggered by: Game:loaded
DCCB: on_run_start invoked
  ...
[full initialization as in Test Case 1]
```

**Success Criteria:**
- ✅ Log shows "run-start hook fired: Game:loaded"
- ✅ Idempotence guard works correctly (suppression if already started)
- ✅ No errors during hook firing

### Test Case 3: Multiple Hook Firings (Idempotence)

**Objective:** Verify idempotence guard prevents duplicate initialization

**Steps:**
1. Complete Test Case 1 (new character)
2. If both hooks fire during the same session, verify only the first triggers initialization

**Expected Log Output:**
```
[First hook fires - initialization runs]
========================================
DCCB: run-start hook fired: Player:birth
========================================
DCCB: run_start accepted
  Triggered by: Player:birth
DCCB: on_run_start invoked
[... full initialization ...]
DCCB: on_run_start completed successfully
========================================

[Second hook fires - suppressed]
========================================
DCCB: run-start hook fired: Game:loaded
========================================
DCCB: run_start suppressed (already started)
  First start was via: Player:birth
```

**Success Criteria:**
- ✅ Only the first hook to fire triggers initialization
- ✅ Subsequent hooks are suppressed with clear logging
- ✅ No duplicate initialization occurs
- ✅ No errors

## Troubleshooting

### If Hooks Don't Bind

**Symptom:** Log shows "failed to bind Player:birth hook" or "failed to bind Game:loaded hook"

**Possible Causes:**
- Hook names are incorrect (ToME doesn't recognize them)
- `class:bindHook` API not available at install time
- ToME version incompatibility

**Action:**
1. Check error message for details
2. Research correct ToME hook names in T-Engine4 docs or source code
3. Try alternative hook names (e.g., `Actor:init`, `Game:start`, `Level:enter`)
4. Update hook names in `tome_hooks.lua` and retry

### If Hooks Don't Fire

**Symptom:** Hooks bind successfully but never fire (no "run-start hook fired" log)

**Possible Causes:**
- Hook names are wrong (bind succeeds but ToME never fires them)
- Hook fires at a different lifecycle point than expected
- ToME version doesn't support these hooks

**Action:**
1. Add debug logging to verify hook binding succeeded
2. Research when hooks actually fire in ToME
3. Try alternative hooks or lifecycle points
4. Document findings in ToME-Integration-Notes.md

### If Hooks Fire But on_run_start Fails

**Symptom:** "run-start hook fired" logged but "on_run_start failed" appears

**Possible Causes:**
- Error in `Hooks.on_run_start()` implementation
- Missing dependencies (Bootstrap, State, etc.)
- Data loading error

**Action:**
1. Check error message for stack trace
2. Verify all DCCB core modules are available
3. Check data files are present and valid
4. Fix error and retry

## Known Limitations

1. **Hook names unverified:** `Player:birth` and `Game:loaded` are educated guesses. Actual names will be confirmed during gameplay testing.

2. **Hook payload structure:** Unknown until hooks fire. First test will reveal available data keys.

3. **Log-only:** This implementation proves the hook binding works but doesn't modify DCCB system behavior beyond logging.

4. **No save/load persistence:** DCCB state is NOT persisted across save/load (Phase 3+).

## Success Declaration

Task 2.3 is **validated and complete** when:

- ✅ Addon loads without errors
- ✅ Run-start hooks bind successfully (log shows "bound run-start hook")
- ✅ At least one hook fires during gameplay (log shows "run-start hook fired")
- ✅ `Hooks.on_run_start()` invokes successfully (log shows "on_run_start invoked")
- ✅ Idempotence guard prevents duplicate starts (if multiple hooks fire)
- ✅ Documentation updated with verified hook details

Once validated, update `/docs/ToME-Integration-Notes.md`:
- Mark hooks as **VERIFIED** in Hook Inventory Table (§2)
- Update §8.6 with observed hook payload structure
- Add verification date to Change Log (§9)

## References

- **Implementation:** `/mod/dccb/integration/tome_hooks.lua`
- **Documentation:** `/docs/ToME-Integration-Notes.md` (§2, §5.2, §8.6)
- **Task Spec:** Problem statement for Phase-2 Task 2.3
