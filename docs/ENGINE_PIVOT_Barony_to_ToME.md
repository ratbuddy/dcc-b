# ENGINE_PIVOT_Barony_to_ToME.md
Version: 1.0
Status: Authoritative (Engine Migration Specification)
Date: 2026-01-18

This document defines the strategic pivot from Barony to Tales of Maj'Eyal (ToME / T-Engine4) as the target engine for DCC-B.

---

## 1. Why the Pivot is Happening

### 1.1 Barony Limitations Discovered

Through initial design and research, Barony's modding capabilities are fundamentally insufficient for DCC-B's core requirements:

**Cannot Add Custom Races:**
- DCC-B requires diverse contestant backgrounds and biology-driven mechanics
- Barony's character system is fixed to predefined races

**Cannot Add Custom Classes:**
- DCC-B needs dynamic, build-path-driven progression systems
- Barony's class system is rigid and cannot be extended meaningfully

**Cannot Add New Item Lists:**
- DCC-B requires region-specific loot pools and sponsor-themed rewards
- Barony's item system lacks extensibility for custom loot tables

**Limited Vertical Progression:**
- Verticality is first-class in DCC-B design
- Barony's dungeon generator has weak support for multi-layer spaces

**Weak Meta-System Hooks:**
- DCC-B needs deep event interception for announcer, sponsor, and show logic
- Barony's API surface is too limited for meta-layer requirements

### 1.2 ToME Strengths

Tales of Maj'Eyal (T-Engine4) provides the exact capabilities DCC-B requires:

**Custom Races:**
- Full race definition system with stat modifiers, starting equipment, special abilities
- Perfect for diverse contestant backgrounds

**Custom Classes:**
- Deep class definition system with stat growth, talent trees, and progression paths
- Enables build-path-driven contestant evolution

**Talent Trees:**
- Hierarchical skill system with dependencies and unlocks
- Direct mapping to DCC-B's skill/build progression model

**Zones and Generators:**
- Procedural zone generation with hooks for custom logic
- Strong support for vertical spaces and multi-level connectivity
- Region-seeded generation fits perfectly with DCC-B's Region Director

**Deep Data-Driven Systems:**
- Nearly everything in ToME is data-defined (races, classes, talents, zones, items, egos)
- Aligns perfectly with DCC-B's "all major logic is data-driven" invariant

**Events and Hooks:**
- Rich event system for game state changes
- Perfect foundation for Meta Layer (announcer, achievements, sponsors)

**Loot Tables and Egos:**
- Sophisticated item generation with rarity tiers and affixes
- Direct support for reward boxes and sponsor-themed loot

---

## 2. What Remains Valid and Unchanged

The core DCC-B architecture and system design from existing docs remain **fully valid**. The pivot is an **engine swap**, not a design rewrite.

### 2.1 Unchanged Core Architecture

From DCC-Spec.md, these layers remain unchanged:

```
Meta Layer (show logic, announcer, sponsors)
↓
Floor Director (escalation, rule sets, mutations)
↓
Region Director (geographic constraints & content filters)
↓
Dungeon Integration Layer (ToME hooks instead of Barony hooks)
↓
Actors (players, contestants, enemies)
```

**Each layer still constrains the ones below it.**

### 2.2 Unchanged System Modules

All five core systems remain architecturally unchanged:

1. **Region Director** - Still selects region seed, loads region profile, constrains generation
2. **Floor Director** - Still turns floors into rule layers, not places
3. **Dungeon Integration Layer** - Still thin translation layer (now ToME instead of Barony)
4. **Contestant System** - Still generates NPC contestants with builds and personality
5. **Meta Layer** - Still implements announcer, achievements, rewards, sponsors

### 2.3 Unchanged Data Schemas

All data schemas from DCC-DataSchemas.md remain valid:

