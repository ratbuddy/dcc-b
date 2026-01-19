# DCC-B Engineering Spec

Version: 0.2
Status: Draft (intended to be iterated in-repo)

This document is the implementation-oriented companion to `DCC-Spec.md`.
It defines concrete module boundaries, file layout, data contracts, hook flow, and coding conventions.

---

## 0. Language & Modding Stack

### 0.1 Primary implementation language
- **Lua** is the primary scripting language for the game engine. This engineering spec assumes Lua for runtime logic and JSON (or equivalent) for data.
- Use your C#/Python comfort for **offline tooling** (schema validation, content generation, linting, build scripts), but keep **runtime** logic in Lua unless an engine-native mechanism requires otherwise.

### 0.2 Runtime principles
- Runtime code must be deterministic given the same seed + config.
- Data-driven first: content expansion should require **no Lua changes** whenever possible.

---

## 1. Repository Layout

Recommended repo structure:

```
/docs
  DCC-Spec.md
  DCC-Engineering.md
  DCC-DataSchemas.md
  ENGINE_PIVOT_Barony_to_ToME.md
/mod
  /dccb
    init.lua
    /core
      bootstrap.lua
      log.lua
      rng.lua
      events.lua
      state.lua
      validate.lua
    /systems
      region_director.lua
      floor_director.lua
      contestant_system.lua
      meta_layer.lua
    /integration
      tome_hooks.lua
      zone_adapter.lua
      actor_adapter.lua
      zone_tags.lua
    /data
      /regions
        *.json
      /floor_rules
        *.json
      /npc_archetypes
        *.json
      /reward_tables
        *.json
      /mutations
        *.json
      /defaults
        config.json
    /ui
      announcer_overlay.lua   (optional, phase 2+)
/tools
  validate_data.py           (optional)
  build_content.py           (optional)
  schema/                    (jsonschema files, optional)
```

Notes:
- `/mod/dccb/init.lua` is the only required “entry” file; everything else is imported from there.
- Keep engine-specific API calls inside `/integration/*`.
- Keep pure logic inside `/systems/*` and `/core/*`.

---

## 2. Module Responsibilities (Hard Boundaries)

### 2.1 Region Director (`/systems/region_director.lua`)
**Owns**
- Region selection, loading, validation
- Region-derived bias functions: enemy pools, loot bias, hazards

**Does NOT own**
- Floor rule selection
- Direct spawning
- Direct dungeon generation calls

### 2.2 Floor Director (`/systems/floor_director.lua`)
**Owns**
- Floor progression state
- Active rule sets
- Mutation activation + parameters

**Does NOT own**
- Region selection
- Spawning entities directly
- UI rendering

### 2.3 Contestant System (`/systems/contestant_system.lua`)
**Owns**
- Contestant generation and long-lived metadata
- Build paths (data-driven)
- Behavior policy selection (risk profile / utility role)

**Does NOT own**
- Dungeon generation logic
- Global show state

### 2.4 Meta Layer (`/systems/meta_layer.lua`)
**Owns**
- Announcer events (logic), achievements, sponsor bias
- Reward resolution pipeline (choosing tables, rolling results)
- Run mutations that affect future floors

**Does NOT own**
- Generating zones
- Direct engine hooks

### 2.5 Integration Layer (`/integration/*`)
**Owns**
- Hook binding to game engine events / lifecycle (currently ToME)
- Adapter functions: apply region/floor constraints to engine generator inputs
- Spawn interception + tagging

**Does NOT own**
- Business logic for regions/floors/show
- Content definitions

---

## 3. Global State Model

All state is stored in a single top-level table managed by `/core/state.lua`.

### 3.1 State shape (authoritative)
```
DCCBState = {
  version = "0.1",
  run = {
    seed = <int>,
    started_at = <timestamp>,
    config = { ... },         -- merged defaults + overrides
  },
  region = {
    id = <string>,
    profile = <RegionProfile>,
  },
  floor = {
    number = <int>,
    state = <FloorState>,
  },
  show = {
    state = <ShowState>,
  },
  contestants = {
    roster = { <Contestant>, ... },
    player_party = { ids... },
  },
  telemetry = {
    events = { ... },         -- optional ring buffer for debugging
  },
}
```

