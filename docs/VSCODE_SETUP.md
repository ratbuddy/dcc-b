# VSCode Setup for DCCB ToME Addon Development

This guide helps you set up VSCode with AI assistance for efficient ToME addon development.

## Quick Start

### 1. Clone T-Engine Source (Recommended)

Having the T-Engine source available dramatically improves AI assistance quality:

```bash
# Clone T-Engine to a location accessible from VSCode
cd ~/projects  # or your preferred location
git clone https://github.com/tome-krtr-v1.3.1.teaa/t-engine4.git

# Alternative: Official repo
git clone https://git.net-core.org/tome/t-engine4.git
```

### 2. Create VSCode Workspace

Save this as `dccb-tome-dev.code-workspace` in the repository root:

```json
{
  "folders": [
    {
      "path": ".",
      "name": "dcc-b (addon)"
    },
    {
      "path": "../t-engine4",
      "name": "T-Engine4 (reference)"
    }
  ],
  "settings": {
    "files.associations": {
      "*.lua": "lua"
    },
    "search.exclude": {
      "**/node_modules": true,
      "**/build": true,
      "**/.git": true
    },
    "files.watcherExclude": {
      "**/.git/objects/**": true,
      "**/.git/subtree-cache/**": true,
      "**/node_modules/**": true
    },
    "lua.workspace.library": [
      "${workspaceFolder}/../t-engine4/game/engines"
    ]
  },
  "extensions": {
    "recommendations": [
      "github.copilot",
      "sumneko.lua",
      "continue.continue"
    ]
  }
}
```

Then open it: `File > Open Workspace from File...`

### 3. Install Recommended Extensions

**GitHub Copilot** (Primary AI Assistant):
- Install from VSCode Marketplace
- Requires GitHub Copilot subscription
- Provides inline code suggestions

**Lua Language Server** (sumneko.lua):
- Provides Lua intellisense
- Works with ToME API when configured

**Continue** (Optional, Open Source):
- Free alternative to Copilot
- Supports multiple AI providers (OpenAI, Claude, etc.)
- More customizable

## AI Assistant Benefits with T-Engine Source

### Without T-Engine Source
❌ AI makes educated guesses about APIs  
❌ Slower iteration (trial and error)  
❌ More errors and debugging needed  

### With T-Engine Source
✅ AI can search actual function definitions  
✅ Finds real usage examples from ToME zones  
✅ Verifies parameter types and signatures  
✅ Discovers available methods on objects  
✅ Understands why things work a certain way  

### Example Queries You Can Make

With T-Engine source in workspace, you or AI can:

```bash
# Find how Grid:loadList really works
grep -r "function.*loadList" t-engine4/game/engines/

# See what methods Level has
grep -r "function Level:" t-engine4/game/engines/

# Find Zone helper methods
grep -r "function Zone:" t-engine4/game/engines/

# See how other zones use currentZone
grep -r "currentZone" t-engine4/game/modules/tome/data/zones/
```

## Using AI Assistance Effectively

### GitHub Copilot Tips

1. **Write descriptive comments** - Copilot uses them for context:
   ```lua
   -- Create a 64x64 map since Empty generator ignores dimensions
   local new_map = Map.new(64, 64)
   ```

2. **Start function signatures** - Let Copilot complete:
   ```lua
   local function make_sandbox_zone()
     -- Copilot will suggest the implementation
   ```

3. **Use Copilot Chat** (Ctrl+I):
   - Ask questions about code
   - Request refactoring
   - Get explanations

### Continue.dev Tips

1. **Configure in settings** (`.continue/config.json`)
2. **Use slash commands**: `/edit`, `/comment`, `/fix`
3. **Select code + Ctrl+L** for context-aware chat

## Workspace Structure

```
your-workspace/
├── dcc-b/                    # This addon repository
│   ├── mod/
│   ├── docs/
│   └── ...
└── t-engine4/                # T-Engine source (reference)
    ├── game/
    │   ├── engines/          # Core engine code
    │   └── modules/
    │       └── tome/
    │           └── data/
    │               └── zones/ # Example zones
    └── ...
```

## Lua Configuration for ToME

Create `.luarc.json` in repository root:

```json
{
  "runtime.version": "LuaJIT",
  "diagnostics.globals": [
    "game",
    "engine",
    "mod",
    "class",
    "require",
    "pcall",
    "loadfile",
    "newEntity"
  ],
  "workspace.library": [
    "${workspaceFolder}/../t-engine4/game/engines"
  ],
  "workspace.checkThirdParty": false
}
```

## Debugging Tips

### Search T-Engine for Patterns

```bash
# Find all Map methods
grep -r "^function Map:" t-engine4/

# Find Zone initialization
grep -r "Zone\.new\|Zone:init" t-engine4/

# See how grids are loaded
grep -r "loadList" t-engine4/game/engines/default/engine/Grid.lua

# Find generator implementations
find t-engine4 -name "*generator*" -type f
```

### Verify API Assumptions

Before implementing, search T-Engine to verify:
- Function exists and signature matches
- Parameters are what you expect
- Return values are as assumed
- Common usage patterns

## Common T-Engine API Locations

| API Element | Location |
|-------------|----------|
| Map class | `t-engine4/game/engines/default/engine/Map.lua` |
| Grid class | `t-engine4/game/engines/default/engine/Grid.lua` |
| Zone class | `t-engine4/game/engines/default/engine/Zone.lua` |
| Entity base | `t-engine4/game/engines/default/engine/Entity.lua` |
| Generators | `t-engine4/game/engines/default/engine/generator/` |
| ToME zones | `t-engine4/game/modules/tome/data/zones/` |

## Troubleshooting

### "T-Engine source not found"
- Check the `"path": "../t-engine4"` in workspace file matches your layout
- Adjust path if you cloned T-Engine elsewhere

### "Lua warnings about unknown globals"
- Update `.luarc.json` with ToME-specific globals
- Add to `diagnostics.globals` array

### "AI suggestions not helpful"
- Ensure T-Engine folder is in workspace
- Try selecting code + asking specific questions
- Provide more context in comments

## Resources

- [T-Engine Official Docs](http://te4.org/)
- [T-Engine Git Repository](https://git.net-core.org/tome/t-engine4.git)
- [GitHub Copilot Docs](https://docs.github.com/en/copilot)
- [Continue.dev Docs](https://continue.dev/docs)

## Support

For DCCB-specific questions, see:
- `/docs/AGENT_GUIDE.md` - Development constraints
- `/docs/DCC-Engineering.md` - Architecture notes
- `/docs/TASK_TEMPLATE.md` - Task format