- Region Profiles (`/regions/*.json`)
- Floor Rule Sets (`/floor_rules/*.json`)
- NPC Archetypes (`/npc_archetypes/*.json`)
- Reward Tables (`/reward_tables/*.json`)
- Mutations (`/mutations/*.json`)
- Config (`defaults/config.json`)

**Data contracts are engine-agnostic by design.**

### 2.4 Unchanged System Invariants

From DCC-Spec.md Section 8, all invariants remain:

- Regions constrain, they do not generate
- Floors mutate rules, not geography
- Contestants are long-lived agents
- Meta systems bend reality
- Dungeon integration remains thin
- All progression is systemic
- All major logic is data-driven

### 2.5 Unchanged Run Lifecycle

The high-level run flow remains unchanged:

```
Start Run
→ Pick Region Seed
→ Initialize Show State
→ Generate Contestants

For each Floor:
→ Determine Floor Rules
→ Mutate Generators
→ Generate Dungeon Chunks
→ Inject Events
→ Run Dungeon
→ Resolve Meta Effects
→ Evolve Contestants
```

---

## 3. What Must Be Revised

### 3.1 Integration Layer (Major)

**File:** `/mod/dccb/integration/*`

The entire integration layer must be rewritten for ToME's API:

- `barony_hooks.lua` → `tome_hooks.lua`
- `gen_adapter.lua` → `zone_adapter.lua`
- `spawn_adapter.lua` → `actor_adapter.lua`
- `room_tags.lua` → `zone_tags.lua`

**Impact:** High effort, but isolated to `/integration/*` by design.

### 3.2 Verticality Strategy (Moderate)

**Doc:** DCC-Spec.md Section 7

ToME has **significantly better** verticality support than Barony. Revisions needed:

- Update verticality examples to reference ToME's multi-level zones
- Document ToME's "up/down stairs" and "ladder" systems
- Leverage ToME's native support for "overworld connection points"

**Impact:** Design improvement, not limitation.

### 3.3 Modding Language (Minor)

**Doc:** DCC-Engineering.md Section 0.1

- Barony uses **Lua**
- ToME uses **Lua** (T-Engine4 is Lua-based)

**Impact:** None. Both engines use Lua.

### 3.4 Repository Layout (Minor)

**Doc:** DCC-Engineering.md Section 1

ToME mods follow a specific structure:

```
/mod/
  /tome-dccb/
    init.lua
    data/
      *.lua (ToME uses Lua data files, not JSON)
    /zones/
    /talents/
    /classes/
    /races/
```

**Impact:** Layout adjustment, but core principles unchanged.

---

## 4. New ToME Engine Primitives We Will Integrate With

### 4.1 Actors (ToME Core Primitive)

**What:** All entities in ToME (players, NPCs, enemies) are "Actors"

**DCC-B Mapping:**
- Contestants → custom Actor classes with personality metadata
- Players → standard Player Actor with DCC-B progression hooks
- Enemies → standard NPC Actors filtered/weighted by Region Director

**Integration Points:**
- `Actor:act()` - per-turn logic, hook for contestant AI
- `Actor:levelup()` - hook for build path progression
- `Actor:die()` - hook for Meta Layer death events

### 4.2 Talents (ToME Skill System)

**What:** Hierarchical skill trees with prerequisites, cooldowns, and effects

**DCC-B Mapping:**
- Contestant skills → custom Talent trees
- Build paths → defined as Talent unlock sequences
- Sponsor gifts → temporary or permanent Talent grants

**Integration Points:**
- `Actor:learnTalent()` - hook for build path learning
- `Actor:useTalent()` - hook for achievement detection
- Talent definitions in `/data/talents/*.lua`

### 4.3 Classes (ToME Progression System)

**What:** Define stat growth, starting equipment, available Talent trees

**DCC-B Mapping:**
- NPC Archetypes → custom Class definitions
- Build preferences → Class-specific Talent tree access
- Personality → Class-specific AI hooks

**Integration Points:**
- Class definitions in `/data/birth/classes/*.lua`
- `Class:startingEquipment()` - loadout bias
- `Class:statModifiers()` - base_stats mapping