### 3.2 Persistence
- Phase 1 target: in-memory only (fresh per run).
- Phase 2+: persist minimal run metadata if the engine supports it (optional).

---

## 4. Data Loading & Validation

### 4.1 Loader rules
- All data lives under `/mod/dccb/data/*`.
- Load order:
  1. defaults/config.json
  2. regions/*.json
  3. floor_rules/*.json
  4. npc_archetypes/*.json
  5. reward_tables/*.json
  6. mutations/*.json

### 4.2 Validation levels
- **Runtime validation** (Lua): required keys, type sanity, referential integrity (IDs exist).
- **Offline validation** (tools): JSON Schema (optional but recommended).

### 4.3 Data invariants
- All assets referenced by ID must exist (or be gracefully ignored with warning if optional).
- No silent fallbacks for missing required fields: fail fast with clear log output.

---

## 5. Deterministic RNG

### 5.1 RNG policy
- All “DCCB” random decisions must come from `/core/rng.lua`.
- Never call `math.random` (or engine RNG) directly from systems.

### 5.2 Stream separation
Use named RNG streams to prevent cross-system interference:
- `rng:stream("region")`
- `rng:stream("floor")`
- `rng:stream("spawns")`
- `rng:stream("rewards")`
- `rng:stream("contestants")`

### 5.3 Seed derivation
- Base run seed comes from the engine or user config.
- Stream seeds derived from base seed + stable hash(stream_name).

---

## 6. Hook Flow (Lifecycle Contracts)

This section defines the expected integration points. Names are conceptual; actual hook names depend on the target engine's APIs (currently ToME).

### 6.1 Run start
1. `DCCB.bootstrap()`
2. Load config + data
3. Initialize state + RNG
4. Region Director selects region profile
5. Meta Layer initializes show state
6. Contestant System generates initial roster
7. Floor Director sets floor=1 and activates rules

### 6.2 Before zone generation (each floor level)
1. Integration receives “about to generate level” callback
2. Region constraints applied (tileset, props, allowed factions)
3. Floor mutations applied (generation knobs, hazards, modifiers)
4. Tag generated zones with metadata (region/floor/rules)

### 6.3 On actor spawn decision
1. Integration intercepts spawn request (actor/item/prop)
2. Region Director filters/weights allowed pools
3. Floor Director applies rule-based weights/mutations
4. Meta Layer may apply sponsor bias (loot only)
5. Spawn finalized; tag entity with provenance metadata

### 6.4 On key events
- Player kills enemy
- Player takes lethal damage / survives at 1 HP
- Contestant death
- Opens reward box
- Floor completion / transition

All key events must go through `/core/events.lua` dispatch.

---

## 7. Event Bus

### 7.1 Design goals
- Decouple systems
- Make behavior testable
- Allow “meta layer bends reality” without tight coupling

### 7.2 Event types (initial)
- `RUN_START`
- `FLOOR_START`
- `FLOOR_END`
- `ZONE_SECTION_START`
- `ZONE_SECTION_END`
- `SPAWN_REQUEST` (pre)
- `SPAWN_FINALIZED` (post)
- `REWARD_OPEN`
- `ACHIEVEMENT_TRIGGERED`
- `CONTESTANT_SPAWNED`
- `CONTESTANT_DIED`
- `PLAYER_DIED`
- `PLAYER_LEVEL_UP` (if applicable)

### 7.3 Event payload conventions
- Always include:
  - `ts` timestamp
  - `floor_number`
  - `region_id`
  - `seed_context` (stream name)
- Avoid passing engine objects directly when possible; pass IDs and descriptors.

---

## 8. Interfaces (Concrete Function Contracts)

This section is intentionally “API-like”. Each module must expose these functions.

### 8.1 `RegionDirector`
- `RegionDirector.init(state, data, rng)`
- `RegionDirector.select_region(state, rng) -> region_id`
- `RegionDirector.get_profile(state) -> RegionProfile`
- `RegionDirector.filter_enemy_pool(state, floor_state, context, candidates) -> weighted_list`
- `RegionDirector.filter_loot_pool(state, floor_state, context, candidates) -> weighted_list`
- `RegionDirector.apply_generation_constraints(state, gen_params) -> gen_params`

### 8.2 `FloorDirector`
- `FloorDirector.init(state, data, rng)`
- `FloorDirector.set_floor(state, n)`
- `FloorDirector.get_state(state) -> FloorState`
- `FloorDirector.activate_rules(state, rng) -> FloorState`
- `FloorDirector.apply_generation_mutations(state, gen_params) -> gen_params`
- `FloorDirector.adjust_spawn_weights(state, spawn_type, weights, context) -> weights`

### 8.3 `ContestantSystem`
- `ContestantSystem.init(state, data, rng)`
- `ContestantSystem.generate_roster(state, rng) -> roster`
- `ContestantSystem.spawn_contestants_if_needed(state, engine_context)`
- `ContestantSystem.on_event(state, event)`
- `ContestantSystem.get_party_policy(state) -> policy`

### 8.4 `MetaLayer`
- `MetaLayer.init(state, data, rng)`
- `MetaLayer.on_event(state, event)`
- `MetaLayer.resolve_reward(state, reward_context, rng) -> reward_result`
- `MetaLayer.apply_loot_bias(state, weights, context) -> weights`
- `MetaLayer.emit_announcement(state, msg, severity)`

### 8.5 `Integration`
- `Hooks.install()`
- `Hooks.on_run_start()`
- `Hooks.on_pre_generate(gen_params)`
- `Hooks.on_spawn_request(spawn_ctx)`
- `Hooks.on_event(engine_event)`

---

## 9. Metadata & Tagging

### 9.1 Entity provenance
All spawned entities should be taggable with:
- `dccb.region_id`
- `dccb.floor_number`
- `dccb.active_rules` (snapshot or reference)
- `dccb.spawn_source` (enemy_pool / event / reward / scripted)
- `dccb.rng_stream`

### 9.2 Zone/area tagging
Generated zones/areas should be taggable with:
- region + floor
- zone section index
- hazard flags
- “special zone” tags (sponsor zone, arena pocket, etc.)

---

## 10. Logging & Debugging

### 10.1 Logging goals
- Fast diagnosis when data is wrong
- Reproducibility via seed printing
- Minimal spam by default

### 10.2 Levels
- ERROR, WARN, INFO, DEBUG
- Default to INFO

### 10.3 Required startup log
On run start, print:
- DCCB version
- run seed
- selected region
- floor 1 rules list
- enabled data packs

---

## 11. Configuration

### 11.1 config.json (defaults)
Include:
- `seed_mode` (engine / fixed / time)
- `region_mode` (random / pinned / weighted)
- `difficulty_curve` (preset name)
- `npc_roster_size`
- `logging_level`
- `enable_ui_overlay`

### 11.2 overrides
Allow local overrides without editing defaults:
- `config.local.json` (gitignored) OR engine-provided vars

---

## 12. Phase 1 Implementation Checklist (Minimal Vertical Slice)

Goal: a runnable mod skeleton that proves the architecture works.

- [ ] init.lua loads bootstrap
- [ ] data loader works + validation errors are readable
- [ ] RNG stream utility exists
- [ ] region selected and printed
- [ ] floor=1 state created and printed
- [ ] on_pre_generate modifies a visible parameter (even if trivial)
- [ ] spawn_request sees candidates and can reweight them
- [ ] event bus dispatch works
- [ ] a “reward open” event resolves via MetaLayer (stub)

---

## 13. AI-Driven Development Workflow (Operational)

When using ChatGPT/Cursor/Claude:
- Paste the relevant section of this doc + `DCC-Spec.md` invariants
- Ask for code that implements one module at a time
- Require unit-test-like “self checks” via log output and deterministic seed runs
- Merge results back into repo and update docs as contracts evolve

---
