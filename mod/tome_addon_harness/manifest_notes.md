# ToME Addon Manifest Notes

**Status:** TBD / Research Required  
**Phase:** Phase-2 Task 2.1  

## Purpose

This document tracks **ToME addon descriptor and manifest requirements** that are not yet fully researched or implemented.

The DCCB ToME Addon Harness currently uses a **minimal generic structure** to avoid inventing ToME APIs. As ToME integration research progresses (Phase-2 Tasks 2.2+), this file will be updated with verified information.

---

## Known Information (from ToME-Integration-Notes.md)

From `/docs/ToME-Integration-Notes.md` §5.1 (Addon Structure and Lifecycle):

### Research Questions (Currently TBD)

- [ ] **TBD:** ToME addon directory structure
  - Is it `/mod/<name>/` or `/game/modules/<name>/` or `/game/addons/<name>/`?
  
- [ ] **TBD:** Addon metadata file format (if any)
  - Does ToME require an `addon.txt`, `manifest.lua`, or similar descriptor file?
  - What fields are required? (name, version, author, dependencies, etc.)
  
- [ ] **TBD:** Entry point file name
  - Is `init.lua` the correct entry point?
  - Or does ToME expect `load.lua`, `mod.lua`, or another name?
  
- [ ] **TBD:** When does the entry point execute?
  - At ToME game boot (before main menu)?
  - At module/addon load time?
  - At new game start?
  
- [ ] **TBD:** Can we access game state from entry point?
  - Or must we wait for a callback/hook to fire?

### Where to Research

Per ToME-Integration-Notes.md §5.1:
- ToME official addon examples (if available)
- ToME source code: `src/loader/` (if accessible)
- T-Engine4 modding docs: https://te4.org/wiki/

---

## Current Harness Approach

The current harness (`/mod/tome_addon_harness/init.lua`) uses:

1. **Directory structure:** `/mod/tome_addon_harness/`
   - Assumption: ToME can load addons from `/mod/<name>/` structure
   - This matches the existing DCCB code structure (`/mod/dccb/`)

2. **Entry point:** `init.lua`
   - Conventional Lua module entry point name
   - Safe assumption for many Lua-based systems

3. **No manifest/descriptor file**
   - The harness does NOT currently include any metadata file
   - If ToME requires one, it must be added in a future task

4. **Defensive initialization**
   - Harness uses `pcall()` for all require/call operations
   - Logs errors via print() fallback if ToME logger unavailable
   - Will not crash if loaded outside ToME or before game state ready

---

## Integration Plan

### Minimal Binding Plan (from ToME-Integration-Notes.md §3)

The harness implements **Step 3.1: Addon Loads and Logs**:

**Goal:** Prove ToME loads our addon and executes `init.lua`

**Current Implementation:**
- ✅ Create `/mod/tome_addon_harness/init.lua` as addon entry point
- ⚠️ Follow ToME addon structure conventions (TBD: research required)
- ✅ Log startup message via logging helper
- ⚠️ Verify log appears in ToME console or log file (TBD: test required)

**Acceptance Criteria:**
- ✅ Message "DCCB ToME Harness loaded" appears in logs
- ⚠️ No errors during addon load (TBD: test in actual ToME)

**Research Needed (from §3.1):**
- ToME addon directory structure ← **This file's focus**
- ToME addon metadata file (if any) ← **This file's focus**
- ToME log output mechanism ← Handled by `logging.lua`

---

## Next Steps

Once ToME addon structure is researched (Phase-2 Task 2.2 or earlier):

1. **Update this document** with verified information:
   - Exact directory structure required
   - Exact metadata file format (if needed)
   - Entry point file conventions
   - Initialization timing

2. **Add required files** to harness:
   - Metadata/manifest file (if needed)
   - Any ToME-required boilerplate

3. **Update README.md** with:
   - Correct installation instructions
   - Verified directory structure
   - ToME-specific configuration steps

4. **Mark sections in ToME-Integration-Notes.md §5.1 as answered**

---

## Placeholder: ToME Addon Descriptor

**Format:** TBD  
**Required Fields:** TBD  
**Optional Fields:** TBD  

Example placeholder (DO NOT USE - this is speculative):
```lua
-- SPECULATIVE - NOT VERIFIED
return {
  name = "DCCB ToME Addon Harness",
  version = "0.1",
  author = "DCCB Project",
  description = "Dungeon Crawler Challenge Broadcast integration for ToME",
  requires = {
    tome_version = "1.7.0" -- Example - TBD
  }
}
```

---

## Discovered ToME API Surfaces

As ToME research progresses, document verified API surfaces here:

### Addon Loading
- **TBD:** Exact loading mechanism
- **TBD:** Load order (relative to other addons)
- **TBD:** Error handling behavior

### Logger Access
- **TBD:** `game.log()` function signature
- **TBD:** Log levels supported
- **TBD:** Log output destination (console, file)

### Hook Registration
- **TBD:** Event registration API (see Task 2.2)
- **TBD:** Available lifecycle hooks (see Task 2.3)

---

## References

### DCC-B Project Docs
- `/docs/ToME-Integration-Notes.md` - Full Phase-2 research plan
- `/docs/AGENT_GUIDE.md` - Development rules and invariants
- `/mod/dccb/integration/tome_hooks.lua` - Integration interface

### ToME Resources
- ToME Website: https://te4.org/
- T-Engine4 Wiki: https://te4.org/wiki/
- ToME GitHub: https://github.com/tome4/tome4

---

## Maintenance

This document will be updated as research progresses. When information is verified:
1. Move from "TBD" to "Verified" section
2. Update harness files accordingly
3. Update `/docs/ToME-Integration-Notes.md` §5.1
4. Mark this document as complete when all TBDs resolved

---

End of manifest_notes.md