### 4.4 Races (ToME Biology System)

**What:** Define physical traits, stat modifiers, special abilities

**DCC-B Mapping:**
- Contestant backgrounds → custom Race definitions
- Region affinity → Race flavor (e.g., "Urban Survivor", "Wasteland Nomad")
- Starting advantages → Race abilities

**Integration Points:**
- Race definitions in `/data/birth/races/*.lua`
- `Race:copy()` - dynamic race generation for contestants
- Racial talents for unique abilities

### 4.5 Zones (ToME Dungeon System)

**What:** Procedurally generated or hand-crafted areas with layouts and spawns

**DCC-B Mapping:**
- Floors → ToME Zone levels
- Region constraints → Zone generator parameters
- Chunk generation → Zone room/tile generation

**Integration Points:**
- `Zone:generateLevel()` - hook for Floor Director mutations
- Zone definitions in `/data/zones/*.lua`
- Generator functions in `/data/general/generators/*.lua`

### 4.6 Generators (ToME Procedural System)

**What:** Algorithms for creating zone layouts (rooms, corridors, etc.)

**DCC-B Mapping:**
- Region asset sets → Generator tileset selection
- Traversal modifiers → Generator parameter tuning
- Verticality bias → Generator stair/ladder placement logic

**Integration Points:**
- Custom generators in `/data/general/generators/dccb-*.lua`
- `Generator:generate(zone, level)` - main hook
- Leverage existing generators (cavern, building, forest) with DCC-B params

### 4.7 Events (ToME Callback System)

**What:** Game-wide event hooks for state changes

**DCC-B Mapping:**
- Event bus (`/core/events.lua`) → wrapper around ToME events
- Meta Layer listeners → ToME event callbacks
- Announcer triggers → respond to combat/death/level events

**Integration Points:**
- `engine.Event:register()` - Meta Layer setup
- Common events: `ACTOR_KILLED`, `LEVEL_UP`, `OBJECT_PICKUP`, `ZONE_ENTER`
- Custom events for DCC-B systems

### 4.8 Loot/Egos (ToME Item System)

**What:** Item generation with base types, rarity tiers, and affixes ("egos")

**DCC-B Mapping:**
- Reward boxes → loot drop events with rarity bias
- Sponsor themes → custom Ego affixes
- Loot bias → rarity and Ego weight modifiers

**Integration Points:**
- `Zone:makeRandomReward()` - hook for Reward Table resolution
- `Object:addEgo()` - sponsor-themed affixes
- Ego definitions in `/data/general/objects/egos/*.lua`

---

## 5. DCC Concepts → ToME Concepts (Detailed Mapping)

### 5.1 Floors → Zones / Zone Modifiers

**DCC-B Concept:** Floors are rule layers that escalate difficulty and inject mechanics

**ToME Mapping:**
- Floor number → Zone level index (zone.level in ToME)
- Floor rules → Zone properties and generator params
- Floor mutations → Dynamic Zone property overrides

**Implementation:**
- Each "floor" is a level within a parent Zone
- Floor Director reads floor number and applies rule sets
- Zone generator is called with mutated params per floor

### 5.2 Regions → Zone Themes / Generator Presets

**DCC-B Concept:** Regions are geographic shards that constrain generation

**ToME Mapping:**
- Region ID → Zone theme/tileset selection
- Asset sets → Generator tileset parameters
- Enemy factions → Zone actor_pool filters
- Hazard rules → Zone trap/effect density params

**Implementation:**
- Region Director selects a "base zone template" at run start
- Zone template defines generator, tileset, actor lists
- Region profile overrides specific generation parameters

### 5.3 Contestants → Actors with Class/Race + Growth Logic

**DCC-B Concept:** NPC contestants are long-lived agents with personality and builds

