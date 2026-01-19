# DCCB ToME Addon Harness

**Version:** 0.1  
**Phase:** Phase-2 Task 2.1  
**Status:** Minimal scaffolding for ToME integration

## Purpose

This is a minimal **ToME addon harness** that serves as the bridge between Tales of Maj'Eyal (ToME / T-Engine4) and the DCCB (Dungeon Crawler Challenge Broadcast) game systems.

The harness provides:
- Safe loading of DCCB integration hooks
- Defensive error handling (won't crash ToME if DCCB fails to load)
- Developer toggle for manual DCCB system initialization
- Clear logging of startup status

## Installation

### For ToME Addon Testing

1. **Copy this directory** to ToME's addons folder:
   ```bash
   # Typical ToME addon location (may vary by platform):
   cp -r mod/tome_addon_harness <ToME_Install>/game/addons/
   ```

2. **Verify directory structure** looks like:
   ```
   <ToME_Install>/game/addons/tome_addon_harness/
   ├── init.lua
   ├── logging.lua
   ├── README.md
   └── manifest_notes.md
   ```

3. **Ensure DCCB modules are accessible** - ToME must be able to require `mod.dccb.integration.tome_hooks`
   - This may require copying the entire `mod/dccb/` tree alongside the harness
   - Or configuring Lua package.path to include the repository root

### For Development Testing (Outside ToME)

The harness is designed to be **safe to load outside ToME** for unit testing:

```bash
cd /path/to/dcc-b
lua -e 'package.path="./mod/?.lua;./mod/?/init.lua;" .. package.path' \
  -e 'require("mod.tome_addon_harness.init")'
```

This will:
- Load the harness
- Require DCCB integration hooks
- Call `Hooks.install()`
- Log all startup messages via print() (ToME logger not available)

## Expected Log Output

When the harness loads successfully, you should see:

```
[DCCB-Harness] INFO: ========================================
[DCCB-Harness] INFO: DCCB ToME Harness loaded
[DCCB-Harness] INFO: ========================================
[DCCB-Harness] INFO: Version: 0.1 (Phase-2 Task 2.1)
[DCCB-Harness] INFO: DEV_AUTORUN: false
[DCCB-Harness] INFO: DCCB integration hooks loaded successfully
[DCCB-Harness] INFO: DCCB hooks installed successfully
[DCCB-Harness] INFO: ========================================
[DCCB-Harness] INFO: DCCB ToME Harness initialization complete
[DCCB-Harness] INFO: ========================================
```

Additionally, you'll see output from `Hooks.install()` itself (defined in `/mod/dccb/integration/tome_hooks.lua`), which includes:
```
DCCB ToME Integration: Installing hooks
Hooks.install: stub installation complete
```

## Developer Toggle: DEV_AUTORUN

The harness includes a **developer toggle** at the top of `init.lua`:

```lua
local DEV_AUTORUN = false
```

### Usage

- **Default (`false`)**: Harness loads and registers hooks, but does NOT initialize DCCB systems
  - This is the **correct mode for actual ToME integration**
  - DCCB systems will be initialized when ToME fires the appropriate lifecycle hooks

- **Dev Mode (`true`)**: Harness manually calls `Hooks.on_run_start()` immediately after loading
  - This is **useful for standalone testing** outside ToME
  - WARNING: This will initialize the entire DCCB system state (region selection, contestant generation, etc.)
  - Only use this for testing in isolation

To enable dev mode:
1. Edit `mod/tome_addon_harness/init.lua`
2. Change `local DEV_AUTORUN = false` to `local DEV_AUTORUN = true`
3. Reload the addon

## Validation Checklist

After installing the harness, verify:

- [ ] Harness loads without errors
- [ ] Log message "DCCB ToME Harness loaded" appears
- [ ] Log message "DCCB hooks installed successfully" appears
- [ ] No Lua errors or stack traces in ToME console/log
- [ ] (If DEV_AUTORUN=true) Full DCCB startup sequence completes with "DCCB Run Started - Summary"

## Known Limitations

This is a **Phase-2 minimal harness**. It does NOT:
- Register actual ToME lifecycle hooks (see TODOs in `tome_hooks.lua`)
- Integrate with ToME's zone generation system
- Spawn contestants as ToME actors
- Persist DCCB state across saves
- Provide UI overlays or HUD elements

See `/docs/ToME-Integration-Notes.md` for full Phase-2 scope and limitations.

## Troubleshooting

### Error: "Failed to load DCCB integration hooks"
- Ensure `mod/dccb/` directory is accessible from ToME's Lua path
- Check that all DCCB core modules exist (core/bootstrap.lua, core/state.lua, etc.)

### Error: "Failed to install DCCB hooks"
- Check DCCB core modules for syntax errors
- Review error message for details (logged by harness)

### No log output visible
- Check ToME's console (if accessible)
- Check ToME's log file location (platform-dependent)
- If outside ToME, ensure stdout/print() works in your Lua environment

## Next Steps

After this harness is validated:
1. **Task 2.2**: Research ToME event API and register actual hooks
2. **Task 2.3**: Bind `on_run_start` to ToME game lifecycle event
3. **Task 2.4**: Bind `on_pre_generate` to ToME zone generation
4. **Task 2.5**: Bind `on_event` to ToME event system

See `/docs/ToME-Integration-Notes.md` §6 for full Phase-2 task breakdown.

## File Overview

| File | Purpose |
|------|---------|
| `init.lua` | Main harness entrypoint - loads and initializes DCCB |
| `logging.lua` | Defensive logging helper (ToME logger → print fallback) |
| `README.md` | This file - installation and usage guide |
| `manifest_notes.md` | TBD documentation for ToME addon descriptors |

## License

See repository root for license information.