**ToME Mapping:**
- Contestant → custom Actor with `contestant=true` flag
- NPC Archetype → custom Race + Class combination
- Build path → Talent unlock sequence stored in Actor metadata
- Personality → AI behavior policy in Actor:act()

**Implementation:**
- Contestant System generates Actors with custom Classes/Races
- Store build path and personality in Actor:addTemporaryValue()
- Custom AI logic in Actor:act() references personality profile

### 5.4 Skills → Talents / Trees

**DCC-B Concept:** Skills are progression choices that define builds

**ToME Mapping:**
- Skill → Talent
- Skill tree → Talent category
- Skill prerequisites → Talent requirements
- Skill cooldowns → Talent cooldowns (native)

**Implementation:**
- Define custom Talent trees in `/data/talents/dccb/*.lua`
- Build paths reference sequences of Talent IDs
- Use ToME's native Talent learning and leveling systems

### 5.5 Reward Boxes → Loot Tables, Vaults, Events

**DCC-B Concept:** Boxes drop rewards based on floor/region/show state

**ToME Mapping:**
- Reward box → special Object ("chest") or scripted drop event
- Reward table → loot generation logic in Meta Layer
- Rarity bias → ToME rarity multiplier + Ego chance
- Sponsor themes → custom Ego affixes

**Implementation:**
- Spawn special chest Objects via Meta Layer
- Override Object:openChest() or use `hook:callHook("OPEN_CHEST")`
- Meta Layer resolves Reward Table and spawns items via `zone:addEntity()`

---

## 6. Migration Plan for the Repository

This pivot is **docs-first**, then code. The migration follows strict phases.

### 6.1 Phase 1: Documentation (CURRENT PHASE)

**Status:** In Progress

**Tasks:**
- [x] Rename Barony-specific docs to engine-neutral names
  - DCC-Barony-Spec.md → DCC-Spec.md
  - DCC-Barony-Engineering.md → DCC-Engineering.md
  - DCC-Barony-DataSchemas.md → DCC-DataSchemas.md
- [x] Create ENGINE_PIVOT_Barony_to_ToME.md (this document)
- [ ] Update AGENT_GUIDE.md to reflect ToME as active engine target
- [ ] Create ToME-Integration-Notes.md (stub)
- [ ] Update AGENT_ENTRYPOINT.md to reference renamed docs

**Acceptance:**
- All docs reference ToME, not Barony
- No code changes made yet
- Docs remain internally consistent

### 6.2 Phase 2: Integration Layer Research

**Status:** Not Started

**Goal:** Document ToME's actual API surface and modding patterns

**Tasks:**
- [ ] Create /docs/ToME-Integration-Notes.md
- [ ] Document ToME's mod structure and entry points
- [ ] Document Actor, Talent, Class, Race, Zone APIs
- [ ] Document event hooks and lifecycle
- [ ] Document loot/item generation APIs
- [ ] Identify any ToME limitations (if any)

**Deliverable:**
- ToME-Integration-Notes.md with concrete API signatures
- Updated DCC-Engineering.md with ToME-specific repo layout

### 6.3 Phase 3: Core Systems (Engine-Agnostic)

**Status:** Not Started

**Goal:** Implement core logic with stub integration

**Tasks:**
- [ ] Implement `/core/bootstrap.lua`
- [ ] Implement `/core/log.lua`
- [ ] Implement `/core/rng.lua`
- [ ] Implement `/core/events.lua`
- [ ] Implement `/core/state.lua`
- [ ] Implement `/core/validate.lua`

**Deliverable:**
- Core systems with unit tests (via log-based "self checks")
- No ToME dependencies yet

### 6.4 Phase 4: System Modules (Engine-Agnostic)

**Status:** Not Started

**Goal:** Implement business logic systems

**Tasks:**
- [ ] Implement `/systems/region_director.lua`
- [ ] Implement `/systems/floor_director.lua`
- [ ] Implement `/systems/contestant_system.lua`
- [ ] Implement `/systems/meta_layer.lua`

**Deliverable:**
- Systems callable with stub data
- Deterministic behavior via core/rng.lua
- Event emission via core/events.lua

### 6.5 Phase 5: Integration Layer (ToME-Specific)

**Status:** Not Started

**Goal:** Wire DCC-B systems into ToME

**Tasks:**
- [ ] Implement `/integration/tome_hooks.lua`
- [ ] Implement `/integration/zone_adapter.lua`
- [ ] Implement `/integration/actor_adapter.lua`
- [ ] Implement `/integration/zone_tags.lua`
- [ ] Define custom Classes in `/data/birth/classes/dccb-*.lua`
- [ ] Define custom Races in `/data/birth/races/dccb-*.lua`
- [ ] Define custom Talents in `/data/talents/dccb/*.lua`

**Deliverable:**
- Runnable ToME mod
- Contestant generation works
- Floor progression works
- Region constraints applied

### 6.6 Phase 6: Data Population

**Status:** Not Started

**Goal:** Create actual content using data schemas

**Tasks:**
- [ ] Create 3-5 example regions
- [ ] Create floor rule sets for floors 1-5
- [ ] Create 5-10 NPC archetypes
- [ ] Create reward tables
- [ ] Create mutations

**Deliverable:**
- Playable vertical slice (floors 1-3, one region)
- Data-driven content authoring proven

### 6.7 Phase 7: Meta Layer + Polish

**Status:** Not Started

**Goal:** Implement announcer, achievements, sponsors

**Tasks:**
- [ ] Announcer event detection and messaging
- [ ] Achievement system
- [ ] Sponsor bias logic
- [ ] UI overlay (if applicable)

**Deliverable:**
- "Show" feeling complete
- Announcer messages appear
- Rewards feel dynamic

---

## 7. Risk Assessment

### 7.1 Known Risks

**ToME API Learning Curve:**
- Mitigation: Phase 2 dedicated to API research
- Mitigation: Leverage existing ToME mod examples

**Data Format Change (JSON → Lua):**
- Impact: Moderate (data schemas must be represented as Lua tables)
- Mitigation: Core logic remains unchanged; only serialization format changes

**Performance (Lua + Procedural Systems):**
- Risk: DCC-B's multi-layer constraint system may be slow
- Mitigation: Profile early; optimize hot paths; cache filtered pools

### 7.2 Fallback Plan

If ToME proves insufficient (unlikely given feature set):
- **Option 1:** Consider T-Engine4 directly (ToME's underlying engine)
- **Option 2:** Evaluate Cogmind or other roguelike engines
- **Option 3:** Build minimal custom engine (last resort)

**Current Assessment:** ToME is almost certainly sufficient. Fallback unlikely.

---

## 8. Success Criteria (Unchanged from DCC-Spec.md)

The project is succeeding if:

- Floors feel mechanically different, not just harder
- Runs feel geographically distinct
- NPCs feel like competitors, not pets
- New systems can be added without refactoring
- The dungeon meaningfully surprises the designer

**These criteria are engine-agnostic and remain the north star.**

---

## 9. References

**Authoritative DCC-B Docs:**
- /docs/DCC-Spec.md
- /docs/DCC-Engineering.md
- /docs/DCC-DataSchemas.md
- /docs/AGENT_GUIDE.md

**ToME / T-Engine4 Resources:**
- ToME Official: https://te4.org/
- T-Engine4 Modding Docs: https://te4.org/wiki/
- ToME GitHub: https://github.com/tome4/tome4

**Next Steps:**
- Complete Phase 1 (documentation updates)
- Begin Phase 2 (ToME API research)

---

## 10. Working Methodology (Unchanged)

- **This document is now authoritative for engine migration**
- All engine-specific work must reference this document
- Integration layer changes must not affect core systems
- Data schemas remain stable across engine pivot
- This file is the canonical migration reference

---

End of ENGINE_PIVOT_Barony_to_ToME.md
